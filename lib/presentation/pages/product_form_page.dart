import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/order_registration_controller.dart';

class ProductFormPage extends StatefulWidget {
  final String? initialSearch;
  const ProductFormPage({super.key, this.initialSearch});
  @override State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  final _sale = TextEditingController();
  final _purchase = TextEditingController();
  final _barcode = TextEditingController();
  bool _saving = false;
  @override void initState() { super.initState(); _code = TextEditingController(); _name = TextEditingController(text: widget.initialSearch?.trim() ?? ''); }
  @override void dispose() { _code.dispose(); _name.dispose(); _sale.dispose(); _purchase.dispose(); _barcode.dispose(); super.dispose(); }
  double _parse(String value) { var v = value.replaceAll(',', '').replaceAll('٬', '').replaceAll('٫', '.'); const fa = '۰۱۲۳۴۵۶۷۸۹'; const ar = '٠١٢٣٤٥٦٧٨٩'; final b = StringBuffer(); for (final c in v.runes) { final ch = String.fromCharCode(c); final i = fa.indexOf(ch); final j = ar.indexOf(ch); b.write(i >= 0 ? i : (j >= 0 ? j : ch)); } return double.tryParse(b.toString()) ?? 0; }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('تعریف کالای جدید'), centerTitle: true), body: Directionality(textDirection: TextDirection.rtl, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(children: [
    TextFormField(controller: _name, autofocus: widget.initialSearch?.trim().isNotEmpty != true, decoration: const InputDecoration(labelText: 'نام کالا', prefixIcon: Icon(Icons.inventory_2_rounded), border: OutlineInputBorder()), validator: (v) => v!.trim().isEmpty ? 'نام کالا الزامی است' : null),
    const SizedBox(height: 14), TextFormField(controller: _code, decoration: const InputDecoration(labelText: 'کد کالا', prefixIcon: Icon(Icons.tag_rounded), helperText: 'کد باید یکتا باشد.', border: OutlineInputBorder()), validator: (v) => v!.trim().isEmpty ? 'کد کالا الزامی است' : null),
    const SizedBox(height: 14), Row(children: [Expanded(child: TextFormField(controller: _sale, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت فروش', suffixText: 'ریال', border: OutlineInputBorder()))), const SizedBox(width: 10), Expanded(child: TextFormField(controller: _purchase, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت خرید', suffixText: 'ریال', border: OutlineInputBorder())))]),
    const SizedBox(height: 14), TextFormField(controller: _barcode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بارکد (اختیاری)', prefixIcon: Icon(Icons.qr_code_2_rounded), border: OutlineInputBorder())),
    const SizedBox(height: 24), SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.add_task_rounded), label: const Text('ثبت و انتخاب کالا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
  ])))));
  Future<void> _save() async { if (!_formKey.currentState!.validate()) return; setState(() => _saving = true); try { final kala = await context.read<OrderRegistrationController>().createKala(code: _code.text, name: _name.text, salePrice: _parse(_sale.text), purchasePrice: _parse(_purchase.text), barcode: _barcode.text); if (mounted) Navigator.pop(context, kala); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red)); } finally { if (mounted) setState(() => _saving = false); } }
}
