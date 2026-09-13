import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/kala.dart';
import '../../data/models/person.dart';
import '../../data/repositories/document_api_repository.dart';
import '../widgets/master_data_selection_sheets.dart';
import '../../shared/utils/iran_format.dart';

class PartnerSaleDocumentPage extends StatefulWidget {
  const PartnerSaleDocumentPage({super.key});
  @override State<PartnerSaleDocumentPage> createState() => _PartnerSaleDocumentPageState();
}

class _PartnerSaleDocumentPageState extends State<PartnerSaleDocumentPage> {
  static const int idSal = 1405;
  static const int idAnbar = 1;
  static const int idMasool = 101;
  static const int idSandogh = 1;
  static const int idSandoghType = 1;
  static const int sanadType = 113;

  Person? _customer;
  final List<_PartnerSaleLine> _lines = [];
  final _noteController = TextEditingController();
  bool _loading = false;

  @override void dispose() { _noteController.dispose(); super.dispose(); }
  String _sabtDate() { final j = Jalali.fromDateTime(DateTime.now()); return '${j.year.toString().padLeft(4, '0')}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}'; }
  String _money(num value) => IranFormat.number(value);

  @override Widget build(BuildContext context) {
    final total = _lines.fold<double>(0, (sum, line) => sum + line.quantity * line.salePrice);
    final profit = _lines.fold<double>(0, (sum, line) => sum + line.quantity * (line.salePrice - line.partnerCost));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('فروش از انبار همکار', style: TextStyle(fontWeight: FontWeight.w800)), centerTitle: true),
      body: Directionality(textDirection: TextDirection.rtl, child: Stack(children: [
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('۱', 'انتخاب مشتری', Icons.person_search_rounded), const SizedBox(height: 10), _buildCustomerCard(theme),
          const SizedBox(height: 24), _sectionTitle('۲', 'اقلام فروش همکار', Icons.local_shipping_outlined), const SizedBox(height: 10), _buildAddProductButton(), const SizedBox(height: 12),
          if (_lines.isEmpty) _emptyState(theme) else ..._lines.asMap().entries.map((e) => _lineCard(e.key, e.value, theme)),
          const SizedBox(height: 24), _sectionTitle('۳', 'توضیحات', Icons.notes_rounded), const SizedBox(height: 10),
          Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: TextField(controller: _noteController, maxLines: 3, decoration: const InputDecoration(labelText: 'شرح سند (اختیاری)', border: OutlineInputBorder())))),
          const SizedBox(height: 16), _summaryCard(total, profit, theme), const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: _loading ? null : _submit, icon: const Icon(Icons.check_circle_rounded), label: const Text('ثبت نهایی سند ۱۱۳', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
          const SizedBox(height: 24),
        ])),
        if (_loading) const Positioned.fill(child: ColoredBox(color: Colors.black38, child: Center(child: CircularProgressIndicator()))),
      ]),),
    );
  }

  Widget _sectionTitle(String step, String title, IconData icon) { final color = Theme.of(context).colorScheme.primary; return Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(step, style: TextStyle(color: color, fontWeight: FontWeight.w900)))), const SizedBox(width: 10), Icon(icon, color: color, size: 22), const SizedBox(width: 6), Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color))]); }

  Widget _buildCustomerCard(ThemeData theme) => Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: theme.colorScheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: _customer != null ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)), child: Icon(_customer != null ? Icons.person_rounded : Icons.person_search_rounded, color: _customer != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_customer?.fullName ?? 'مشتری انتخاب نشده است', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 3), Text(_customer?.mobile ?? 'مشتری را انتخاب کنید.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))])), FilledButton.tonalIcon(onPressed: _chooseCustomer, icon: const Icon(Icons.search_rounded, size: 18), label: Text(_customer != null ? 'تغییر' : 'انتخاب'))])));
  Widget _buildAddProductButton() => SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _chooseProduct, icon: const Icon(Icons.add_shopping_cart_rounded), label: const Text('افزودن کالا', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))));
  Widget _emptyState(ThemeData theme) => Container(width: double.infinity, padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .35), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant)), child: Column(children: [Icon(Icons.local_shipping_outlined, size: 44, color: theme.colorScheme.onSurfaceVariant), const SizedBox(height: 8), Text('هنوز کالایی اضافه نشده است', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant))]));

  Widget _lineCard(int index, _PartnerSaleLine line, ThemeData theme) { final total = line.quantity * line.salePrice; return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)), child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(IranFormat.digits(index + 1), style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)))), const SizedBox(width: 10), Expanded(child: Text(line.kala.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))), IconButton(onPressed: () => setState(() => _lines.removeAt(index)), icon: const Icon(Icons.delete_outline_rounded, color: Colors.red))]), const SizedBox(height: 12), Row(children: [Expanded(child: TextFormField(initialValue: line.quantity.toString(), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تعداد', border: OutlineInputBorder()), onChanged: (v) => setState(() => line.quantity = double.tryParse(v.replaceAll(',', '')) ?? 0))), const SizedBox(width: 10), Expanded(child: TextFormField(key: ValueKey('partner-price-$index-${line.salePrice}'), initialValue: line.salePrice == 0 ? '' : CurrencyFormatter.format(line.salePrice), inputFormatters: [CurrencyFormatter.inputFormatter], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت فروش واحد', suffixText: 'ریال', border: OutlineInputBorder()), onChanged: (v) => setState(() => line.salePrice = CurrencyFormatter.parse(v))))]), const SizedBox(height: 10), TextFormField(key: ValueKey('partner-cost-$index-${line.partnerCost}'), initialValue: line.partnerCost == 0 ? '' : CurrencyFormatter.format(line.partnerCost), inputFormatters: [CurrencyFormatter.inputFormatter], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بهای همکار', suffixText: 'ریال', border: OutlineInputBorder()), onChanged: (v) => setState(() => line.partnerCost = CurrencyFormatter.parse(v))), const SizedBox(height: 10), Row(children: [Text('جمع:', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)), const Spacer(), Text('${_money(total)} ریال', style: const TextStyle(fontWeight: FontWeight.w900))])]))); }

  Widget _summaryCard(double total, double profit, ThemeData theme) => Card(elevation: 0, color: theme.colorScheme.primaryContainer.withValues(alpha: .45), child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Row(children: [Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary), const SizedBox(width: 8), const Text('خلاصه فروش همکار', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]), const Divider(height: 24), _summaryRow('مشتری:', _customer?.fullName ?? 'انتخاب نشده'), const SizedBox(height: 8), _summaryRow('اقلام:', '${IranFormat.digits(_lines.length)} قلم'), const SizedBox(height: 8), _summaryRow('مبلغ فروش:', '${_money(total)} ریال', bold: true), const SizedBox(height: 8), _summaryRow('سود:', '${_money(profit)} ریال', bold: true, color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700), const SizedBox(height: 12), const Align(alignment: Alignment.centerRight, child: Text('این سند موجودی انبار خودمان را کاهش نمی‌دهد.', style: TextStyle(fontSize: 12)))])));
  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) => Row(children: [Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.left, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: color))) ]);

  void _chooseCustomer() { Person? picked; showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => EnhancedPersonSearchSheet(onSelected: (person) => picked = person)).then((_) { if (picked != null && mounted) setState(() => _customer = picked); }); }
  void _chooseProduct() { Kala? picked; showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => EnhancedKalaSearchSheet(onSelected: (kala) => picked = kala)).then((_) { if (picked == null || !mounted) return; final i = _lines.indexWhere((x) => x.kala.id == picked!.id); setState(() { if (i >= 0) _lines[i].quantity += 1; else _lines.add(_PartnerSaleLine(kala: picked!, salePrice: picked!.salePrice ?? 0, partnerCost: picked!.purchasePrice ?? 0)); }); }); }

  Future<void> _submit() async {
    if (_customer == null) { _message('لطفاً مشتری را انتخاب کنید', true); return; }
    if (_lines.isEmpty) { _message('حداقل یک کالا اضافه کنید', true); return; }
    setState(() => _loading = true);
    try {
      final request = CreateDocumentRequest(idSal: idSal, sanadType: sanadType, idAnbar: idAnbar, idTaraf: _customer!.id, idTarafType: _customer!.personType, idMasool: idMasool, idSandogh: idSandogh, idSandoghType: idSandoghType, sabtDate: _sabtDate(), des: 'فروش از انبار همکار', sharh: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(), checkStock: false, items: _lines.map((line) => CreateDocumentItemRequest(idKala: line.kala.code, quantity: line.quantity, unitPrice: line.salePrice, purchasePrice: line.partnerCost, isIncoming: false)).toList());
      final doc = await context.read<DocumentApiRepository>().createPartnerSaleDocument(request: request);
      if (!mounted) return;
      setState(() { _lines.clear(); _customer = null; _noteController.clear(); });
      await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('سند فروش از انبار همکار ثبت شد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18), textAlign: TextAlign.center), const SizedBox(height: 8), Text('شماره فاکتور: ${IranFormat.digits(doc.idFaktor)}\nمبلغ: ${_money(doc.totalAmount)} ریال', textAlign: TextAlign.center)]), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تأیید'))]));
    } catch (e) { if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), true); } finally { if (mounted) setState(() => _loading = false); }
  }
  void _message(String text, bool error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700, behavior: SnackBarBehavior.floating));
}

class _PartnerSaleLine { final Kala kala; double quantity; double salePrice; double partnerCost; _PartnerSaleLine({required this.kala, this.quantity = 1, required this.salePrice, required this.partnerCost}); }
