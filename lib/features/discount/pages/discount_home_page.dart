import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/discount_controller.dart';
import '../widgets/create_discount_card.dart';
import '../widgets/consume_discount_card.dart';
import 'discount_codes_page.dart';
import 'discount_history_page.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/discount_code.dart';

class DiscountHomePage extends StatefulWidget {
  const DiscountHomePage({super.key});

  @override
  State<DiscountHomePage> createState() => _DiscountHomePageState();
}

class _DiscountHomePageState extends State<DiscountHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountController>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت تخفیف'),
          actions: [
            IconButton(
              icon: const Icon(Icons.backup),
              onPressed: () => _showBackupOptions(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => context.read<DiscountController>().refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: CreateDiscountCard()),
                          SizedBox(width: 16),
                          Expanded(child: ConsumeDiscountCard()),
                        ],
                      );
                    } else {
                      return const Column(
                        children: [
                          CreateDiscountCard(),
                          SizedBox(height: 16),
                          ConsumeDiscountCard(),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: 'آخرین کدهای صادر شده',
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DiscountCodesPage()),
                  ),
                ),
                const SizedBox(height: 8),
                const RecentCodesList(),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: 'تاریخچه آخرین مصرف‌ها',
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DiscountHistoryPage()),
                  ),
                ),
                const SizedBox(height: 8),
                const RecentHistoryList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onSeeAll, child: const Text('مشاهده همه')),
      ],
    );
  }

  void _showBackupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('پشتیبان‌گیری (خروجی JSON)'),
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final path = await context.read<DiscountController>().exportData();
                if (path != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('فایل در مسیر $path ذخیره شد')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('بازیابی اطلاعات'),
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final success = await context.read<DiscountController>().importData();
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('اطلاعات با موفقیت بازیابی شد')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('پاک کردن تمام اطلاعات', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: const Text('آیا مطمئن هستید که می‌خواهید تمام کدهای تخفیف و تاریخچه مصرف را حذف کنید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              context.read<DiscountController>().clearAll();
              Navigator.pop(context);
            },
            child: const Text('حذف همه', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class RecentCodesList extends StatelessWidget {
  const RecentCodesList({super.key});

  @override
  Widget build(BuildContext context) {
    final codes = context.watch<DiscountController>().codes;
    if (codes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('کدی یافت نشد.'),
        ),
      );
    }
    
    final recent = codes.take(3).toList();
    return Column(
      children: recent.map((code) => Card(
        child: ListTile(
          title: Text(code.code, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${code.discountValue}${code.discountType == DiscountType.percentage ? '%' : ' تومان'}'),
          trailing: Chip(
            label: Text(code.status, style: const TextStyle(fontSize: 12)),
            backgroundColor: _getStatusColor(code.status),
          ),
        ),
      )).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'فعال': return Colors.green[100]!;
      case 'منقضی شده': return Colors.red[100]!;
      case 'تمام شده': return Colors.orange[100]!;
      default: return Colors.grey[300]!;
    }
  }
}

class RecentHistoryList extends StatelessWidget {
  const RecentHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<DiscountController>().history;
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('سابقه‌ای یافت نشد.'),
        ),
      );
    }

    final recent = history.take(3).toList();
    return Column(
      children: recent.map((item) => Card(
        child: ListTile(
          title: Text(item.discountCode),
          subtitle: Text(item.customerPhone ?? 'بدون شماره'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.discountAmount?.toStringAsFixed(0)} تومان', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text(AppDateFormatter.toPersian(item.usedAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
