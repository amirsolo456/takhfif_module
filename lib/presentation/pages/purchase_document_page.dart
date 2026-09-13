import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/kala.dart';
import '../../data/models/person.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../shared/utils/iran_format.dart';
import '../widgets/master_data_selection_sheets.dart';
import '../widgets/shamsi_date_picker_dialog.dart';

class PurchaseDocumentPage extends StatefulWidget {
  const PurchaseDocumentPage({super.key});

  @override
  State<PurchaseDocumentPage> createState() => _PurchaseDocumentPageState();
}

class _PurchaseDocumentPageState extends State<PurchaseDocumentPage> {
  static const int idSal = 1405;
  static const int idAnbar = 1;
  static const int idMasool = 101;
  static const int idSandogh = 1;
  static const int idSandoghType = 1;
  static const int defaultPurchaseSanadType = 11;

  Person? _supplier;
  final List<_PurchaseLine> _lines = [];
  final _noteController = TextEditingController();
  final int _sanadType = defaultPurchaseSanadType;
  Jalali _selectedDate = Jalali.now();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _money(num value) => NumberFormat('#,###').format(value);

  @override
  Widget build(BuildContext context) {
    final total = _lines.fold<double>(0, (sum, line) => sum + line.quantity * line.purchasePrice);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('صدور اسناد', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('❖', style: TextStyle(color: theme.colorScheme.primary, fontSize: 16)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'پاک‌سازی فرم',
            onPressed: _lines.isEmpty && _supplier == null
                ? null
                : () => setState(() {
                      _lines.clear();
                      _supplier = null;
                      _noteController.clear();
                    }),
            icon: const Icon(Icons.cleaning_services_rounded),
          ),
        ],
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
                  _sectionTitle('۱', 'انتخاب تأمین‌کننده', Icons.business_center_outlined, Colors.blue.shade700),
                  const SizedBox(height: 10),
                  _buildSupplierCard(theme),
                  const SizedBox(height: 24),
                  _sectionTitle('۲', 'اقلام سند خرید', Icons.inventory_2_outlined, Colors.teal.shade700),
                  const SizedBox(height: 10),
                  _buildAddProductButton(theme),
                  const SizedBox(height: 12),
                  if (_lines.isEmpty)
                    _emptyLinesPlaceholder(theme)
                  else
                    ..._lines.asMap().entries.map((entry) => _lineCard(entry.key, entry.value, theme)),
                  const SizedBox(height: 24),
                  _sectionTitle('۳', 'تنظیمات و توضیحات سند', Icons.tune_outlined, Colors.deepOrange.shade700),
                  const SizedBox(height: 10),
                  _buildSettingsCard(theme),
                  const SizedBox(height: 24),
                  _summaryCard(total, theme),
                  const SizedBox(height: 16),
                  _submitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('در حال ثبت سند خرید و افزایش موجودی...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String step, String title, IconData icon, Color color) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(step, style: TextStyle(fontWeight: FontWeight.w900, color: primary, fontSize: 13))),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(width: 4),
        Text('❖', style: TextStyle(color: primary, fontSize: 12)),
      ],
    );
  }

  Widget _buildSupplierCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _supplier != null ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_supplier != null ? Icons.person_rounded : Icons.person_search_rounded,
                  color: _supplier != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_supplier?.fullName ?? 'تأمین‌کننده انتخاب نشده است', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(_supplier?.mobile ?? 'برای ثبت سند خرید، یک تأمین‌کننده انتخاب کنید.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _chooseSupplier,
              icon: Icon(_supplier != null ? Icons.edit_rounded : Icons.search_rounded, size: 18),
              label: Text(_supplier != null ? 'تغییر' : 'انتخاب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _chooseProduct,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('افزودن کالا به سند خرید', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }

  Widget _emptyLinesPlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text('هنوز هیچ کالایی اضافه نشده است', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('روی دکمه بالا بزنید تا کالاهای خریده‌شده را جستجو و وارد کنید.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _lineCard(int index, _PurchaseLine line, ThemeData theme) {
    final lineTotal = line.quantity * line.purchasePrice;
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSecondaryContainer))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.kala.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      if (line.kala.code.isNotEmpty)
                        Text('کد: ${line.kala.code}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _lines.removeAt(index)),
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onSurfaceVariant),
                  tooltip: 'حذف قلم',
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
                    decoration: const InputDecoration(labelText: 'تعداد / مقدار', prefixIcon: Icon(Icons.numbers_rounded), border: OutlineInputBorder()),
                    onChanged: (value) => setState(() => line.quantity = double.tryParse(value.replaceAll(',', '')) ?? 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-price-$index'),
                    initialValue: line.purchasePrice == 0 ? '' : CurrencyFormatter.format(line.purchasePrice),
                    inputFormatters: [CurrencyFormatter.inputFormatter],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'قیمت خرید واحد', prefixIcon: Icon(Icons.attach_money_rounded), suffixText: 'ریال', border: OutlineInputBorder()),
                    onChanged: (value) => line.purchasePrice = CurrencyFormatter.parse(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Text('جمع این قلم:', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Text('${_money(lineTotal)} ریال', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    final formattedDate =
        '${IranFormat.digits(_selectedDate.year)}/${IranFormat.digits(_selectedDate.month.toString().padLeft(2, '0'))}/${IranFormat.digits(_selectedDate.day.toString().padLeft(2, '0'))}';

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
                          formattedDate,
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
                labelText: 'توضیحات و شرح سند (اختیاری)',
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

  Widget _summaryCard(double total, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: .5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: .3))),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary), const SizedBox(width: 8), const Text('خلاصه سند خرید', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
            const Divider(height: 24),
            _summaryRow('تأمین‌کننده:', _supplier?.fullName ?? 'انتخاب نشده'),
            const SizedBox(height: 8),
            _summaryRow('تعداد اقلام:', '${_lines.length} قلم'),
            const SizedBox(height: 8),
            _summaryRow('مجموع کل سند:', '${_money(total)} ریال', isBold: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.surface.withValues(alpha: .7), borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [Icon(Icons.info_outline_rounded, size: 18), SizedBox(width: 8), Expanded(child: Text('با ثبت نهایی، کالاها وارد انبار شده و موجودی افزایش می‌یابد.', style: TextStyle(fontSize: 12)))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, fontSize: isBold ? 16 : 14, color: isBold ? Theme.of(context).colorScheme.primary : null)),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: _loading ? null : _submit,
        child: const Text('ذخیره', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _chooseSupplier() {
    Person? picked;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => EnhancedPersonSearchSheet(onSelected: (person) => picked = person),
    ).then((_) {
      if (picked != null && mounted) setState(() => _supplier = picked);
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
      if (picked == null || !mounted) return;
      final index = _lines.indexWhere((line) => line.kala.id == picked!.id);
      setState(() {
        if (index >= 0) {
          _lines[index].quantity += 1;
        } else {
          _lines.add(_PurchaseLine(kala: picked!, purchasePrice: picked!.purchasePrice ?? 0));
        }
      });
    });
  }

  Future<void> _submit() async {
    if (_supplier == null) {
      _message('لطفاً تأمین‌کننده را انتخاب کنید', true);
      return;
    }
    if (_lines.isEmpty) {
      _message('حداقل یک کالا اضافه کنید', true);
      return;
    }
    if (_lines.any((line) => line.quantity <= 0 || line.purchasePrice < 0)) {
      _message('تعداد و قیمت خرید اقلام را بررسی کنید', true);
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = context.read<DocumentApiRepository>();
      final shamsiDate =
          '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}';

      final request = CreateDocumentRequest(
        idSal: idSal,
        sanadType: _sanadType,
        idAnbar: idAnbar,
        idTaraf: _supplier!.id,
        idTarafType: _supplier!.personType,
        idMasool: idMasool,
        idSandogh: idSandogh,
        idSandoghType: idSandoghType,
        sabtDate: shamsiDate,
        des: 'سند خرید',
        sharh: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        checkStock: false,
        items: _lines.map((line) => CreateDocumentItemRequest(
          idKala: line.kala.code.isNotEmpty ? line.kala.code : line.kala.id,
          quantity: line.quantity,
          unitPrice: line.purchasePrice,
          purchasePrice: line.purchasePrice,
          isIncoming: true,
        )).toList(),
      );

      final doc = await repo.createPurchaseDocument(request: request);
      if (!mounted) return;

      setState(() {
        _lines.clear();
        _supplier = null;
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
              const Text('سند خرید با موفقیت ثبت شد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              Text('شماره سند: ${doc.idFaktor}\nموجودی انبار اقلام مربوطه افزایش یافت.', textAlign: TextAlign.center),
            ],
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تأیید'))],
        ),
      );
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PurchaseLine {
  final Kala kala;
  double quantity;
  double purchasePrice;

  _PurchaseLine({required this.kala, this.purchasePrice = 0}) : quantity = 1;
}
