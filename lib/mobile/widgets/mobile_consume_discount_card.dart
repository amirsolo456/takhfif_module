import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../core/utils/currency_formatter.dart';

class MobileConsumeDiscountCard extends StatefulWidget {
  const MobileConsumeDiscountCard({super.key});

  @override
  State<MobileConsumeDiscountCard> createState() => _MobileConsumeDiscountCardState();
}

class _MobileConsumeDiscountCardState extends State<MobileConsumeDiscountCard> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
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
    _amountController.dispose();
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
      try {
        await context.read<DiscountController>().consumeCode(
          code: _codeController.text,
          amount: double.parse(_amountController.text.replaceAll(',', '')),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد با موفقیت مصرف شد'), backgroundColor: Colors.green));
          _codeController.clear();
          _amountController.clear();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('مصرف کد تخفیف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                decoration: InputDecoration(
                  labelText: 'کد تخفیف را وارد کنید',
                  hintText: _clipboardSuggestion != null ? 'پیشنهاد: $_clipboardSuggestion' : 'مثلاً KH8D92XA',
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                child: const Text('مصرف کد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
