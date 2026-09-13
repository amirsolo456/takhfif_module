import 'package:flutter/material.dart';
import '../../data/models/profit_report.dart';
import '../../data/repositories/profit_report_api_repository.dart';
import '../../shared/utils/iran_format.dart';

class ProfitReportPage extends StatefulWidget {
  const ProfitReportPage({super.key});

  @override
  State<ProfitReportPage> createState() => _ProfitReportPageState();
}

class _ProfitReportPageState extends State<ProfitReportPage> {
  final _idSalController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  ProfitReport? _report;
  bool _loading = false;
  String? _error;

  String money(num value) => '${IranFormat.number(value)} ریال';

  @override
  void dispose() {
    _idSalController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    final idSal = IranFormat.parseNumber(_idSalController.text.trim())?.toInt();
    final fromDate = _fromDateController.text.trim();
    final toDate = _toDateController.text.trim();

    if (idSal == null || fromDate.isEmpty || toDate.isEmpty) {
      setState(() => _error = 'سال مالی، تاریخ شروع و تاریخ پایان را وارد کنید.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await ProfitReportApiRepository(
        baseUrl: '',
      ).getReport(idSal: idSal, fromDate: fromDate, toDate: toDate);

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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: const Text('گزارش سود')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _field(
                    controller: _idSalController,
                    label: 'سال مالی',
                    hint: 'مثلاً ۱۴۰۵',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _fromDateController,
                    label: 'از تاریخ',
                    hint: 'مثلاً ۱۴۰۵/۰۶/۰۱',
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _toDateController,
                    label: 'تا تاریخ',
                    hint: 'مثلاً ۱۴۰۵/۰۶/۳۱',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _loadReport,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calculate_rounded),
                      label: Text(_loading ? 'در حال محاسبه...' : 'محاسبه سود'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(_error!),
              ),
            ),
          ],
          if (report != null) ...[
            const SizedBox(height: 12),
            Card(child: ListTile(title: const Text('مجموع فروش'), trailing: Text(money(report.totalSales)))),
            Card(child: ListTile(title: const Text('بهای تمام‌شده'), trailing: Text(money(report.totalPurchaseCost)))),
            Card(
              child: ListTile(
                title: const Text('سود فروش', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  money(report.totalProfit),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: report.totalProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('جزئیات کالاها', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...report.items.map(
              (item) => Card(
                child: ListTile(
                  title: Text('کالا: ${IranFormat.digits(item.idKala)}'),
                  subtitle: Text(
                    'تعداد: ${IranFormat.number(item.quantity)}\n'
                    'فروش: ${money(item.salesAmount)}\n'
                    'بهای تمام‌شده: ${money(item.purchaseCost)}',
                  ),
                  trailing: Text(
                    money(item.profit),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.profit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
