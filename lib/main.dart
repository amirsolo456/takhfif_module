import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'core/config/api_settings.dart';
import 'shared/controllers/discount_controller.dart';
import 'shared/controllers/theme_controller.dart';
import 'shared/controllers/order_controller.dart';
import 'shared/controllers/invoice_registration_controller.dart';
import 'data/repositories/invoice_api_repository.dart';
import 'data/repositories/document_api_repository.dart';
import 'data/repositories/master_data_repository.dart';
import 'data/repositories/discount_code_api_repository.dart';
import 'data/repositories/sms_api_repository.dart';
import 'data/repositories/pending_web_order_api_repository.dart';
import 'shared/controllers/order_registration_controller.dart';
import 'shared/controllers/discount_code_controller.dart';
import 'presentation/android/app/android_app.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  Intl.defaultLocale = 'fa_IR';

  final apiSettings = ApiSettings();
  try {
    await apiSettings.load();
  } catch (e) {
    debugPrint('Error loading ApiSettings: $e');
  }
  final String baseUrl = apiSettings.baseUrl;

  debugPrint('Connecting to Backend at: $baseUrl');

  final invoiceRepo = InvoiceApiRepository(baseUrl: baseUrl);
  final documentRepo = DocumentApiRepository(baseUrl: baseUrl);
  final masterDataRepo = MasterDataRepository(baseUrl: baseUrl);
  final discountRepo = DiscountCodeApiRepository(baseUrl: baseUrl);
  final smsRepo = SmsApiRepository(baseUrl: baseUrl);
  final pendingWebOrderRepo = PendingWebOrderApiRepository(baseUrl: baseUrl);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider.value(value: apiSettings),
        Provider.value(value: smsRepo),
        ChangeNotifierProvider.value(value: documentRepo),
        Provider<MasterDataRepository>.value(value: masterDataRepo),
        ChangeNotifierProvider.value(value: discountRepo),
        ChangeNotifierProvider.value(value: pendingWebOrderRepo),
        ChangeNotifierProvider(create: (_) => DiscountController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => InvoiceRegistrationController(repository: invoiceRepo)),
        ChangeNotifierProvider(
          create: (context) => OrderRegistrationController(
            documentRepo: context.read<DocumentApiRepository>(),
            masterDataRepo: context.read<MasterDataRepository>(),
            discountRepo: context.read<DiscountCodeApiRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DiscountCodeController(repository: discountRepo)),
      ],
      child: const _StartupSplash(),
    ),
  );
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AndroidApp();
  }
}


class _StartupSplash extends StatefulWidget {
  const _StartupSplash();

  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash> {
  bool _showApp = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showApp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) return const RootApp();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF043D24),
        body: SizedBox.expand(
          child: Image.asset(
            'assets/icon/app_splash_screen.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
