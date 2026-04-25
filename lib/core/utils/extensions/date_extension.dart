import 'package:intl/intl.dart';

extension DateExtension on DateTime {
  String get formatted => DateFormat('dd MMM yyyy').format(this);
  String get formattedWithTime =>
      DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get timeOnly => DateFormat('hh:mm a').format(this);
  String get apiFormat => DateFormat('yyyy-MM-dd').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isPast {
    final now = DateTime.now();
    return isBefore(DateTime(now.year, now.month, now.day));
  }
}
