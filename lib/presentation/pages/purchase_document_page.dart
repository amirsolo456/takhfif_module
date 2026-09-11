import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/kala.dart';
import '../../data/models/person.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../shared/controllers/order_registration_controller.dart';
import 'order_registration_page.dart';

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
  static const int defaultPurchaseSanadType = 13;

  Person? _supplier;
  final List<_PurchaseLine> _lines = [];
  final _noteController = TextEditingController();
  int _sanadType = defaultPurchaseSanadType;
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 850;
    final total = _lines.fold<double>(0, (s, x) => s + x.quantity * x.purchasePrice);
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت سند خرید')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(children: [
          Row(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('۱. تأمین‌کننده', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.business_center_outlined)),
                      title: Text(_supplier?.fullName ?? 'تأمین‌کننده انتخاب نشده'),
                      subtitle: _supplier?.mobile == null ? null : Text(_supplier!.mobile!),
                      trailing: FilledButton.icon(
                        onPressed: _chooseSupplier,
                        icon: const Icon(Icons.person_search),
                        label: const Text('انتخاب'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('۲. کالا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _chooseProduct,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('افزودن کالا به سند'),
                  ),
                  const SizedBox(height: 12),
                  ..._lines.asMap().entries.map((e) => _lineCard(e.key, e.value)),
                  const SizedBox(height: 12),
                  const Text('۳. تنظیمات سند', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'توضیحات', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: '$_sanadType',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'نوع سند خرید',
                      helperText: 'کد نوع سند خرید KianStore؛ در صورت نیاز قابل تغییر است.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _sanadType = int.tryParse(v) ?? defaultPurchaseSanadType,
                  ),
                  if (!isDesktop) ...[
                    const SizedBox(height: 20),
                    _summary(total),
                    const SizedBox(height: 20),
                    _submitButton(),
                  ],
                ]),
              ),
            ),
            if (isDesktop)
              SizedBox(width: 340, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                Expanded(child: _summary(total)),
                const SizedBox(height: 12),
                _submitButton(),
              ]))),
          ]),
          if (_loading) const Positioned.fill(child: ColoredBox(color: Color(0x55000000), child: Center(child: CircularProgressIndicator()))),
        ]),
      ),
    );
  }

  Widget _lineCard(int index, _PurchaseLine line) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(line.kala.name, style: const TextStyle(fontWeight: FontWeight.w800))),
            IconButton(onPressed: () => setState(() => _lines.removeAt(index)), icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ]),
          Row(children: [
            Expanded(child: TextFormField(
              initialValue: line.quantity.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'تعداد', border: OutlineInputBorder()),
              onChanged: (v) => line.quantity = double.tryParse(v.replaceAll(',', '')) ?? 0,
            )),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(
              initialValue: line.purchasePrice.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'قیمت خرید واحد', border: OutlineInputBorder()),
              onChanged: (v) => line.purchasePrice = double.tryParse(v.replaceAll(',', '')) ?? 0,
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _summary(double total) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('خلاصه خرید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text('تعداد ردیف: ${_lines.length}'),
        const SizedBox(height: 8),
        Text('جمع سند: ${NumberFormat('#,###').format(total)} ریال', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('ثبت نهایی سند خرید، کالاها را به‌صورت ورودی ثبت می‌کند و موجودی انبار را افزایش می‌دهد.'),
      ])));

  Widget _submitButton() => SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(onPressed: _loading ? null : _submit, icon: const Icon(Icons.add_box), label: const Text('ثبت سند خرید و افزایش موجودی')),
      );

  void _chooseSupplier() {
    showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PersonSearchSheet(onSelected: (p) => Navigator.pop(context, p)),
    ).then((p) {
      if (p != null && mounted) setState(() => _supplier = p);
    });
  }

  void _chooseProduct() {
    showModalBottomSheet<Kala>(
      context: context,
      isScrollControlled: true,
      builder: (_) => KalaSearchSheet(onSelected: (k) => Navigator.pop(context, k)),
    ).then((k) {
      if (k == null || !mounted) return;
      final existing = _lines.where((x) => x.kala.id == k.id).firstOrNull;
      setState(() {
        if (existing != null) {
          existing.quantity += 1;
        } else {
          _lines.add(_PurchaseLine(kala: k, purchasePrice: k.purchasePrice ?? 0));
        }
      });
    });
  }

  Future<void> _submit() async {
    if (_supplier == null) return _message('لطفاً تأمین‌کننده را انتخاب کنید', true);
    if (_lines.isEmpty) return _message('حداقل یک کالا اضافه کنید', true);
    if (_sanadType <= 0) return _message('نوع سند خرید معتبر نیست', true);
    if (_lines.any((x) => x.quantity <= 0 || x.purchasePrice < 0)) return _message('تعداد و قیمت خرید اقلام را بررسی کنید', true);

    setState(() => _loading = true);
    try {
      final repo = context.read<DocumentApiRepository>();
      final now = DateTime.now();
      final request = CreateDocumentRequest(
        idSal: idSal,
        sanadType: _sanadType,
        idAnbar: idAnbar,
        idTaraf: _supplier!.id,
        idTarafType: _supplier!.personType,
        idMasool: idMasool,
        idSandogh: idSandogh,
        idSandoghType: idSandoghType,
        sabtDate: '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}',
        des: 'سند خرید',
        sharh: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        checkStock: false,
        items: _lines.map((x) => CreateDocumentItemRequest(
          idKala: x.kala.code,
          quantity: x.quantity,
          unitPrice: x.purchasePrice,
          purchasePrice: x.purchasePrice,
          isIncoming: true,
        )).toList(),
      );
      final doc = await repo.createPurchaseDocument(request: request, sanadType: _sanadType);
      if (!mounted) return;
      setState(() { _lines.clear(); _supplier = null; _noteController.clear(); });
      await showDialog<void>(context: context, builder: (_) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 56),
        content: Text('سند خرید با موفقیت ثبت شد.\nشماره سند: ${doc.idFaktor}\nموجودی اقلام افزایش یافت.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تایید'))],
      ));
    } catch (e) {
      if (mounted) _message(e.toString(), true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? Colors.red : Colors.green));
  }
}

class _PurchaseLine {
  final Kala kala;
  double quantity;
  double purchasePrice;
  _PurchaseLine({required this.kala, this.quantity = 1, this.purchasePrice = 0});
}
