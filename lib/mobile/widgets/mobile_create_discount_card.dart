import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../data/models/discount_code.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/currency_formatter.dart';

class MobileCreateDiscountCard extends StatefulWidget {
  const MobileCreateDiscountCard({super.key});

  @override
  State<MobileCreateDiscountCard> createState() => _MobileCreateDiscountCardState();
}

class _MobileCreateDiscountCardState extends State<MobileCreateDiscountCard> {
  final _formKey = GlobalKey<FormState>();
  DiscountType _type = DiscountType.percentage;
  final _valueController = TextEditingController();
  final _limitController = TextEditingController();
  final _minPurchaseController = TextEditingController();
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

  void _pickDate(bool isStart) async {
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
      try {
        final value = double.parse(_valueController.text.replaceAll(',', ''));
        final minPurchase = _minPurchaseController.text.isEmpty 
            ? null 
            : double.parse(_minPurchaseController.text.replaceAll(',', ''));

        final code = await context.read<DiscountController>().createDiscount(
          type: _type,
          value: value,
          start: _startDate,
          end: _endDate,
          limit: int.parse(_limitController.text),
          minPurchase: minPurchase,
        );
        if (mounted) _showResult(code);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  void _showResult(String code) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('کد تخفیف صادر شد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
              child: Text(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy),
              label: const Text('کپی کد'),
            ),
          ],
        ),
      ),
    );
    _formKey.currentState?.reset();
    _valueController.clear();
    _limitController.clear();
    _minPurchaseController.clear();
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
              const Text('صدور کد تخفیف جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              DropdownButtonFormField<DiscountType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'نوع تخفیف', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _type = v!),
                items: const [
                  DropdownMenuItem(value: DiscountType.percentage, child: Text('درصدی')),
                  DropdownMenuItem(value: DiscountType.fixed, child: Text('مبلغ ثابت')),
                ],
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
                decoration: const InputDecoration(labelText: 'حداقل مبلغ خرید (کف خرید)', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'شروع', border: OutlineInputBorder()),
                        child: Text(AppDateFormatter.toPersian(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'پایان', border: OutlineInputBorder()),
                        child: Text(AppDateFormatter.toPersian(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(labelText: 'تعداد دفعات قابل استفاده', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('صدور کد تخفیف'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
