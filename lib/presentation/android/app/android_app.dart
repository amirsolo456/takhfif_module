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
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFE4E4E7);
        }
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return const Color(0xFF27272A);
        }
        return const Color(0xFF18181B);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFA1A1AA);
        }
        return Colors.white;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFA1A1AA);
        }
        return Colors.white;
      }),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: Color(0xFF00A3FF), // Cyan blue active highlight matching image
            onPrimary: Colors.white,
            primaryContainer: Color(0xFF5A5A5A), // Table header grey from image
            onPrimaryContainer: Colors.white,
            secondary: Color(0xFF00A3FF),
            onSecondary: Colors.white,
            surface: Color(0xFF2D2D2D), // Dark grey row/card surface from image
            onSurface: Colors.white, // Crisp white text
            surfaceContainerHighest: Color(0xFF5A5A5A), // Header and sub-card grey from image
            onSurfaceVariant: Color(0xFFD0D0D0), // Light grey label text
            outline: Color(0xFF00A3FF),
            outlineVariant: Color(0xFF424242), // Thin divider lines
            error: Color(0xFFEF4444),
          )
        : const ColorScheme.light(
            primary: Color(0xFF18181B), // Solid black/dark charcoal primary
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFE4E4E7), // Soft grey container for selected items
            onPrimaryContainer: Color(0xFF18181B),
            secondary: Color(0xFF27272A),
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFF4F4F5),
            onSecondaryContainer: Color(0xFF18181B),
            tertiary: Color(0xFF18181B),
            surface: Colors.white, // Crisp white cards and modals
            onSurface: Color(0xFF18181B), // Dark text
            surfaceContainerHighest: Color(0xFFEEEEF2), // Light neutral input fill
            onSurfaceVariant: Color(0xFF71717A), // Muted labels
            outline: Color(0xFFD4D4D8),
            outlineVariant: Color(0xFFE2E2E8),
            error: Color(0xFFEF4444),
          );

    final buttonStyle = _blackWhiteButtonStyle();

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'BYekan',
      fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn', 'Arial', 'sans-serif'],
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontWeight: FontWeight.w800,
          fontSize: 17.5,
          height: 1.35,
          color: dark ? Colors.white : const Color(0xFF18181B),
        ),
        titleMedium: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontWeight: FontWeight.w700,
          fontSize: 15.5,
          height: 1.35,
          color: dark ? Colors.white : const Color(0xFF18181B),
        ),
        titleSmall: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          height: 1.35,
          color: dark ? const Color(0xFFD0D0D0) : const Color(0xFF3F3F46),
        ),
        bodyLarge: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontSize: 14.5,
          height: 1.4,
          color: dark ? Colors.white : const Color(0xFF18181B),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontSize: 13.5,
          height: 1.4,
          color: dark ? const Color(0xFFD0D0D0) : const Color(0xFF3F3F46),
        ),
        bodySmall: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontSize: 12,
          height: 1.35,
          color: dark ? const Color(0xFFA0A0A0) : const Color(0xFF71717A),
        ),
        labelLarge: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: dark ? Colors.white : const Color(0xFF18181B),
        ),
        labelMedium: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: dark ? const Color(0xFFD0D0D0) : const Color(0xFF3F3F46),
        ),
      ),
      scaffoldBackgroundColor: dark ? const Color(0xFF212121) : const Color(0xFFF4F4F6),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF212121) : const Color(0xFFF4F4F6),
        foregroundColor: dark ? Colors.white : const Color(0xFF18181B),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'BYekan',
          fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma', 'Vazirmatn'],
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : const Color(0xFF18181B),
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF2D2D2D) : Colors.white, // Dark grey background for detail cards in night mode
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: dark ? const Color(0xFF424242) : const Color(0xFFE2E2E8),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF383838) : const Color(0xFFEEEEF2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF424242) : const Color(0xFFE2E2E8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF424242) : const Color(0xFFE2E2E8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF00A3FF) : const Color(0xFF18181B),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        labelStyle: TextStyle(
          color: dark ? const Color(0xFFD0D0D0) : const Color(0xFF71717A),
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: dark ? const Color(0xFF888888) : const Color(0xFFA1A1AA),
          fontSize: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: dark ? const Color(0xFF424242) : const Color(0xFFE2E2E8)),
          foregroundColor: dark ? Colors.white : const Color(0xFF18181B),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? Colors.white : const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF0E0E0E);
          }
          return const Color(0xFFCECECE);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFECECEC);
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF585858)),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: Color(0xFF6B6B6B), width: 0.5);
          }
          return const BorderSide(color: Color(0xFF939393), width: 1.0);
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF0E0E0E);
          }
          return const Color(0xFFCECECE);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return const Color(0xFFF5F5F6);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return const Color(0xFFCECECE);
        }),
        trackOutlineWidth: WidgetStateProperty.all(0.5),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: dark ? const Color(0xFF00A3FF) : const Color(0xFF18181B),
        unselectedLabelColor: dark ? Colors.white54 : const Color(0xFF71717A),
        indicatorColor: dark ? const Color(0xFF00A3FF) : const Color(0xFF18181B),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'BYekan'),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontFamily: 'BYekan'),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? const Color(0xFF2D2D2D) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF2D2D2D) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF212121) : Colors.white,
        indicatorColor: dark ? const Color(0xFF383838) : const Color(0xFFE4E4E7),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: dark ? const Color(0xFF00A3FF) : const Color(0xFF18181B));
          }
          return IconThemeData(color: dark ? Colors.white70 : const Color(0xFF71717A));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: dark ? const Color(0xFF00A3FF) : const Color(0xFF18181B),
              fontFamily: 'BYekan',
            );
          }
          return TextStyle(fontSize: 12, color: dark ? Colors.white70 : const Color(0xFF71717A), fontFamily: 'BYekan');
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
