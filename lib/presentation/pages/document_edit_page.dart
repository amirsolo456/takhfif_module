import 'package:flutter/material.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../shared/utils/iran_format.dart';

class DocumentEditPage extends StatefulWidget {
  final DocumentApiRepository repository;
  final int idSal;
  final String id;
  const DocumentEditPage({super.key, required this.repository, required this.idSal, required this.id});

  @override
  State<DocumentEditPage> createState() => _DocumentEditPageState();
}

class _EditRow {
  final TextEditingController code;
  final TextEditingController qty;
  final TextEditingController purchase;
  final TextEditingController sale;
  _EditRow({required String code, required double qty, required double purchase, required double sale})
      : code = TextEditingController(text: code),
        qty = TextEditingController(text: _n(qty)),
        purchase = TextEditingController(text: _n(purchase)),
        sale = TextEditingController(text: _n(sale));
  static String _n(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
  void dispose() { code.dispose(); qty.dispose(); purchase.dispose(); sale.dispose(); }
}

class _DocumentEditPageState extends State<DocumentEditPage> {
  late Future<DocumentModel> _future;
  final rows = <_EditRow>[];
  bool saving = false;
  bool initialized = false;

  @override
  void initState() { super.initState(); _future = widget.repository.getDocument(idSal: widget.idSal, id: widget.id); }

  void _initRows(DocumentModel d) {
    if (initialized) return;
    initialized = true;
    rows.addAll(d.items.map((x) => _EditRow(code: x.idKala, qty: x.quantity, purchase: x.purchasePrice, sale: x.unitPrice)));
    if (rows.isEmpty) _addRow();
  }

  void _addRow() => setState(() => rows.add(_EditRow(code: '', qty: 1, purchase: 0, sale: 0)));
  void _removeRow(int i) { final row = rows.removeAt(i); row.dispose(); setState(() {}); }

  double _number(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;

  Future<void> _save() async {
    if (saving) return;
    final items = <Map<String, dynamic>>[];
    for (final row in rows) {
      final code = row.code.text.trim();
      final qty = _number(row.qty);
      if (code.isEmpty || qty <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد کالا و تعداد همه ردیف‌ها را صحیح وارد کنید.'))); return; }
      items.add({'idKala': code, 'quantity': qty, 'unitPrice': _number(row.sale), 'purchasePrice': _number(row.purchase), 'isIncoming': false});
    }
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک کالا باید در سند باشد.'))); return; }
    setState(() => saving = true);
    try {
      await widget.repository.updateSaleDocument(idSal: widget.idSal, id: widget.id, items: items);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سند با موفقیت ویرایش شد.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ویرایش سند'), centerTitle: true, actions: [IconButton(onPressed: saving ? null : _save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined))]),
        body: FutureBuilder<DocumentModel>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text(snap.error.toString()));
            final d = snap.data;
            if (d == null) return const Center(child: Text('اطلاعات سند دریافت نشد.'));
            _initRows(d);
            return ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Text('فاکتور ${IranFormat.digits(d.idFaktor)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('فقط کالاها و قیمت خرید/فروش قابل ویرایش هستند. می‌توانید کالا اضافه یا حذف کنید.'),
                const SizedBox(height: 14),
                ...List.generate(rows.length, (i) => _rowCard(i)),
                OutlinedButton.icon(onPressed: saving ? null : _addRow, icon: const Icon(Icons.add_outlined), label: const Text('افزودن کالا')),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('ذخیره تغییرات')),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {TextInputType keyboard = TextInputType.number}) => Expanded(child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true)));

  Widget _rowCard(int i) {
    final r = rows[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Row(children: [Text('کالا ${IranFormat.digits(i + 1)}', style: const TextStyle(fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: saving ? null : () => _removeRow(i), color: Colors.red, icon: const Icon(Icons.delete_outline))]),
          TextField(controller: r.code, keyboardType: TextInputType.text, decoration: const InputDecoration(labelText: 'کد کالا', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          Row(children: [_field('تعداد', r.qty), const SizedBox(width: 7), _field('قیمت خرید', r.purchase), const SizedBox(width: 7), _field('قیمت فروش', r.sale)]),
        ]),
      ),
    );
  }
}
