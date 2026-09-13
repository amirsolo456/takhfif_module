import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###');

  static String format(num? value) {
    if (value == null || value == 0) return '';
    return _formatter.format(value.round());
  }

  static double parse(String value) {
    final clean = _normalizeDigits(value).replaceAll(RegExp(r'\D'), '');
    return double.tryParse(clean) ?? 0;
  }

  static String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
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

    final rawCursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = CurrencyFormatter._normalizeDigits(
      newValue.text.substring(0, rawCursor),
    ).replaceAll(RegExp(r'\D'), '').length;

    var cursor = 0;
    var seenDigits = 0;
    while (cursor < formatted.length && seenDigits < digitsBeforeCursor) {
      final code = formatted.codeUnitAt(cursor);
      if (code >= 0x30 && code <= 0x39) {
        seenDigits++;
      }
      cursor++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
