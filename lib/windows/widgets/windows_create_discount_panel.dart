import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../data/models/discount_code.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/currency_formatter.dart';

class WindowsCreateDiscountPanel extends StatefulWidget {
  const WindowsCreateDiscountPanel({super.key});

  @override
  State<WindowsCreateDiscountPanel> createState() => _WindowsCreateDiscountPanelState();
}

class _WindowsCreateDiscountPanelState extends State<WindowsCreateDiscountPanel> {
  final _formKey = GlobalKey<FormState>();
  DiscountType _type = DiscountType.percentage;
  final _valueController = TextEditingController();
  final _limitController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _valueController.addListener(() => setState(() {}));
    _minPurchaseController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _valueController.dispose();
    _limitController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  String _getEquivalentText() {
    final valueStr = _valueController.text.replaceAll(',', '');
    final minPurchaseStr = _minPurchaseController.text.replaceAll(',', '');

    if (valueStr.isEmpty || minPurchaseStr.isEmpty) return '';

    final value = double.tryParse(valueStr);
    final minPurchase = double.tryParse(minPurchaseStr);

    if (value == null || minPurchase == null || minPurchase <= 0) return '';

    if (_type == DiscountType.fixed) {
      final percent = (value / minPurchase) * 100;
      return 'معادل ${percent.toStringAsFixed(1)}٪ کل مبلغ خرید';
    } else {
      final amount = minPurchase * (value / 100);
      return 'معادل ${CurrencyFormatter.format(amount)} تومان از مبلغ خرید';
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => DatePickerDialog(
        initialDate: isStart ? _startDate : _endDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<DiscountController>();
      try {
        final value = double.parse(_valueController.text.replaceAll(',', ''));
        final minPurchase = _minPurchaseController.text.isEmpty 
            ? null 
            : double.parse(_minPurchaseController.text.replaceAll(',', ''));
        final maxDiscount = _maxDiscountController.text.isEmpty 
            ? null 
            : double.parse(_maxDiscountController.text.replaceAll(',', ''));

        final code = await controller.createDiscount(
          type: _type,
          value: value,
          start: _startDate,
          end: _endDate,
          limit: int.parse(_limitController.text),
          minPurchase: minPurchase,
          maxDiscount: maxDiscount,
        );
        if (mounted) {
          _showSuccess(code);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
        }
      }
    }
  }

  void _showSuccess(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کد تخفیف با موفقیت ایجاد شد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy),
              label: const Text('کپی و بستن'),
            ),
          ],
        ),
      ),
    );
    _formKey.currentState?.reset();
    _valueController.clear();
    _limitController.clear();
    _minPurchaseController.clear();
    _maxDiscountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('تعریف کد تخفیف جدید', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<DiscountType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'نوع تخفیف', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: DiscountType.percentage, child: Text('درصدی')),
                  DropdownMenuItem(value: DiscountType.fixed, child: Text('مبلغ ثابت')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _type == DiscountType.percentage ? 'درصد تخفیف' : 'مبلغ تخفیف (تومان)',
                  border: const OutlineInputBorder(),
                  helperText: _getEquivalentText(),
                  helperStyle: const TextStyle(color: Colors.blueAccent),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: _type == DiscountType.fixed ? [CurrencyFormatter.inputFormatter] : null,
                validator: (v) => v!.isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minPurchaseController,
                decoration: const InputDecoration(
                  labelText: 'حداقل مبلغ خرید (کف خرید)',
                  border: OutlineInputBorder(),
                  hintText: 'مثلاً 100,000',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyFormatter.inputFormatter],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'شروع اعتبار', border: OutlineInputBorder()),
                        child: Text(AppDateFormatter.toPersian(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'پایان اعتبار', border: OutlineInputBorder()),
                        child: Text(AppDateFormatter.toPersian(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(labelText: 'سقف تعداد دفعات مصرف', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 12),
              if (_type == DiscountType.percentage)
                TextFormField(
                  controller: _maxDiscountController,
                  decoration: const InputDecoration(labelText: 'حداکثر مبلغ تخفیف', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyFormatter.inputFormatter],
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('صدور کد تخفیف'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
