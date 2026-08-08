import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/platform_helper.dart';
import 'shared/controllers/discount_controller.dart';
import 'windows/windows_app.dart';
import 'mobile/mobile_app.dart';

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
    if (PlatformHelper.isWindows) {
      return const WindowsApp();
    } else {
      return const MobileApp();
    }
  }
}
