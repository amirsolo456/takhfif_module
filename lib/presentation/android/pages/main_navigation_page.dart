import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_settings.dart';
import '../../../shared/controllers/theme_controller.dart';
import '../../pages/order_registration_page.dart';
import '../../pages/purchase_document_page.dart';
import '../../pages/discount_code_list_page.dart';
import '../../pages/orders_page.dart';
import '../../pages/pending_web_orders_page.dart';
import '../../pages/profit_report_page.dart';
import '../../pages/partner_sale_document_page.dart';
import 'mobile_discount_home_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});
  @override State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  List<Widget> _buildPages() => [const OrderRegistrationPage(), const PurchaseDocumentPage(), const OrdersPage(idSal: 0)];

  void _openDashboard() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('داشبورد تخفیف‌ها'), centerTitle: true), body: const MobileDashboard())));
  void _openDiscountCodes() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiscountCodeListPage()));
  void _openProfitReport() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfitReportPage()));
  void _openPendingWebOrders() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingWebOrdersPage()));
  void _openPartnerSale() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartnerSaleDocumentPage()));

  @override Widget build(BuildContext context) {
    final pages = _buildPages();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(child: Column(children: [
        _AppHeader(
          onSettings: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApiSettingsPage(settings: context.read<ApiSettings>()))),
          onMore: () async {
            final action = await showMenu<String>(context: context, position: const RelativeRect.fromLTRB(16, 62, 16, 0), items: const [
              PopupMenuItem(value: 'dashboard', child: ListTile(leading: Icon(Icons.dashboard_outlined), title: Text('داشبورد'))),
              PopupMenuItem(value: 'discount', child: ListTile(leading: Icon(Icons.confirmation_number_outlined), title: Text('کدهای تخفیف'))),
              PopupMenuItem(value: 'profit', child: ListTile(leading: Icon(Icons.analytics_outlined), title: Text('گزارش سود'))),
              PopupMenuItem(value: 'pending', child: ListTile(leading: Icon(Icons.pending_actions), title: Text('فاکتورهای معلق'))),
              PopupMenuItem(value: 'partner-sale', child: ListTile(leading: Icon(Icons.local_shipping_outlined), title: Text('فروش از انبار همکار'))),
            ]);
            if (!mounted) return;
            switch (action) {
              case 'dashboard': _openDashboard(); break;
              case 'discount': _openDiscountCodes(); break;
              case 'profit': _openProfitReport(); break;
              case 'pending': _openPendingWebOrders(); break;
              case 'partner-sale': _openPartnerSale(); break;
            }
          },
        ),
        Expanded(child: IndexedStack(index: _currentIndex, children: pages)),
      ])),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Container(
        height: 68,
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .92), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? .25 : .08), blurRadius: 16, offset: const Offset(0, 4))], border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .5))),
        child: ClipRRect(borderRadius: BorderRadius.circular(28), child: NavigationBar(
          selectedIndex: _currentIndex, onDestinationSelected: (index) => setState(() => _currentIndex = index), backgroundColor: Colors.transparent, elevation: 0, height: 68, labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, indicatorColor: theme.colorScheme.primaryContainer,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.add_shopping_cart_outlined), selectedIcon: Icon(Icons.add_shopping_cart_outlined), label: 'ثبت فروش'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_outlined), label: 'ثبت خرید'),
            NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_outlined), label: 'تاریخچه اسناد'),
          ],
        )),
      ))),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback onMore;
  const _AppHeader({required this.onSettings, required this.onMore});

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = context.watch<ThemeController>();
    final isDark = themeController.isDark;
    return Material(color: theme.colorScheme.surface, elevation: 0, surfaceTintColor: Colors.transparent, shadowColor: Colors.transparent, child: Container(
      height: 62, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .35))),),
      child: Row(children: [
        IconButton(tooltip: 'تنظیمات اتصال', onPressed: onSettings, icon: const Icon(Icons.settings_outlined), style: IconButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0)),
        IconButton(tooltip: 'بیشتر', onPressed: onMore, icon: const Icon(Icons.more_vert_outlined), style: IconButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0)),
        const SizedBox(width: 4),
        Tooltip(message: 'سوییچ به ${isDark ? 'تم روز' : 'تم شب'}', child: InkWell(onTap: () => themeController.toggleTheme(), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, size: 16, color: isDark ? Colors.indigoAccent : Colors.amber.shade800), const SizedBox(width: 5), Text(isDark ? 'تم شب' : 'تم روز', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))])))),
        const Spacer(), const Text('خاتون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 10),
        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .5))), child: Icon(Icons.point_of_sale_outlined, color: theme.colorScheme.primary)),
      ]),
    ));
  }
}
