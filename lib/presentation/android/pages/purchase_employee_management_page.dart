import 'package:flutter/material.dart';
import '../../../core/config/api_settings.dart';
import '../../../data/models/purchase_employee.dart';
import '../../../data/repositories/purchase_employee_repository.dart';

class PurchaseEmployeeManagementPage extends StatefulWidget {
  const PurchaseEmployeeManagementPage({super.key});
  @override
  State<PurchaseEmployeeManagementPage> createState() => _PurchaseEmployeeManagementPageState();
}

class _PurchaseEmployeeManagementPageState extends State<PurchaseEmployeeManagementPage> {
  late final PurchaseEmployeeRepository _repository;
  late Future<List<PurchaseEmployee>> _future;

  @override
  void initState() {
    super.initState();
    _repository = PurchaseEmployeeRepository(baseUrl: ApiSettings.current.baseUrl);
    _future = _repository.getAll();
  }

  void _refresh() => setState(() => _future = _repository.getAll());

  Future<void> _edit([PurchaseEmployee? employee]) async {
    final nameController = TextEditingController(text: employee?.name ?? '');
    final mobileController = TextEditingController(text: employee?.mobile ?? '');
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(employee == null ? 'تعریف خریدار داخلی' : 'ویرایش خریدار داخلی'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره تماس (اختیاری)', prefixIcon: Icon(Icons.phone_outlined))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(employee == null ? 'ثبت' : 'ذخیره')),
            ],
          ),
        ),
      );
      if (result != true || !mounted) return;
      final name = nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام را وارد کنید.')));
        return;
      }
      if (employee == null) {
        await _repository.create(name: name, mobile: mobileController.text.trim().isEmpty ? null : mobileController.text.trim());
      } else {
        await _repository.update(id: employee.id, name: name, mobile: mobileController.text.trim().isEmpty ? null : mobileController.text.trim());
      }
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(employee == null ? 'خریدار داخلی ثبت شد ✅' : 'اطلاعات ویرایش شد ✅')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      nameController.dispose();
      mobileController.dispose();
    }
  }

  Future<void> _disable(PurchaseEmployee employee) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('غیرفعال کردن'),
          content: Text('«${employee.name}» از فهرست خریداران داخلی حذف شود؟ سوابق قبلی باقی می‌ماند.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('غیرفعال کن')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _repository.disable(employee.id);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خریدار داخلی غیرفعال شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('کارکنان خریدار'), centerTitle: true),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.person_add_alt_1), label: const Text('تعریف خریدار')),
          body: FutureBuilder<List<PurchaseEmployee>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد')));
              final employees = snapshot.data ?? const <PurchaseEmployee>[];
              if (employees.isEmpty) return const Center(child: Text('هنوز کارمند خریدی تعریف نشده است.'));
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = employees[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(e.mobile?.isNotEmpty == true ? e.mobile! : 'شماره تماس ثبت نشده'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) { if (value == 'edit') _edit(e); if (value == 'disable') _disable(e); },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                            PopupMenuItem(value: 'disable', child: Text('غیرفعال کردن')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
}
