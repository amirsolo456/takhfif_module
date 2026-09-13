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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعریف خریدار جدید'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromContacts,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.contacts_rounded),
                  label: const Text('انتخاب از مخاطبین گوشی', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 20),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('شخص حقیقی')),
                    ButtonSegment(value: 2, label: Text('شخص حقوقی/شرکت')),
                  ],
                  selected: {_personType},
                  onSelectionChanged: (set) => setState(() => _personType = set.first),
                ),
                const SizedBox(height: 20),
                if (_personType == 1) ...[
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'نام', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline_rounded)),
                    validator: (v) => v!.trim().isEmpty ? 'نام الزامی است' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'نام خانوادگی', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_rounded)),
                    validator: (v) => v!.trim().isEmpty ? 'نام خانوادگی الزامی است' : null,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'نام شرکت / فروشگاه', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business_rounded)),
                    validator: (v) => v!.trim().isEmpty ? 'نام شرکت الزامی است' : null,
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'شماره موبایل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android_rounded)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.trim().isEmpty ? 'شماره موبایل الزامی است' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'آدرس (اختیاری)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('ثبت و انتخاب مشتری', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
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
