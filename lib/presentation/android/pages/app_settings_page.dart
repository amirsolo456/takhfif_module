import 'package:flutter/material.dart';
import '../../../core/config/api_settings.dart';
import 'user_management_page.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ApiSettings.current;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تنظیمات'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('اتصال و واحد پول'),
                subtitle: Text(settings.baseUrl),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ApiSettingsPage(settings: settings)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('تعریف کاربر'),
                subtitle: const Text('ایجاد نام کاربری و رمز عبور برای کاربران مجاز'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserManagementPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
