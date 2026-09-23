import 'package:flutter/material.dart';
import '../../../core/config/api_settings.dart';
import '../../../data/repositories/auth_repository.dart';
import 'login_page.dart';
import 'user_management_page.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خروج از حساب کاربری'),
          content: const Text('آیا برای خروج از حساب کاربری خود اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !context.mounted) return;

    final authRepo = AuthRepository(baseUrl: ApiSettings.current.baseUrl);
    await authRepo.clearSession();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(authRepository: authRepo),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ApiSettings.current;
    final theme = Theme.of(context);

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
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: .25),
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                title: Text(
                  'خروج از حساب کاربری',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                subtitle: const Text('پاکسازی نشست و بازگشت به صفحه ورود'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _confirmLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
