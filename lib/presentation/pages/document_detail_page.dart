import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../shared/utils/iran_format.dart';

class DocumentDetailPage extends StatefulWidget {
  final DocumentApiRepository repository;
  final int idSal;
  final String id;
  const DocumentDetailPage({super.key, required this.repository, required this.idSal, required this.id});
  @override State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _PersianGroupedFormatter extends TextInputFormatter {
  final bool decimal;
  const _PersianGroupedFormatter({this.decimal = false});

  static String normalize(String value, {bool decimal = false}) {
    var text = value
        .replaceAll('۰', '0').replaceAll('۱', '1').replaceAll('۲', '2')
        .replaceAll('۳', '3').replaceAll('۴', '4').replaceAll('۵', '5')
        .replaceAll('۶', '6').replaceAll('۷', '7').replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll('٠', '0').replaceAll('١', '1').replaceAll('٢', '2')
        .replaceAll('٣', '3').replaceAll('٤', '4').replaceAll('٥', '5')
        .replaceAll('٦', '6').replaceAll('٧', '7').replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll(',', '').replaceAll('٬', '').replaceAll('،', '')
        .replaceAll('٫', '.').replaceAll(' ', '');
    text = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final dot = text.indexOf('.');
    if (!decimal) {
      if (dot >= 0) text = text.substring(0, dot);
      return text;
    }
    if (dot < 0) return text;
    return text.substring(0, dot + 1) + text.substring(dot + 1).replaceAll('.', '');
  }

  static String format(String value, {bool decimal = false}) {
    final raw = normalize(value, decimal: decimal);
    if (raw.isEmpty) return '';
    final parts = raw.split('.');
    var integer = parts.first;
    final chunks = <String>[];
    while (integer.length > 3) {
      chunks.insert(0, integer.substring(integer.length - 3));
      integer = integer.substring(0, integer.length - 3);
    }
    chunks.insert(0, integer);
    final grouped = IranFormat.digits(chunks.join('٬'));
    if (!decimal || parts.length == 1) return grouped;
    return '$grouped٫${IranFormat.digits(parts[1])}';
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = format(newValue.text, decimal: decimal);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }
}

class _EditRow {
  final TextEditingController code, qty, purchase, sale;

  _EditRow({
    required String code,
    required double qty,
    required double purchase,
    required double sale,
  })  : code = TextEditingController(text: _PersianGroupedFormatter.format(code)),
        qty = TextEditingController(
          text: _PersianGroupedFormatter.format(
            qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
            decimal: true,
          ),
        ),
        purchase = TextEditingController(
          text: _PersianGroupedFormatter.format(
            CurrencyHelper.fromRawRials(purchase).round().toString(),
          ),
        ),
        sale = TextEditingController(
          text: _PersianGroupedFormatter.format(
            CurrencyHelper.fromRawRials(sale).round().toString(),
          ),
        );

  void dispose() {
    code.dispose();
    qty.dispose();
    purchase.dispose();
    sale.dispose();
  }
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late Future<DocumentModel> _future;
  final rows = <_EditRow>[];
  bool saving = false, initialized = false;

  @override void initState() { super.initState(); _future = _load(); }
  Future<DocumentModel> _load() => widget.repository.getDocument(idSal: widget.idSal, id: widget.id);

  void _initRows(DocumentModel d) {
    if (initialized || d.sanadType != 12) return;
    initialized = true;
    rows.addAll(d.items.map((x) => _EditRow(code: x.idKala, qty: x.quantity, purchase: x.purchasePrice, sale: x.unitPrice)));
  }

  double _num(TextEditingController c) => IranFormat.parseNumber(c.text) ?? 0;

  String _code(TextEditingController c) => _PersianGroupedFormatter.normalize(c.text);
  void _addRow() => setState(() => rows.add(_EditRow(code: '', qty: 1, purchase: 0, sale: 0)));
  void _removeRow(int i) { final r = rows.removeAt(i); r.dispose(); setState(() {}); }

  Future<void> _saveSale() async {
    if (saving) return;
    final items = <Map<String, dynamic>>[];
    for (final r in rows) {
      final code = _code(r.code); final qty = _num(r.qty);
      final sale = _num(r.sale); final purchase = _num(r.purchase);
      if (code.isEmpty || qty <= 0 || sale < 0 || purchase < 0) { _message('کد کالا، تعداد و قیمت‌ها را صحیح وارد کنید.', true); return; }
      items.add({'idKala': code, 'quantity': qty, 'unitPrice': CurrencyHelper.toRawRials(sale), 'purchasePrice': CurrencyHelper.toRawRials(purchase), 'isIncoming': false});
    }
    if (items.isEmpty) { _message('سند باید حداقل یک کالا داشته باشد.', true); return; }
    setState(() => saving = true);
    try {
      await widget.repository.updateSaleDocument(idSal: widget.idSal, id: widget.id, items: items);
      if (!mounted) return;
      _message('سند با موفقیت ویرایش شد.', false);
      Navigator.pop(context, true);
    } catch (e) { if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), true); }
    finally { if (mounted) setState(() => saving = false); }
  }

  void _message(String text, bool error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red : null));

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('حذف سند', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('آیا از حذف سند شماره «${IranFormat.digits(doc.idFaktor)}» اطمینان دارید؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف نهایی'))],
    ));
    if (confirm != true || !mounted) return;
    try {
      await widget.repository.deleteDocument(idSal: widget.idSal, id: widget.id, sanadType: doc.sanadType);
      if (!mounted) return;
      _message('سند با موفقیت حذف شد.', false);
      Navigator.pop(context, true);
    } catch (e) { if (mounted) _message('خطا در حذف سند: ${e.toString().replaceFirst('Exception: ', '')}', true); }
  }

  void _retry() => setState(() {
        initialized = false;
        for (final r in rows) {
          r.dispose();
        }
        rows.clear();
        _future = _load();
      });
  @override
  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ApiSettings>();
    return Directionality(textDirection: TextDirection.rtl, child: FutureBuilder<DocumentModel>(
      future: _future,
      builder: (context, snapshot) {
        final document = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text('سند ${IranFormat.digits(widget.id)}'), centerTitle: true, actions: [
            if (document?.sanadType == 12) IconButton(onPressed: saving ? null : _saveSale, tooltip: 'ذخیره ویرایش', icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined)),
            if (document != null) IconButton(tooltip: 'حذف سند', icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant), onPressed: () => _deleteDocument(document)),
          ]),
          body: Builder(builder: (context) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _ErrorView(message: snapshot.error.toString(), onRetry: _retry);
            if (document == null) return _ErrorView(message: 'اطلاعات سند دریافت نشد.', onRetry: _retry);
            _initRows(document);
            return RefreshIndicator(onRefresh: () async => _retry(), child: ListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, padding: const EdgeInsets.fromLTRB(12, 12, 12, 220), children: [
              _HeaderCard(document: document), const SizedBox(height: 18),
              Text('اقلام سند', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)), const SizedBox(height: 10),
              if (document.sanadType == 12) ...[
                ...List.generate(rows.length, (i) => _editRowCard(i)),
                OutlinedButton.icon(onPressed: saving ? null : _addRow, icon: const Icon(Icons.add_outlined), label: const Text('افزودن کالا')),
                const SizedBox(height: 8), FilledButton.icon(onPressed: saving ? null : _saveSale, icon: const Icon(Icons.save_outlined), label: const Text('ذخیره تغییرات')),
              ] else ...document.items.map((item) => _ItemCard(item: item)),
            ]));
          }),
        );
      },
    ));
  }

  static const _font = 'BYekan';
  static const _fallback = <String>['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'];

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: _font, fontFamilyFallback: _fallback),
        floatingLabelStyle: const TextStyle(fontFamily: _font, fontFamilyFallback: _fallback),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      );

  Widget _numberField(String label, TextEditingController controller, {bool decimal = false}) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        inputFormatters: [_PersianGroupedFormatter(decimal: decimal)],
        style: const TextStyle(fontFamily: _font, fontFamilyFallback: _fallback, fontSize: 16, fontWeight: FontWeight.w700),
        decoration: _inputDecoration(label),
        textDirection: TextDirection.ltr,
        scrollPadding: const EdgeInsets.only(bottom: 180),
      ),
    );
  }

  Widget _codeField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: const [_PersianGroupedFormatter()],
      style: const TextStyle(fontFamily: _font, fontFamilyFallback: _fallback, fontSize: 16, fontWeight: FontWeight.w700),
      decoration: _inputDecoration('کد کالا'),
      textDirection: TextDirection.ltr,
      scrollPadding: const EdgeInsets.only(bottom: 180),
    );
  }

  Widget _editRowCard(int i) {
    final r = rows[i];
    final theme = Theme.of(context);
    final unit = CurrencyHelper.unitSymbol;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'کالا ${IranFormat.number(i + 1)}',
                    style: TextStyle(
                      fontFamily: _font,
                      fontFamilyFallback: _fallback,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: saving ? null : () => _removeRow(i),
                  color: Colors.red.shade700,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'حذف کالا',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 3, child: _codeField(r.code)),
                const SizedBox(width: 10),
                _numberField('تعداد', r.qty, decimal: true),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _numberField('قیمت خرید ($unit)', r.purchase),
                const SizedBox(width: 10),
                _numberField('قیمت فروش ($unit)', r.sale),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final DocumentModel document; const _HeaderCard({required this.document});
  @override Widget build(BuildContext context) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _InfoRow('شناسه سند', IranFormat.digits(document.id)), _InfoRow('سال مالی', IranFormat.digits(document.idSal)), _InfoRow('نوع سند', IranFormat.digits(document.sanadType)), _InfoRow('شماره فاکتور', IranFormat.digits(document.idFaktor)), _InfoRow('طرف حساب', '${IranFormat.digits(document.idTaraf)} / ${IranFormat.digits(document.idTarafType)}'), _InfoRow('انبار', IranFormat.digits(document.idAnbar)), _InfoRow('تاریخ', IranFormat.date(document.sabtDate)), _InfoRow('وضعیت نهایی', document.isFinal ? 'نهایی' : 'پیش‌نویس'), _InfoRow('مبلغ کل', CurrencyHelper.format(document.totalAmount)), if ((document.description ?? '').trim().isNotEmpty) _InfoRow('شرح', document.description!),
  ])));
}

class _ItemCard extends StatelessWidget {
  final DocumentItemModel item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncoming = item.isIncoming;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ردیف ${IranFormat.digits(item.id2)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'کالا: ${IranFormat.digits(item.idKala)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isIncoming ? Colors.green : Colors.orange).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isIncoming ? 'ورود' : 'خروج',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isIncoming ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: _DetailCell(
                    label: 'تعداد',
                    value: IranFormat.number(item.quantity),
                    valueColor: theme.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: _DetailCell(
                    label: 'قیمت فروش',
                    value: CurrencyHelper.format(item.unitPrice),
                    valueColor: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DetailCell(
                    label: 'قیمت خرید',
                    value: CurrencyHelper.format(item.purchasePrice),
                    valueColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: _DetailCell(
                    label: 'جمع کل',
                    value: CurrencyHelper.format(item.totalAmount),
                    valueColor: theme.colorScheme.primary,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _DetailCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title, value; const _InfoRow(this.title, this.value);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 125, child: Text(title, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant))), Expanded(child: Text(value, style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w900)))]));
}

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry; const _ErrorView({required this.message, required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_outlined), label: const Text('تلاش مجدد'))])));
}
