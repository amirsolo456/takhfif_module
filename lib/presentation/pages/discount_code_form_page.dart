import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../shared/controllers/discount_code_controller.dart';
import '../../shared/utils/money_formatter.dart';
import '../../shared/utils/iran_format.dart';
import '../../data/models/discount_code_model.dart';
import '../widgets/shamsi_date_picker_dialog.dart';

class DiscountCodeFormPage extends StatefulWidget {
  final DiscountCodeModel? code;
  const DiscountCodeFormPage({super.key, this.code});

  @override
  State<DiscountCodeFormPage> createState() => _DiscountCodeFormPageState();
}

class _DiscountCodeFormPageState extends State<DiscountCodeFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _valueController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _usageLimitController;
  late TextEditingController _perCustomerLimitController;
  late TextEditingController _descController;

  int _type = 1;
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final c = widget.code;
    _codeController = TextEditingController(text: c?.code);
    _titleController = TextEditingController(text: c?.title);
    _valueController = TextEditingController(text: c == null ? '۰' : c.type == 2 ? MoneyFormatter.format(c.value) : IranFormat.digits(c.value.toStringAsFixed(0)));
    _minAmountController = TextEditingController(text: c?.minOrderAmount == null ? null : MoneyFormatter.format(c!.minOrderAmount!));
    _maxAmountController = TextEditingController(text: c?.maxDiscountAmount == null ? null : MoneyFormatter.format(c!.maxDiscountAmount!));
    _usageLimitController = TextEditingController(text: c?.usageLimit == null ? null : IranFormat.digits(c!.usageLimit!));
    _perCustomerLimitController = TextEditingController(text: c?.perCustomerLimit == null ? null : IranFormat.digits(c!.perCustomerLimit!));
    _descController = TextEditingController(text: c?.description);

    if (c != null) {
      _type = c.type;
      _isActive = c.isActive;
      _startDate = c.startDate;
      _endDate = c.endDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFixedAmount = _type == 2;

    return Scaffold(
      appBar: AppBar(title: Text(widget.code == null ? 'ایجاد کد تخفیف' : 'ویرایش کد تخفیف')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'کد تخفیف (مثلا: SUMMER1403)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان (اختیاری)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'نوع تخفیف', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('درصدی')),
                  DropdownMenuItem(value: 2, child: Text('مبلغ ثابت')),
                ],
                onChanged: (v) => setState(() {
                  _type = v!;
                  if (_type == 2 && _valueController.text.isNotEmpty) {
                    _valueController.text = MoneyFormatter.format(MoneyFormatter.parse(_valueController.text));
                  } else if (_type == 1) {
                    _valueController.text = IranFormat.digits(MoneyFormatter.parse(_valueController.text).toStringAsFixed(0));
                  }
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: isFixedAmount ? 'مبلغ تخفیف' : 'مقدار درصد',
                  suffixText: isFixedAmount ? 'تومان' : '%',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: isFixedAmount ? [MoneyInputFormatter()] : const [],
                validator: (v) {
                  final val = isFixedAmount ? MoneyFormatter.parse(v ?? '') : IranFormat.parseNumber(v ?? '');
                  if (val == null || val < 0) return 'عدد نامعتبر';
                  if (_type == 1 && val > 100) return 'درصد نمی‌تواند بیش از ۱۰۰ باشد';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minAmountController,
                      decoration: const InputDecoration(labelText: 'حداقل خرید', suffixText: 'تومان', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [MoneyInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxAmountController,
                      decoration: const InputDecoration(labelText: 'سقف مبلغ تخفیف', suffixText: 'تومان', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [MoneyInputFormatter()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDatePicker('تاریخ شروع', _startDate, (d) => setState(() => _startDate = d))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker('تاریخ پایان', _endDate, (d) => setState(() => _endDate = d))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usageLimitController,
                      decoration: const InputDecoration(labelText: 'تعداد کل قابل استفاده', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _perCustomerLimitController,
                      decoration: const InputDecoration(labelText: 'سقف استفاده هر مشتری', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('وضعیت فعال'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'توضیحات', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('ذخیره'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onSelected) {
    final jalaliDate = date != null ? Jalali.fromDateTime(date) : Jalali.now();

    return InkWell(
      onTap: () async {
        final pickedJalali = await ShamsiDatePickerDialog.show(
          context: context,
          initialDate: jalaliDate,
        );
        if (pickedJalali != null) {
          onSelected(pickedJalali.toDateTime());
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_rounded),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date == null ? 'انتخاب کنید' : IranFormat.date(date.toIso8601String()),
          style: const TextStyle(
            fontFamily: 'BYekan',
            fontFamilyFallback: ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'code': _codeController.text,
      'title': _titleController.text,
      'type': _type,
      'value': _type == 2 ? MoneyFormatter.parse(_valueController.text) : IranFormat.parseNumber(_valueController.text) ?? 0,
      'minOrderAmount': _minAmountController.text.trim().isEmpty ? null : MoneyFormatter.parse(_minAmountController.text),
      'maxDiscountAmount': _maxAmountController.text.trim().isEmpty ? null : MoneyFormatter.parse(_maxAmountController.text),
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'usageLimit': IranFormat.parseNumber(_usageLimitController.text)?.toInt(),
      'perCustomerLimit': IranFormat.parseNumber(_perCustomerLimitController.text)?.toInt(),
      'isActive': _isActive,
      'description': _descController.text,
    };

    final controller = context.read<DiscountCodeController>();
    bool success;
    if (widget.code == null) {
      success = await controller.createCode(data);
    } else {
      success = await controller.updateCode(widget.code!.id, data);
    }

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.error ?? 'خطا در ذخیره'), backgroundColor: Colors.red));
    }
  }
}
