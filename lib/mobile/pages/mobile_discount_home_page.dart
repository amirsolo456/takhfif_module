import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import 'mobile_discount_codes_page.dart';
import 'mobile_discount_history_page.dart';
import '../widgets/mobile_create_discount_card.dart';
import '../widgets/mobile_consume_discount_card.dart';

class MobileDiscountHomePage extends StatefulWidget {
  const MobileDiscountHomePage({super.key});

  @override
  State<MobileDiscountHomePage> createState() => _MobileDiscountHomePageState();
}

class _MobileDiscountHomePageState extends State<MobileDiscountHomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountController>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const MobileDashboard(),
      const MobileDiscountCodesPage(),
      const MobileDiscountHistoryPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت تخفیف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => _showBackupOptions(context),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'خانه'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'کدها'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'تاریخچه'),
        ],
      ),
    );
  }

  void _showBackupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('پشتیبان‌گیری (JSON)'),
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final path = await context.read<DiscountController>().exportData();
                if (path != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('ذخیره شد در: $path')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('بازیابی اطلاعات'),
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final success = await context.read<DiscountController>().importData();
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('بازیابی شد')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MobileDashboard extends StatelessWidget {
  const MobileDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DiscountController>().refreshData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            MobileCreateDiscountCard(),
            SizedBox(height: 16),
            MobileConsumeDiscountCard(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
