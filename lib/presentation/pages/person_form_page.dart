import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/order_registration_controller.dart';

class PersonFormPage extends StatefulWidget {
  final String? initialSearch;

  const PersonFormPage({super.key, this.initialSearch});

  @override
  State<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<PersonFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  int _personType = 1; // 1: Haghighi, 2: Hoghoghi

  @override
  void initState() {
    super.initState();
    final query = widget.initialSearch?.trim() ?? '';

    if (query.isEmpty) return;

    final normalized = query.replaceAll(RegExp(r'\s+'), ' ');
    final isMostlyNumeric = RegExp(r'^[0-9۰-۹+\-\s]+$').hasMatch(normalized);

    if (isMostlyNumeric) {
      _mobileController.text = normalized;
      return;
    }

    final parts = normalized.split(' ');
    _firstNameController.text = parts.first;
    if (parts.length > 1) {
      _lastNameController.text = parts.sublist(1).join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعریف خریدار جدید')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('شخص حقیقی')),
                  ButtonSegment(value: 2, label: Text('شخص حقوقی/شرکت')),
                ],
                selected: {_personType},
                onSelectionChanged: (set) => setState(() => _personType = set.first),
              ),
              const SizedBox(height: 24),
              if (_personType == 1) ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'نام', border: OutlineInputBorder()),
                  validator: (v) => v!.trim().isEmpty ? 'اجباری' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'نام خانوادگی', border: OutlineInputBorder()),
                  validator: (v) => v!.trim().isEmpty ? 'اجباری' : null,
                ),
              ] else ...[
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'نام شرکت/فروشگاه', border: OutlineInputBorder()),
                  validator: (v) => v!.trim().isEmpty ? 'اجباری' : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'شماره موبایل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().isEmpty ? 'اجباری' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'آدرس', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('ثبت و انتخاب مشتری', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'personType': _personType,
      'firstName': _personType == 1 ? _firstNameController.text.trim() : null,
      'lastName': _personType == 1 ? _lastNameController.text.trim() : null,
      'companyName': _personType == 2 ? _companyController.text.trim() : null,
      'mobile': _mobileController.text.trim(),
      'phone': null,
      'nationalId': null,
      'economicCode': null,
      'address': _addressController.text.trim(),
      'postalCode': null,
      'email': null,
    };

    final controller = context.read<OrderRegistrationController>();
    final person = await controller.createPerson(data);

    if (person != null && mounted) {
      Navigator.pop(context, person);
    } else if (mounted) {
      final errorMsg = controller.error ?? 'خطا در ثبت مشتری';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'کپی خطا',
            textColor: Colors.white,
            onPressed: () => Clipboard.setData(ClipboardData(text: errorMsg)),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
