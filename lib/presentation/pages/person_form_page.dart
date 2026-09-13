import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/order_registration_controller.dart';
import '../../data/models/person.dart';

class PersonFormPage extends StatefulWidget {
  final String? initialSearch;

  const PersonFormPage({super.key, this.initialSearch});

  @override
  State<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<PersonFormPage> {
  static const MethodChannel _contactChannel = MethodChannel('app.khatoon/contacts');

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
      _mobileController.text = _cleanPhoneNumber(normalized);
      return;
    }

    _applyNameData(normalized);
  }

  void _applyNameData(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;
    _firstNameController.text = parts.first;
    if (parts.length > 1) {
      _lastNameController.text = parts.sublist(1).join(' ');
    } else {
      _lastNameController.clear();
    }
  }

  String _cleanPhoneNumber(String phone) {
    var clean = phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final c in clean.runes) {
      final ch = String.fromCharCode(c);
      final i = fa.indexOf(ch);
      final j = ar.indexOf(ch);
      b.write(i >= 0 ? i : (j >= 0 ? j : ch));
    }
    clean = b.toString();
    if (clean.startsWith('+98')) {
      clean = '0${clean.substring(3)}';
    } else if (clean.startsWith('98') && clean.length == 12) {
      clean = '0${clean.substring(2)}';
    }
    return clean;
  }

  Future<void> _pickFromContacts() async {
    try {
      final Map<dynamic, dynamic>? result = await _contactChannel.invokeMapMethod('pickContact');
      if (result != null) {
        final name = (result['name'] ?? '').toString();
        final phone = (result['phone'] ?? '').toString();
        if (mounted) {
          setState(() {
            if (name.isNotEmpty) _applyNameData(name);
            if (phone.isNotEmpty) _mobileController.text = _cleanPhoneNumber(phone);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اطلاعات مخاطب با موفقیت جایگذاری شد.')),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted && e.message != null && e.message!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت مخاطب: $e')),
        );
      }
    }
  }

  Widget _buildLabelWithAsterisk(String label, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Tahoma',
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: '* ',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('شخص جدید'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'مشخصات شخص جدید را وارد نمایید',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickFromContacts,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.contacts_rounded, size: 20),
                  label: const Text('انتخاب از مخاطبین گوشی', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                _buildLabelWithAsterisk('نوع شخص', isRequired: true),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _personType = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _personType == 1 ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _personType == 1 ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: 1,
                                groupValue: _personType,
                                onChanged: (v) => setState(() => _personType = v!),
                              ),
                              const Text('حقیقی', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _personType = 2),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _personType == 2 ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _personType == 2 ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: 2,
                                groupValue: _personType,
                                onChanged: (v) => setState(() => _personType = v!),
                              ),
                              const Text('حقوقی/شرکت', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_personType == 1) ...[
                  _buildLabelWithAsterisk('نام', isRequired: true),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(hintText: 'نام شخص را وارد کنید'),
                    validator: (v) => v!.trim().isEmpty ? 'نام الزامی است' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabelWithAsterisk('نام خانوادگی', isRequired: true),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(hintText: 'نام خانوادگی را وارد کنید'),
                    validator: (v) => v!.trim().isEmpty ? 'نام خانوادگی الزامی است' : null,
                  ),
                ] else ...[
                  _buildLabelWithAsterisk('نام شرکت / فروشگاه', isRequired: true),
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(hintText: 'نام شرکت یا فروشگاه را وارد کنید'),
                    validator: (v) => v!.trim().isEmpty ? 'نام شرکت الزامی است' : null,
                  ),
                ],
                const SizedBox(height: 16),
                _buildLabelWithAsterisk('شماره موبایل', isRequired: true),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(hintText: '۰۹۱۲۳۴۵۶۷۸۹'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.trim().isEmpty ? 'شماره موبایل الزامی است' : null,
                ),
                const SizedBox(height: 16),
                _buildLabelWithAsterisk('آدرس', isRequired: false),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: 'آدرس کامل (اختیاری)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _save,
                          child: const Text('تایید', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('انصراف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    final cleanMobile = _cleanPhoneNumber(mobile);
    final controller = context.read<OrderRegistrationController>();

    if (cleanMobile.isNotEmpty) {
      try {
        final existingPeople = await controller.searchPersons(cleanMobile);
        Person? duplicate;
        for (final p in existingPeople) {
          final pMobile = p.mobile != null ? _cleanPhoneNumber(p.mobile!) : '';
          if (pMobile.isNotEmpty && pMobile == cleanMobile) {
            duplicate = p;
            break;
          }
        }

        if (duplicate != null && mounted) {
          final personName = duplicate.fullName;
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 52),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'این شماره موبایل قبلاً ثبت شده است!',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'شماره «$mobile» قبلاً با نام «$personName» در سیستم ذخیره شده است.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ویرایش شماره'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, duplicate);
                  },
                  child: const Text('انتخاب همین شخص'),
                ),
              ],
            ),
          );
          return;
        }
      } catch (_) {
        // Continue to server creation if local check fails
      }
    }

    final data = {
      'personType': _personType,
      'firstName': _personType == 1 ? _firstNameController.text.trim() : null,
      'lastName': _personType == 1 ? _lastNameController.text.trim() : null,
      'companyName': _personType == 2 ? _companyController.text.trim() : null,
      'mobile': mobile,
      'phone': null,
      'nationalId': null,
      'economicCode': null,
      'address': _addressController.text.trim(),
      'postalCode': null,
      'email': null,
    };

    final person = await controller.createPerson(data);

    if (person != null && mounted) {
      Navigator.pop(context, person);
    } else if (mounted) {
      final errorMsg = controller.error ?? 'خطا در ثبت مشتری';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
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
