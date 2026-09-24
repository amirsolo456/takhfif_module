import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takhfif_module/presentation/android/pages/app_settings_page.dart';
import '../../../core/config/api_settings.dart';
import '../../../shared/controllers/theme_controller.dart';
import '../../pages/order_registration_page.dart';
import '../../pages/purchase_document_page.dart';
import '../../pages/discount_code_list_page.dart';
import '../../pages/orders_page.dart';
import '../../pages/pending_web_orders_page.dart';
import '../../widgets/app_more_actions_button.dart';
import '../../widgets/custom_settings_icon.dart';
import '../../pages/profit_report_page.dart';
import '../../pages/partner_sale_document_page.dart';
import '../../pages/partner_sale_history_page.dart';
import '../../pages/warehouse_management_page.dart';
import 'login_page.dart';
import '../../../data/repositories/auth_repository.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});
  @override State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _pages;
  late final AuthRepository _authRepository;
  late final Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _authRepository = AuthRepository(baseUrl: ApiSettings.current.baseUrl);
    _sessionFuture = _hasSession();
    _pages = const [OrderRegistrationPage(), PurchaseDocumentPage(), OrdersPage(idSal: 0)];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _hasSession() async {
    try {
      final user = await _authRepository.restoreSession();
      return user != null;
    } catch (_) {
      return false;
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openDiscountCodes() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiscountCodeListPage()));
  void _openProfitReport() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfitReportPage()));
  void _openPendingWebOrders() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingWebOrdersPage()));
  void _openPartnerSale() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartnerSaleDocumentPage()));
  void _openPartnerSaleHistory() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartnerSaleHistoryPage(idSal: 0)));
  void _openWarehouseManagement() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WarehouseManagementPage()));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const Scaffold(key: ValueKey('nav_loading'), body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.data != true) {
          child = LoginPage(key: const ValueKey('nav_login'), authRepository: _authRepository);
        } else {
          child = KeyedSubtree(key: const ValueKey('nav_main'), child: _buildMain(context));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: child,
        );
      },
    );
  }

  Widget _buildMain(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        _AppHeader(
          onSettings: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppSettingsPage())),
          onMore: () async {
            final action = await showMenu<String>(context: context, position: const RelativeRect.fromLTRB(16, 62, 16, 0), items: const [
              PopupMenuItem(value: 'discount', child: ListTile(leading: Icon(Icons.confirmation_number_outlined), title: Text('کدهای تخفیف'))),
              PopupMenuItem(value: 'profit', child: ListTile(leading: Icon(Icons.analytics_outlined), title: Text('گزارش سود'))),
              PopupMenuItem(value: 'pending', child: ListTile(leading: Icon(Icons.pending_actions), title: Text('فاکتورهای معلق'))),
              PopupMenuItem(value: 'partner-sale', child: ListTile(leading: Icon(Icons.local_shipping_outlined), title: Text('فروش از انبار همکار'))),
              PopupMenuItem(value: 'partner-history', child: ListTile(leading: Icon(Icons.history_outlined), title: Text('تاریخچه فروش همکار'))),
              PopupMenuItem(value: 'warehouse-management', child: ListTile(leading: Icon(Icons.warehouse_outlined), title: Text('مدیریت انبارها'))),
            ]);
            if (!mounted) return;
            switch (action) {
              case 'discount': _openDiscountCodes(); break;
              case 'profit': _openProfitReport(); break;
              case 'pending': _openPendingWebOrders(); break;
              case 'partner-sale': _openPartnerSale(); break;
              case 'partner-history': _openPartnerSaleHistory(); break;
              case 'warehouse-management': _openWarehouseManagement(); break;
            }
          },
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              if (_currentIndex != index) {
                setState(() => _currentIndex = index);
              }
            },
            children: _pages,
          ),
        ),
      ])),
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF262626) : Colors.white;
    final shadowColor = isDark ? Colors.black.withValues(alpha: .35) : Colors.black.withValues(alpha: .06);

    final items = const [
      _AppNavDestination(
        icon: Icons.add_shopping_cart_outlined,
        selectedIcon: Icons.add_shopping_cart_rounded,
        label: 'ثبت فروش',
      ),
      _AppNavDestination(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        label: 'ثبت خرید',
      ),
      _AppNavDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'تاریخچه اسناد',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              final activeColor = isDark ? Colors.white : const Color(0xFF0E0E0E);
              final inactiveColor = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF787878);

              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Top Indicator Line
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOutCubic,
                        width: isSelected ? 48.0 : 0.0,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                        ),
                      ),
                      // Content Column (Icon + Text)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 24,
                              color: isSelected ? activeColor : inactiveColor,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontFamily: 'BYekan',
                                fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                color: isSelected ? activeColor : inactiveColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AppNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
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
      height: 62, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .35)))),
      child: Row(children: [
        IconButton(tooltip: 'تنظیمات', onPressed: onSettings, icon: CustomSettingsIcon(size: 22, color: theme.colorScheme.onSurface), style: IconButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0)),
        const SizedBox(width: 4),
        AppMoreActionsButton(tooltip: 'بیشتر', onPressed: onMore),
        const SizedBox(width: 4),
        Tooltip(message: 'سوییچ به ${isDark ? 'تم روز' : 'تم شب'}', child: InkWell(onTap: () => themeController.toggleTheme(), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, size: 16), const SizedBox(width: 5), Text(isDark ? 'تم شب' : 'تم روز', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))])))),
        const Spacer(), const Text('خاتون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => Icon(
                Icons.store_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
        ),
      ]),
    ));
  }
}
