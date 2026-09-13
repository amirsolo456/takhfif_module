import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###');

  static String format(num? value) {
    if (value == null) return '0';
    return _formatter.format(value.round());
  }

  static double parse(String value) {
    final clean = _normalizeDigits(value).replaceAll(RegExp(r'\D'), '');
    return double.tryParse(clean) ?? 0;
  }

  static String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣۴٥٦٧٨٩';
    var result = value;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], i.toString());
      result = result.replaceAll(arabic[i], i.toString());
    }
    return result;
  }

  static TextInputFormatter get inputFormatter => _CurrencyInputFormatter();
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final normalized = CurrencyFormatter._normalizeDigits(newValue.text);
    final cleanText = normalized.replaceAll(RegExp(r'\D'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;

    final formatted = CurrencyFormatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
