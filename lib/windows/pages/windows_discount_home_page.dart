import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../widgets/windows_create_discount_panel.dart';
import '../widgets/windows_consume_discount_panel.dart';
import '../widgets/windows_discount_table.dart';
import '../widgets/windows_usage_table.dart';

class WindowsDiscountHomePage extends StatefulWidget {
  const WindowsDiscountHomePage({super.key});

  @override
  State<WindowsDiscountHomePage> createState() => _WindowsDiscountHomePageState();
}

class _WindowsDiscountHomePageState extends State<WindowsDiscountHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountController>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سامانه مدیریت و مصرف کدهای تخفیف (Desktop)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'بروزرسانی',
            onPressed: () => context.read<DiscountController>().refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: 'پشتیبان‌گیری / بازیابی',
            onPressed: () => _showBackupMenu(context),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Management Panels
          Container(
            width: 400,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  WindowsCreateDiscountPanel(),
                  SizedBox(height: 24),
                  WindowsConsumeDiscountPanel(),
                ],
              ),
            ),
          ),
          // Right Side: Data Tables
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('کدهای تخفیف صادر شده', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Divider(),
                            Expanded(child: WindowsDiscountTable()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تاریخچه مصرف کدها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Divider(),
                            Expanded(child: WindowsUsageTable()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupMenu(BuildContext context) {
    final controller = context.read<DiscountController>();
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('پشتیبان‌گیری (JSON)'),
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final path = await controller.exportData();
              if (path != null) {
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('ذخیره شد در: $path')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline),
            title: const Text('بازیابی اطلاعات'),
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await controller.importData();
              if (success) {
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('بازیابی با موفقیت انجام شد')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('حذف تمام اطلاعات', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: const Text('آیا از حذف تمام کدهای تخفیف و تاریخچه مصرف اطمینان دارید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              context.read<DiscountController>().clearAll();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف همه'),
          ),
        ],
      ),
    );
  }
}
