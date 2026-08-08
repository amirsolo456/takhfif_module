import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/platform_helper.dart';
import 'shared/controllers/discount_controller.dart';
import 'presentation/android/app/android_app.dart';
import 'presentation/ios/app/ios_app.dart';
import 'presentation/windows/app/windows_app.dart';
import 'presentation/macos/app/macos_app.dart';
import 'presentation/web/app/web_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiscountController()),
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
    
    // Fallback
    return const AndroidApp();
  }
}
