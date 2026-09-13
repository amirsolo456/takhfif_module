import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MoneyFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'fa_IR');

  static String format(num? value) {
    if (value == null) return '۰';
    return _numberFormat.format(value.round());
  }

  static double parse(String value) {
    final normalized = _normalizeDigits(value)
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(normalized) ?? 0;
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
}

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = _normalizeDigits(newValue.text);
    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = MoneyFormatter.format(int.parse(digitsOnly));
    final rawCursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = _normalizeDigits(
      newValue.text.substring(0, rawCursor),
    ).replaceAll(RegExp(r'[^0-9]'), '').length;

    var cursor = 0;
    var seenDigits = 0;
    while (cursor < formatted.length && seenDigits < digitsBeforeCursor) {
      final code = formatted.codeUnitAt(cursor);
      final isPersianDigit = code >= 0x06F0 && code <= 0x06F9;
      final isAsciiDigit = code >= 0x30 && code <= 0x39;
      if (isPersianDigit || isAsciiDigit) seenDigits++;
      cursor++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], i.toString());
      result = result.replaceAll(arabic[i], i.toString());
    }

    return result;
  }
}
