import 'package:intl/intl.dart';

String formatChatTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final sameDay =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (sameDay) return DateFormat('HH:mm').format(date);
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days == 1) return 'Hier';
  if (days < 7) return DateFormat('EEE', 'fr_FR').format(date);
  return DateFormat('dd/MM').format(date);
}

String formatMessageTime(DateTime? date) =>
    date == null ? '' : DateFormat('HH:mm').format(date);

String formatDateLabel(DateTime? date) {
  if (date == null) return 'Aujourd’hui';
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Aujourd’hui';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day) {
    return 'Hier';
  }
  return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
}

String formatLastSeen(DateTime? date) {
  if (date == null) return 'vu récemment';
  final age = DateTime.now().difference(date);
  if (age.inMinutes < 2) return 'en ligne';
  return 'vu à ${DateFormat('HH:mm').format(date)}';
}
