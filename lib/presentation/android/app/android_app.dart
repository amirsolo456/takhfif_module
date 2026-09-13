import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../../../shared/controllers/theme_controller.dart';
import '../pages/main_navigation_page.dart';

class AndroidApp extends StatelessWidget {
  const AndroidApp({super.key});

  ButtonStyle _blackWhiteButtonStyle() {
    return ButtonStyle(
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Colors.white;
        }
        return Colors.black;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return const BorderSide(color: Colors.black, width: 1.5);
        }
        return const BorderSide(color: Colors.white, width: 1.5);
      }),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            primaryContainer: Color(0xFF2C2C2E),
            onPrimaryContainer: Colors.white,
            secondary: Color(0xFFA0A0A0),
            surface: Color(0xFF1C1C1E),
            onSurface: Colors.white,
            surfaceContainerHighest: Color(0xFF2C2C2E),
            outlineVariant: Color(0xFF3A3A3C),
          )
        : const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFEFEFEF),
            onPrimaryContainer: Colors.black,
            secondary: Color(0xFF666666),
            surface: Colors.white,
            onSurface: Colors.black,
            surfaceContainerHighest: Color(0xFFF0F0F2),
            outlineVariant: Color(0xFFE0E0E0),
          );

    final buttonStyle = _blackWhiteButtonStyle();

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Tahoma',
      scaffoldBackgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF7F7F8),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'خاتون',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: themeController.isDark ? ThemeMode.dark : ThemeMode.light,
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
