/// Small date helpers so the app doesn't need the `intl` package.
library;

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `7:05 AM`, `12:30 PM`.
String formatTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// `Fri, Nov 20`.
String formatDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

/// `Fri, Nov 20 · 7:30 AM`.
String formatDeparture(DateTime d) => '${formatDay(d)} · ${formatTime(d)}';

/// Human countdown such as `in 45 min`, `in 3 h`, `tomorrow`, `in 4 days`.
String formatRelative(DateTime target, DateTime now) {
  final diff = target.difference(now);
  if (diff.isNegative) return 'departed';
  if (diff.inMinutes < 60) return 'in ${diff.inMinutes.clamp(1, 59)} min';
  if (diff.inHours < 24) return 'in ${diff.inHours} h';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(target.year, target.month, target.day);
  final days = day.difference(today).inHours ~/ 24;
  if (days <= 1) return 'tomorrow';
  return 'in $days days';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// `$12.50`.
String formatMoney(double value) => '\$${value.toStringAsFixed(2)}';
