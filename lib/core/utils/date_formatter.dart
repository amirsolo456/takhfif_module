import 'package:shamsi_date/shamsi_date.dart';
import 'package:intl/intl.dart';

class AppDateFormatter {
  static String toPersian(DateTime date) {
    final Jalali j = Jalali.fromDateTime(date);
    final f = j.formatter;
    return '${f.yyyy}/${f.mm}/${f.dd}';
  }

  static String toPersianWithTime(DateTime date) {
    final Jalali j = Jalali.fromDateTime(date);
    final f = j.formatter;
    final time = DateFormat('HH:mm').format(date);
    return '${f.yyyy}/${f.mm}/${f.dd} - $time';
  }
}
