import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_settings.dart';
import '../../pages/order_registration_page.dart';
import '../../pages/discount_code_list_page.dart';
import '../../pages/orders_page.dart';
import 'mobile_discount_home_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  List<Widget> _buildPages() => [
        const OrderRegistrationPage(),
        const DiscountCodeListPage(),
        const OrdersPage(),
        const MobileDashboard(),
      ];

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AppHeader(
              onSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ApiSettingsPage(
                      settings: context.read<ApiSettings>(),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart),
            label: 'ثبت سفارش',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'کدهای تخفیف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'تاریخچه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'داشبورد',
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final VoidCallback onSettings;

  const _AppHeader({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withOpacity(.35)),
          ),
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'تنظیمات اتصال',
              onPressed: onSettings,
              icon: const Icon(Icons.settings_rounded),
            ),
            const Spacer(),
            const Text(
              'مدیریت تخفیف',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.point_of_sale_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
