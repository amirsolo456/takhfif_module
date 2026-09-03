import 'package:flutter/material.dart';
import '../../pages/order_registration_page.dart';
import '../../pages/discount_code_list_page.dart';
import 'mobile_discount_history_page.dart';
import 'mobile_discount_home_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OrderRegistrationPage(),
    const DiscountCodeListPage(),
    const MobileDiscountHistoryPage(),
    const MobileDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_shopping_cart), label: 'ثبت سفارش'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'کدهای تخفیف'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'تاریخچه'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'داشبورد'),
        ],
      ),
    );
  }
}
