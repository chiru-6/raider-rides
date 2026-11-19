import 'package:flutter_test/flutter_test.dart';
import 'package:raider_rides/core/date_format.dart';

void main() {
  test('formatTime uses a 12-hour clock', () {
    expect(formatTime(DateTime(2026, 11, 20, 7, 5)), '7:05 AM');
    expect(formatTime(DateTime(2026, 11, 20, 0, 0)), '12:00 AM');
    expect(formatTime(DateTime(2026, 11, 20, 12, 30)), '12:30 PM');
    expect(formatTime(DateTime(2026, 11, 20, 23, 59)), '11:59 PM');
  });

  test('formatDeparture shows weekday, date and time', () {
    // November 20, 2026 is a Friday.
    expect(formatDeparture(DateTime(2026, 11, 20, 7, 30)), 'Fri, Nov 20 · 7:30 AM');
  });

  test('formatRelative counts down to departure', () {
    final now = DateTime(2026, 11, 19, 12);
    expect(formatRelative(DateTime(2026, 11, 19, 12, 45), now), 'in 45 min');
    expect(formatRelative(DateTime(2026, 11, 19, 15), now), 'in 3 h');
    expect(formatRelative(DateTime(2026, 11, 20, 13), now), 'tomorrow');
    expect(formatRelative(DateTime(2026, 11, 23, 9), now), 'in 4 days');
    expect(formatRelative(DateTime(2026, 11, 19, 11), now), 'departed');
  });

  test('formatMoney uses two decimals', () {
    expect(formatMoney(30), '\$30.00');
    expect(formatMoney(12.5), '\$12.50');
  });
}
