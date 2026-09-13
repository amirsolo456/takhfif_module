import 'dart:async';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  late bool _isDark;
  bool? _manualOverride;
  Timer? _timer;

  ThemeController() {
    _isDark = isNightInTehran();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_manualOverride == null) {
        final night = isNightInTehran();
        if (night != _isDark) {
          _isDark = night;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get isDark => _manualOverride ?? _isDark;

  static bool isNightInTehran() {
    final utc = DateTime.now().toUtc();
    final tehranNow = utc.add(const Duration(hours: 3, minutes: 30));
    return tehranNow.hour >= 18 || tehranNow.hour < 6;
  }

  void toggleTheme() {
    _manualOverride = !isDark;
    notifyListeners();
  }
}
