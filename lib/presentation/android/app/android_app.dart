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
    _themeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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

  // Iran uses UTC+03:30 year-round. Automatic DST has not been used since 2022.
  static bool _iranIsNight() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3, minutes: 30));
    return now.hour >= 19 || now.hour < 6;
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F8F45),
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Tahoma',
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFFE1306C);
          }
          return dark ? Colors.white54 : Colors.black45;
        }),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF405DE6).withValues(alpha: .14);
          }
          return null;
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
