import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_settings.dart';
import '../../../data/repositories/auth_repository.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose(); _password.dispose(); _firstName.dispose(); _lastName.dispose(); super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    try {
      final token = await AuthRepository(baseUrl: ApiSettings.current.baseUrl).getToken();
      if (token == null || token.isEmpty) throw Exception('نشست ورود معتبر نیست.');
      final response = await http.post(
        Uri.parse('${ApiSettings.current.baseUrl}/api/mobile-users'),
        headers: {'Accept':'application/json','Content-Type':'application/json','Authorization':'Bearer $token'},
        body: jsonEncode({'username':_username.text.trim(),'password':_password.text,'firstName':_firstName.text.trim(),'lastName':_lastName.text.trim(),'access':2}),
      ).timeout(const Duration(seconds:20));
      Map<String,dynamic> body = const {};
      try { final decoded = jsonDecode(response.body); if (decoded is Map<String,dynamic>) body = decoded; } catch (_) {}
      if (response.statusCode != 200 || body['success'] != true) throw Exception(body['message']?.toString() ?? 'ایجاد کاربر انجام نشد.');
      if (!mounted) return;
      _username.clear(); _password.clear(); _firstName.clear(); _lastName.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کاربر با موفقیت ایجاد شد ✅')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مدیریت کاربران'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.manage_accounts_outlined, size: 56),
          const SizedBox(height:12),
          const Text('تعریف کاربر جدید', textAlign:TextAlign.center, style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          const SizedBox(height:24),
          TextFormField(controller:_username,textDirection:TextDirection.ltr,decoration:const InputDecoration(labelText:'نام کاربری',prefixIcon:Icon(Icons.person_outline)),validator:(v)=>v==null||v.trim().isEmpty?'نام کاربری را وارد کنید.':null),
          const SizedBox(height:14),
          TextFormField(controller:_password,obscureText:_obscure,textDirection:TextDirection.ltr,decoration:InputDecoration(labelText:'رمز عبور',prefixIcon:const Icon(Icons.password_outlined),suffixIcon:IconButton(onPressed:()=>setState(()=>_obscure=!_obscure),icon:Icon(_obscure?Icons.visibility_outlined:Icons.visibility_off_outlined))),validator:(v)=>v==null||v.length<4?'رمز عبور حداقل ۴ کاراکتر باشد.':null),
          const SizedBox(height:14),
          TextFormField(controller:_firstName,decoration:const InputDecoration(labelText:'نام (اختیاری)',prefixIcon:Icon(Icons.badge_outlined))),
          const SizedBox(height:14),
          TextFormField(controller:_lastName,decoration:const InputDecoration(labelText:'نام خانوادگی (اختیاری)',prefixIcon:Icon(Icons.badge_outlined))),
          const SizedBox(height:24),
          FilledButton.icon(onPressed:_loading?null:_create,icon:_loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.person_add_alt_1),label:Text(_loading?'در حال ایجاد...':'ایجاد کاربر'),style:FilledButton.styleFrom(minimumSize:const Size(double.infinity,50))),
        ]),
      ),
    ),
  );
}
