import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

class IranFormat {
  // Format with an explicit Latin grouping pattern, then localize digits and
  // use the Persian thousands separator. This avoids locale/font-dependent
  // grouping issues for values such as 1,920,000,000.
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.###', 'en_US');


  static String number(num? value) {
    if (value == null) return '\u202A۰\u202C';
    final isNegative = value < 0;
    final formatted = _numberFormat.format(value.abs().round());
    final localized = digits(formatted);
    final result = isNegative ? '-$localized' : localized;
    return '\u202A$result\u202C';
  }

  static String decimal(num? value) {
    if (value == null) return '\u202A۰\u202C';
    final isNegative = value < 0;
    final formatted = _decimalFormat.format(value.abs());
    final localized = digits(formatted);
    final result = isNegative ? '-$localized' : localized;
    return '\u202A$result\u202C';
  }

  static String digits(Object? value) {
    const latin = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var text = value?.toString() ?? '';
    for (var i = 0; i < latin.length; i++) {
      text = text.replaceAll(latin[i], persian[i]);
    }
    return text;
  }

  static double? parseNumber(String value) {
    var text = value.trim();
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(persian[i], i.toString());
      text = text.replaceAll(arabic[i], i.toString());
    }
    text = text.replaceAll(',', '').replaceAll('٬', '').replaceAll(' ', '');
    return double.tryParse(text);
  }

  static String date(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final input = raw.trim();

    // Already Jalali: keep the calendar and only localize the digits.
    final jalaliMatch = RegExp(r'^(13|14)\d{2}[-/]\d{1,2}[-/]\d{1,2}').firstMatch(input);
    if (jalaliMatch != null) {
      return digits(input.replaceAll('-', '/'));
    }

    final normalized = input.replaceFirst(' ', 'T').replaceAll('/', '-');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return digits(input.replaceAll('-', '/'));

    final jalali = Jalali.fromDateTime(parsed);
    final result = '${jalali.year.toString().padLeft(4, '0')}/'
        '${jalali.month.toString().padLeft(2, '0')}/'
        '${jalali.day.toString().padLeft(2, '0')}';
    return digits(result);
  }

  static String dateTime(DateTime value) {
    final jalali = Jalali.fromDateTime(value);
    final result = '${jalali.year.toString().padLeft(4, '0')}/'
        '${jalali.month.toString().padLeft(2, '0')}/'
        '${jalali.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return digits(result);
  }
}
