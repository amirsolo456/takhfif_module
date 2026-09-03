import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/platform_helper.dart';
import 'shared/controllers/discount_controller.dart';
import 'shared/controllers/order_controller.dart';
import 'shared/controllers/invoice_registration_controller.dart';
import 'data/repositories/invoice_api_repository.dart';
import 'data/repositories/order_api_repository.dart';
import 'data/repositories/document_api_repository.dart';
import 'data/repositories/master_data_repository.dart';
import 'data/repositories/discount_code_api_repository.dart';
import 'data/repositories/sms_api_repository.dart';
import 'shared/controllers/order_registration_controller.dart';
import 'shared/controllers/discount_code_controller.dart';
import 'presentation/android/app/android_app.dart';
import 'presentation/ios/app/ios_app.dart';
import 'presentation/windows/app/windows_app.dart';
import 'presentation/macos/app/macos_app.dart';
import 'presentation/web/app/web_app.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  String baseUrl = configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : 'http://localhost:5069';

  if (!kIsWeb && Platform.isAndroid && configuredBaseUrl.isEmpty) {
    baseUrl = 'http://10.0.2.2:5069';
  }

  debugPrint('Connecting to Backend at: $baseUrl');

  final invoiceRepo = InvoiceApiRepository(baseUrl: baseUrl);
  final orderRepo = OrderApiRepository(baseUrl: baseUrl);
  final documentRepo = DocumentApiRepository(baseUrl: baseUrl);
  final masterDataRepo = MasterDataRepository(baseUrl: baseUrl);
  final discountRepo = DiscountCodeApiRepository(baseUrl: baseUrl);
  final smsRepo = SmsApiRepository(baseUrl: baseUrl);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: smsRepo),
        Provider<DocumentApiRepository>.value(value: documentRepo),
        Provider<MasterDataRepository>.value(value: masterDataRepo),
        Provider<DiscountCodeApiRepository>.value(value: discountRepo),
        ChangeNotifierProvider(create: (_) => DiscountController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(
          create: (_) => InvoiceRegistrationController(repository: invoiceRepo),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderRegistrationController(
            documentRepo: context.read<DocumentApiRepository>(),
            masterDataRepo: context.read<MasterDataRepository>(),
            discountRepo: context.read<DiscountCodeApiRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DiscountCodeController(repository: discountRepo),
        ),
      ],
      child: const RootApp(),
    ),
  );
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.isWeb) return const WebApp();
    if (PlatformHelper.isWindows) return const WindowsApp();
    if (PlatformHelper.isMacOS) return const MacOSApp();
    if (PlatformHelper.isAndroid) return const AndroidApp();
    if (PlatformHelper.isIOS) return const IOSApp();

    return const AndroidApp();
  }
}
