import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../pages/main_navigation_page.dart';

class AndroidApp extends StatefulWidget {
  const AndroidApp({super.key});

  @override
  State<AndroidApp> createState() => _AndroidAppState();
}

class _AndroidAppState extends State<AndroidApp> {
  Timer? _themeTimer;
  bool _isDark = _iranIsNight();

  @override
  void initState() {
    super.initState();
    _themeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final next = _iranIsNight();
      if (next != _isDark && mounted) {
        setState(() => _isDark = next);
      }
    });
  }

  @override
  void dispose() {
    _themeTimer?.cancel();
    super.dispose();
  }

  /// Tehran Time Zone (UTC+03:30).
  /// Daytime: 06:00 AM to 18:00 PM (6:00 PM) -> Light Theme
  /// Nighttime: 18:00 PM to 06:00 AM -> Dark Theme
  static bool _iranIsNight() {
    final utc = DateTime.now().toUtc();
    final tehranNow = utc.add(const Duration(hours: 3, minutes: 30));
    return tehranNow.hour >= 18 || tehranNow.hour < 6;
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F8F45),
      brightness: brightness,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Tahoma',
      scaffoldBackgroundColor: dark ? const Color(0xFF121212) : scheme.surface,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: buttonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: buttonShape),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            // Instagram magenta/pink handler color for checked state
            return const Color(0xFFE1306C);
          }
          return dark ? Colors.white54 : Colors.black45;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت فروشگاه',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      locale: const Locale('fa', 'IR'),
      home: const MainNavigationPage(),
    );
  }
}
