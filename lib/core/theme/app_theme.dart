import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _black = Colors.black;
  static const _white = Colors.white;
  static const _surfaceSoft = Color(0xFFF7F7F7);
  static const _border = Color(0xFFE6E6E6);
  static const _muted = Color(0xFF6B6B6B);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _black,
      brightness: Brightness.light,
      primary: _black,
      onPrimary: _white,
      secondary: Color(0xFF2B2B2B),
      onSecondary: _white,
      surface: _white,
      onSurface: _black,
      error: Color(0xFFB42318),
      onError: _white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: _surfaceSoft,
      fontFamily: 'Tahoma',
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        backgroundColor: _white,
        foregroundColor: _black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Tahoma',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: _black,
        ),
      ),
      cardTheme: CardThemeData(
        color: _white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _black, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB42318)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _black,
          foregroundColor: _white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Tahoma', fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _black,
          foregroundColor: _white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Tahoma', fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _black,
          side: const BorderSide(color: _border),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: _white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color(0xFFEAEAEA),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Tahoma', fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: _white,
        indicatorColor: Color(0xFFEAEAEA),
        selectedIconTheme: IconThemeData(color: _black),
        selectedLabelTextStyle: TextStyle(fontFamily: 'Tahoma', color: _black, fontWeight: FontWeight.w700),
        unselectedIconTheme: IconThemeData(color: _muted),
        unselectedLabelTextStyle: TextStyle(fontFamily: 'Tahoma', color: _muted),
      ),
      dividerTheme: const DividerThemeData(color: _border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceSoft,
        selectedColor: _black,
        labelStyle: const TextStyle(fontFamily: 'Tahoma', color: _black),
        secondaryLabelStyle: const TextStyle(fontFamily: 'Tahoma', color: _white),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(fontFamily: 'Tahoma', fontSize: 18, fontWeight: FontWeight.w700, color: _black),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _black,
        contentTextStyle: const TextStyle(fontFamily: 'Tahoma', color: _white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: _black, borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'Tahoma', color: _white, fontSize: 12),
      ),
    );
  }
}
