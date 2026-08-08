import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../core/utils/currency_formatter.dart';

class WindowsConsumeDiscountPanel extends StatefulWidget {
  const WindowsConsumeDiscountPanel({super.key});

  @override
  State<WindowsConsumeDiscountPanel> createState() => _WindowsConsumeDiscountPanelState();
}

class _WindowsConsumeDiscountPanelState extends State<WindowsConsumeDiscountPanel> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _codeFocusNode = FocusNode();
  String? _clipboardSuggestion;

  @override
  void initState() {
    super.initState();
    _codeFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _codeFocusNode.removeListener(_onFocusChange);
    _codeFocusNode.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _productController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onFocusChange() async {
    if (_codeFocusNode.hasFocus && _codeController.text.isEmpty) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty && _isValidCodeFormat(text)) {
        setState(() {
          _clipboardSuggestion = text.toUpperCase();
        });
      }
    } else if (!_codeFocusNode.hasFocus) {
      setState(() {
        _clipboardSuggestion = null;
      });
    }
  }

  bool _isValidCodeFormat(String text) {
    // Basic check: Alphanumeric and length 5-15
    return RegExp(r'^[A-Z0-9]{5,15}$', caseSensitive: false).hasMatch(text);
  }

  void _applySuggestion() {
    if (_clipboardSuggestion != null) {
      setState(() {
        _codeController.text = _clipboardSuggestion!;
        _clipboardSuggestion = null;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<DiscountController>();
      try {
        await controller.consumeCode(
          code: _codeController.text,
          phone: _phoneController.text,
          product: _productController.text,
          amount: double.parse(_amountController.text.replaceAll(',', '')),
          description: _descController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('کد تخفیف با موفقیت مصرف شد'), backgroundColor: Colors.green),
          );
          _reset();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _reset() {
    _codeController.clear();
    _phoneController.clear();
    _productController.clear();
    _amountController.clear();
    _descController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('ثبت مصرف کد تخفیف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                decoration: InputDecoration(
                  labelText: 'کد تخفیف',
                  hintText: _clipboardSuggestion != null ? 'پیشنهاد: $_clipboardSuggestion (Enter برای تایید)' : 'مثلاً KH8D92XA',
                  hintStyle: TextStyle(color: _clipboardSuggestion != null ? Colors.blue.withValues(alpha: 0.5) : null),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                textCapitalization: TextCapitalization.characters,
                onFieldSubmitted: (v) {
                  if (v.isEmpty && _clipboardSuggestion != null) {
                    _applySuggestion();
                  } else {
                    _submit();
                  }
                },
                validator: (v) => v!.isEmpty && _clipboardSuggestion == null ? 'اجباری' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'مبلغ خرید (تومان)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyFormatter.inputFormatter],
                validator: (v) => v!.isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'شماره مشتری', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(labelText: 'نام محصول', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'توضیحات اختیاری', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  child: const Text('مصرف و ثبت تراکنش'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
