import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/kala.dart';
import '../../data/models/person.dart';
import '../../data/repositories/document_api_repository.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/master_data_selection_sheets.dart';
import '../widgets/shamsi_date_picker_dialog.dart';
import '../../shared/utils/iran_format.dart';

class PartnerSaleDocumentPage extends StatefulWidget {
  const PartnerSaleDocumentPage({super.key});

  @override
  State<PartnerSaleDocumentPage> createState() => _PartnerSaleDocumentPageState();
}

class _PartnerSaleDocumentPageState extends State<PartnerSaleDocumentPage> with AutomaticKeepAliveClientMixin {
  static const int idSal = 1405;
  static const int idAnbar = 1;
  static const int idMasool = 101;
  static const int idSandogh = 1;
  static const int idSandoghType = 1;
  static const int sanadType = 113;

  Person? _customer;
  final List<_PartnerSaleLine> _lines = [];
  final _noteController = TextEditingController();
  Jalali _selectedDate = Jalali.now();
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatJalali(Jalali j) =>
      '${j.year.toString().padLeft(4, '0')}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';

  String _formatDisplayJalali(Jalali j) =>
      '${IranFormat.digits(j.year)}/${IranFormat.digits(j.month.toString().padLeft(2, '0'))}/${IranFormat.digits(j.day.toString().padLeft(2, '0'))}';


  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<ApiSettings>();
    final total = _lines.fold<double>(0, (sum, line) => sum + line.quantity * line.salePrice);
    final profit = _lines.fold<double>(0, (sum, line) => sum + line.quantity * (line.salePrice - line.partnerCost));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('فروش از انبار همکار', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('❖', style: TextStyle(color: theme.colorScheme.primary, fontSize: 16)),
          ],
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(step: '۱', title: 'انتخاب طرف حساب', icon: Icons.person_search_rounded),
                  const SizedBox(height: 10),
                  _buildCustomerCard(theme),
                  const SizedBox(height: 24),
                  const SectionHeader(step: '۲', title: 'جستجو و افزودن کالا', icon: Icons.local_shipping_outlined),
                  const SizedBox(height: 10),
                  _buildAddProductButton(theme),
                  const SizedBox(height: 12),
                  if (_lines.isEmpty)
                    _emptyState(theme)
                  else
                    ..._lines.asMap().entries.map((e) => _lineCard(e.key, e.value, theme)),
                  const SizedBox(height: 24),
                  const SectionHeader(step: '۳', title: 'تنظیمات و توضیحات', icon: Icons.tune_rounded),
                  const SizedBox(height: 10),
                  _buildSettingsCard(theme),
                  const SizedBox(height: 16),
                  _summaryCard(total, profit, theme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(color: Colors.black38, child: Center(child: CircularProgressIndicator())),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: DocumentSubmitButton(
            onPressed: _submit,
            loading: _loading,
            label: 'ثبت',
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(ThemeData theme) =>
      PersonSelectionCard(
        selectedPerson: _customer,
        onSelect: _chooseCustomer,
        placeholderTitle: 'طرف حساب انتخاب نشده است',
        placeholderSubtitle: 'برای ثبت فاکتور همکار، خریدار را انتخاب کنید.',
      );

  Widget _buildAddProductButton(ThemeData theme) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _chooseProduct,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: theme.colorScheme.primary),
          ),
          icon: const Icon(Icons.search_rounded),
          label: const Text('جستجو و انتخاب کالا', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      );

  Widget _emptyState(ThemeData theme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined, size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('هنوز هیچ کالایی اضافه نشده است', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );

  Widget _lineCard(int index, _PartnerSaleLine line, ThemeData theme) {
    final total = line.quantity * line.salePrice;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(IranFormat.digits(index + 1), style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(line.kala.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                IconButton(
                  onPressed: () => setState(() => _lines.removeAt(index)),
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onSurfaceVariant),
                  tooltip: 'حذف',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: line.quantity == line.quantity.roundToDouble() ? line.quantity.toInt().toString() : line.quantity.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'تعداد / مقدار', border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => line.quantity = double.tryParse(v.replaceAll(',', '')) ?? 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('partner-price-$index-${line.kala.code}'),
                    initialValue: line.salePrice == 0 ? '' : CurrencyFormatter.format(CurrencyHelper.fromRawRials(line.salePrice)),
                    inputFormatters: [CurrencyFormatter.inputFormatter],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'قیمت فروش واحد', suffixText: CurrencyHelper.unitSymbol, border: const OutlineInputBorder()),
                    onChanged: (v) => setState(() => line.salePrice = CurrencyHelper.toRawRials(CurrencyFormatter.parse(v))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey('partner-cost-$index-${line.kala.code}'),
              initialValue: line.partnerCost == 0 ? '' : CurrencyFormatter.format(CurrencyHelper.fromRawRials(line.partnerCost)),
              inputFormatters: [CurrencyFormatter.inputFormatter],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'بهای خرید همکار', suffixText: CurrencyHelper.unitSymbol, border: const OutlineInputBorder()),
              onChanged: (v) => setState(() => line.partnerCost = CurrencyHelper.toRawRials(CurrencyFormatter.parse(v))),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey('partner-total-$index-${line.kala.code}'),
              initialValue: total == 0 ? '' : CurrencyFormatter.format(CurrencyHelper.fromRawRials(total)),
              inputFormatters: [CurrencyFormatter.inputFormatter],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'جمع کل این قلم',
                suffixText: CurrencyHelper.unitSymbol,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final lineTotal = CurrencyHelper.toRawRials(CurrencyFormatter.parse(v));
                setState(() {
                  if (line.quantity > 0) {
                    line.salePrice = lineTotal / line.quantity;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            InkWell(
              onTap: _pickShamsiDate,
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
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Tahoma'),
                            children: const [
                              TextSpan(text: '* ', style: TextStyle(color: Color(0xFFEF4444))),
                              TextSpan(text: 'تاریخ سند (شمسی)'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDisplayJalali(_selectedDate),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_calendar_rounded, size: 16, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text('تغییر تاریخ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'شرح سند (اختیاری)',
                hintText: 'توضیحات موردنظر را وارد کنید',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickShamsiDate() async {
    final picked = await ShamsiDatePickerDialog.show(
      context: context,
      initialDate: _selectedDate,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _summaryCard(double total, double profit, ThemeData theme) => Card(
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: .45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: .3))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(children: [Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary), const SizedBox(width: 8), const Text('خلاصه فروش همکار', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
              const Divider(height: 24),
              _summaryRow('مشتری:', _customer?.fullName ?? 'انتخاب نشده'),
              const SizedBox(height: 8),
              _summaryRow('اقلام:', '${IranFormat.digits(_lines.length)} قلم'),
              const SizedBox(height: 8),
              _summaryRow('مبلغ فروش:', CurrencyHelper.format(total), bold: true),
              const SizedBox(height: 8),
              _summaryRow('سود تخمینی:', CurrencyHelper.format(profit), bold: true, color: profit >= 0 ? Colors.green : Colors.red),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: theme.colorScheme.surface.withValues(alpha: .7), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('این سند موجودی انبار خودمان را کاهش نمی‌دهد (SanadType=113).', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) => Row(
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'BYekan',
                fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color: color ?? (bold ? Theme.of(context).colorScheme.primary : null),
              ),
            ),
          ),
        ],
      );

  void _chooseCustomer() {
    Person? picked;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => EnhancedPersonSearchSheet(onSelected: (person) => picked = person),
    ).then((_) {
      if (picked != null && mounted) setState(() => _customer = picked);
    });
  }

  void _chooseProduct() {
    Kala? picked;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => EnhancedKalaSearchSheet(onSelected: (kala) => picked = kala),
    ).then((_) {
      final selectedKala = picked;
      if (selectedKala == null || !mounted) {
        return;
      }
      final i = _lines.indexWhere((x) => x.kala.id == selectedKala.id);
      setState(() {
        if (i >= 0) {
          _lines[i].quantity += 1;
        } else {
          _lines.add(_PartnerSaleLine(
            kala: selectedKala,
            quantity: 1,
            salePrice: selectedKala.salePrice ?? 0,
            partnerCost: selectedKala.purchasePrice ?? 0,
          ));
        }
      });
    });
  }

  Future<void> _submit() async {
    if (_customer == null) {
      _message('لطفاً مشتری را انتخاب کنید', true);
      return;
    }
    if (_lines.isEmpty) {
      _message('حداقل یک کالا اضافه کنید', true);
      return;
    }
    if (_lines.any((line) => line.quantity <= 0 || line.salePrice < 0 || line.partnerCost < 0)) {
      _message('تعداد و قیمت‌های اقلام را بررسی کنید', true);
      return;
    }

    setState(() => _loading = true);
    try {
      final request = CreateDocumentRequest(
        idSal: idSal,
        sanadType: sanadType,
        idAnbar: idAnbar,
        idTaraf: _customer!.id,
        idTarafType: _customer!.personType,
        idMasool: idMasool,
        idSandogh: idSandogh,
        idSandoghType: idSandoghType,
        sabtDate: _formatJalali(_selectedDate),
        des: 'فروش از انبار همکار',
        sharh: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        checkStock: false,
        items: _lines
            .map((line) => CreateDocumentItemRequest(
                  idKala: line.kala.code.isNotEmpty ? line.kala.code : line.kala.id,
                  quantity: line.quantity,
                  unitPrice: line.salePrice,
                  purchasePrice: line.partnerCost,
                  isIncoming: false,
                ))
            .toList(),
      );

      final doc = await context.read<DocumentApiRepository>().createPartnerSaleDocument(request: request);
      if (!mounted) return;

      setState(() {
        _lines.clear();
        _customer = null;
        _noteController.clear();
      });

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 64),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'سند فروش از انبار همکار با موفقیت ثبت شد',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'شماره فاکتور: ${IranFormat.digits(doc.idFaktor)}\nمبلغ کل: ${CurrencyHelper.format(doc.totalAmount)}',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تأیید'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text, bool error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
}

class _PartnerSaleLine {
  final Kala kala;
  double quantity;
  double salePrice;
  double partnerCost;

  _PartnerSaleLine({
    required this.kala,
    required this.quantity,
    required this.salePrice,
    required this.partnerCost,
  });
}
