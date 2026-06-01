import 'package:intl/intl.dart';

class Utils {
  static String formatMoney(double amount) {
    return NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('yyyy年MM月').format(date);
  }

  static String formatDay(DateTime date) {
    return DateFormat('MM-dd').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return formatDate(date);
  }

  static List<DateTime> getThisMonthRange() {
    final now = DateTime.now();
    return [DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0)];
  }

  static List<DateTime> getLastMonthRange() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return [lastMonth, DateTime(lastMonth.year, lastMonth.month + 1, 0)];
  }
}