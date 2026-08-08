import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###');

  static String format(num? value) {
    if (value == null) return '0';
    return _formatter.format(value);
  }

  static TextInputFormatter get inputFormatter => _CurrencyInputFormatter();
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String cleanText = newValue.text.replaceAll(',', '');
    final int? value = int.tryParse(cleanText);

    if (value == null) return oldValue;

    final String formatted = CurrencyFormatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
