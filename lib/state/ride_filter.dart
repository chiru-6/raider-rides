import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_format.dart';
import '../models/ride.dart';

class RideFilter {
  const RideFilter({this.query = '', this.date, this.minSeats = 1, this.mineOnly = false});

  /// Matches the origin or destination.
  final String query;

  /// Only rides leaving on this day.
  final DateTime? date;

  /// Open seats needed. Rides the user is already in always show.
  final int minSeats;

  /// Only rides the user drives or joined.
  final bool mineOnly;

  bool get isActive => query.isNotEmpty || date != null || minSeats > 1 || mineOnly;

  RideFilter copyWith({String? query, DateTime? date, bool clearDate = false, int? minSeats, bool? mineOnly}) {
    return RideFilter(
      query: query ?? this.query,
      date: clearDate ? null : (date ?? this.date),
      minSeats: minSeats ?? this.minSeats,
      mineOnly: mineOnly ?? this.mineOnly,
    );
  }
}

/// Pure filtering logic, kept outside the widgets so it's easy to test.
/// Past rides are hidden; results are sorted by departure time.
List<Ride> applyFilter(List<Ride> rides, RideFilter filter, {required String? userId, required DateTime now}) {
  final query = filter.query.trim().toLowerCase();
  final result = rides.where((ride) {
    if (!ride.departure.isAfter(now)) return false;
    if (query.isNotEmpty &&
        !ride.destination.toLowerCase().contains(query) &&
        !ride.origin.toLowerCase().contains(query)) {
      return false;
    }
    final date = filter.date;
    if (date != null && !isSameDay(ride.departure, date)) return false;
    final mine = userId != null && ride.involves(userId);
    if (filter.mineOnly && !mine) return false;
    if (!mine && ride.seatsLeft < filter.minSeats) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.departure.compareTo(b.departure));
  return result;
}

class RideFilterController extends Notifier<RideFilter> {
  @override
  RideFilter build() => const RideFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setDate(DateTime? date) =>
      state = date == null ? state.copyWith(clearDate: true) : state.copyWith(date: date);

  /// 1 → 2 → 3 → 1 seats.
  void cycleSeats() => state = state.copyWith(minSeats: state.minSeats >= 3 ? 1 : state.minSeats + 1);

  void toggleMine() => state = state.copyWith(mineOnly: !state.mineOnly);

  void clear() => state = const RideFilter();
}

final rideFilterProvider = NotifierProvider<RideFilterController, RideFilter>(RideFilterController.new);
