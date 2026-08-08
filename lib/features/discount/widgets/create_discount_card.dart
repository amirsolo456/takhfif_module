import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../controllers/discount_controller.dart';
import '../../../data/models/discount_code.dart';
import '../../../core/utils/date_formatter.dart';

class CreateDiscountCard extends StatefulWidget {
  const CreateDiscountCard({super.key});

  @override
  State<CreateDiscountCard> createState() => _CreateDiscountCardState();
}

class _CreateDiscountCardState extends State<CreateDiscountCard> {
  final _formKey = GlobalKey<FormState>();
  DiscountType _type = DiscountType.percentage;
  final _valueController = TextEditingController();
  final _limitController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  bool get _isValid {
    return _valueController.text.isNotEmpty && _limitController.text.isNotEmpty;
  }

  Future<void> _pickDate(bool isStart) async {
    final Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(isStart ? _startDate : _endDate),
      firstDate: Jalali(1400),
      lastDate: Jalali(1450),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked.toDateTime();
        } else {
          _endDate = picked.toDateTime();
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<DiscountController>();
      try {
        final code = await controller.createDiscount(
          type: _type,
          value: double.parse(_valueController.text),
          start: _startDate,
          end: _endDate,
          limit: int.parse(_limitController.text),
          minPurchase: _minPurchaseController.text.isEmpty ? null : double.parse(_minPurchaseController.text),
          maxDiscount: _maxDiscountController.text.isEmpty ? null : double.parse(_maxDiscountController.text),
        );

        if (mounted) {
          _showResultDialog(code);
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در صدور کد: $e')),
          );
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _valueController.clear();
      _limitController.clear();
      _minPurchaseController.clear();
      _maxDiscountController.clear();
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
    });
  }

  void _showResultDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کد تخفیف صادر شد', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('کد تولید شده:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('کد کپی شد')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('کپی کد'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'صدور کد تخفیف جدید',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _type == DiscountType.percentage ? 'درصد تخفیف' : 'مبلغ تخفیف (تومان)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_type == DiscountType.percentage ? Icons.percent : Icons.money),
                ),
                validator: (v) => v!.isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'تاریخ شروع', border: OutlineInputBorder()),
                        child: Text(AppDateFormatter.toPersian(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'تاریخ پایان', border: OutlineInputBorder()),
                        child: Text(AppDateFormatter.toPersian(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'تعداد دفعات قابل استفاده',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                validator: (v) => v!.isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('تنظیمات پیشرفته', style: TextStyle(fontSize: 14)),
                children: [
                  TextFormField(
                    controller: _minPurchaseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'حداقل مبلغ خرید', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _maxDiscountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'حداکثر مبلغ تخفیف', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('صدور کد تخفیف', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Jalali?> showPersianDatePicker({
  required BuildContext context,
  required Jalali initialDate,
  required Jalali firstDate,
  required Jalali lastDate,
}) async {
  return await showDialog<DateTime>(
    context: context,
    builder: (context) => Theme(
      data: Theme.of(context),
      child: DatePickerDialog(
        initialDate: initialDate.toDateTime(),
        firstDate: firstDate.toDateTime(),
        lastDate: lastDate.toDateTime(),
      ),
    ),
  ).then((value) => value != null ? Jalali.fromDateTime(value) : null);
}
