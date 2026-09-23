import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/profit_report.dart';
import '../../data/repositories/profit_report_api_repository.dart';
import '../../shared/utils/iran_format.dart';
import '../widgets/custom_calendar_icon.dart';
import '../widgets/shamsi_date_picker_dialog.dart';

class ProfitReportPage extends StatefulWidget {
  const ProfitReportPage({super.key});

  @override
  State<ProfitReportPage> createState() => _ProfitReportPageState();
}

class _ProfitReportPageState extends State<ProfitReportPage> {
  late TextEditingController _idSalController;
  late Jalali _fromDate;
  late Jalali _toDate;

  ProfitReport? _report;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _toDate = now;
    _fromDate = _getOneMonthAgo(now);
    _idSalController = TextEditingController(text: IranFormat.digits(now.year));
  }

  static Jalali _getOneMonthAgo(Jalali now) {
    if (now.month > 1) {
      final prevMonth = now.month - 1;
      final maxDays = Jalali(now.year, prevMonth, 1).monthLength;
      final day = now.day > maxDays ? maxDays : now.day;
      return Jalali(now.year, prevMonth, day);
    } else {
      final prevYear = now.year - 1;
      const prevMonth = 12;
      final maxDays = Jalali(prevYear, prevMonth, 1).monthLength;
      final day = now.day > maxDays ? maxDays : now.day;
      return Jalali(prevYear, prevMonth, day);
    }
  }

  String _formatJalali(Jalali j) {
    final monthStr = j.month.toString().padLeft(2, '0');
    final dayStr = j.day.toString().padLeft(2, '0');
    return '${j.year}/$monthStr/$dayStr';
  }

  String _formatDisplayJalali(Jalali j) {
    final monthStr = j.month.toString().padLeft(2, '0');
    final dayStr = j.day.toString().padLeft(2, '0');
    return '${IranFormat.digits(j.year)}/${IranFormat.digits(monthStr)}/${IranFormat.digits(dayStr)}';
  }

  String money(num value) => CurrencyHelper.format(value);

  @override
  void dispose() {
    _idSalController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    final idSal = IranFormat.parseNumber(_idSalController.text.trim())?.toInt();
    final fromDateStr = _formatJalali(_fromDate);
    final toDateStr = _formatJalali(_toDate);

    if (idSal == null) {
      setState(() => _error = 'لطفاً سال مالی معتبر وارد کنید.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final baseUrl = context.read<ApiSettings>().baseUrl;
      final repo = ProfitReportApiRepository(baseUrl: baseUrl);
      final report = await repo.getReport(
        idSal: idSal,
        fromDate: fromDateStr,
        toDate: toDateStr,
      );

      if (!mounted) return;
      setState(() => _report = report);
    } on ProfitReportApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'خطا در دریافت گزارش: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildDateField({
    required String label,
    required Jalali value,
    required ValueChanged<Jalali> onPicked,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final picked = await ShamsiDatePickerDialog.show(
          context: context,
          initialDate: value,
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDisplayJalali(value),
                  style: TextStyle(
                    fontFamily: 'BYekan',
                    fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Spacer(),
            CustomCalendarIcon(color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ApiSettings>();
    final report = _report;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('گزارش سود'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _idSalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'سال مالی',
                        hintText: 'مثلاً ۱۴۰۵',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDateField(
                      label: 'از تاریخ (شمسی)',
                      value: _fromDate,
                      onPicked: (d) => setState(() => _fromDate = d),
                    ),
                    const SizedBox(height: 12),
                    _buildDateField(
                      label: 'تا تاریخ (شمسی)',
                      value: _toDate,
                      onPicked: (d) => setState(() => _toDate = d),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _loadReport,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.calculate_rounded),
                        label: Text(
                          _loading ? 'در حال محاسبه...' : 'محاسبه سود',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                  title: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            if (report != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: ListTile(
                  title: const Text('مجموع فروش', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    money(report.totalSales),
                    style: TextStyle(
                      fontFamily: 'BYekan',
                      fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Card(
                elevation: 0,
                child: ListTile(
                  title: const Text('بهای تمام‌شده', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    money(report.totalPurchaseCost),
                    style: TextStyle(
                      fontFamily: 'BYekan',
                      fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Card(
                elevation: 0,
                color: report.totalProfit >= 0 ? Colors.green.shade900.withValues(alpha: .2) : Colors.red.shade900.withValues(alpha: .2),
                child: ListTile(
                  title: const Text('سود فروش', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  trailing: Text(
                    money(report.totalProfit),
                    style: TextStyle(
                      fontFamily: 'BYekan',
                      fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: report.totalProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'جزئیات کالاها',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              ...report.items.map(
                (item) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      'کالا: ${IranFormat.digits(item.idKala)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'تعداد: ${IranFormat.number(item.quantity)}\n'
                        'فروش: ${money(item.salesAmount)}\n'
                        'بهای تمام‌شده: ${money(item.purchaseCost)}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                      ),
                    ),
                    trailing: Text(
                      money(item.profit),
                      style: TextStyle(
                        fontFamily: 'BYekan',
                        fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: item.profit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
