import 'package:flutter/material.dart';
import '../config/api_settings.dart';
import '../../shared/utils/iran_format.dart';

class CurrencyHelper {
  static CurrencyUnit get activeUnit => ApiSettings.current.currencyUnit;

  static String get unitSymbol => ApiSettings.current.currencyUnitLabel;

  /// Formats a raw amount (stored in Rials in database/API) for display according to active currency unit.
  static String format(num? rawAmountInRials, {bool showSymbol = true}) {
    if (rawAmountInRials == null) return showSymbol ? '۰ $unitSymbol' : '۰';
    final displayValue = activeUnit == CurrencyUnit.toman
        ? (rawAmountInRials / 10)
        : rawAmountInRials;
    final formatted = IranFormat.number(displayValue);
    return showSymbol ? '$formatted $unitSymbol' : formatted;
  }

  /// Formats a raw amount for display without any currency symbol.
  static String formatNumber(num? rawAmountInRials) {
    return format(rawAmountInRials, showSymbol: false);
  }

  /// Converts a user input value (entered in active unit) to raw Rials for API/database payload.
  static double toRawRials(num inputAmount) {
    return activeUnit == CurrencyUnit.toman ? (inputAmount * 10).toDouble() : inputAmount.toDouble();
  }

  /// Converts a raw Rial amount from API/database to the value displayed in input field for editing.
  static double fromRawRials(num rawRials) {
    return activeUnit == CurrencyUnit.toman ? (rawRials / 10).toDouble() : rawRials.toDouble();
  }
}
