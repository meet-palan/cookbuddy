import 'package:intl/intl.dart';

class DateTimeHelper {
  static String formatDate(DateTime date) {
    return DateFormat("dd MMM yyyy").format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat("hh:mm a").format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime);
  }
}
