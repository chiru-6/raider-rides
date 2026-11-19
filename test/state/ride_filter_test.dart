import 'package:flutter_test/flutter_test.dart';
import 'package:raider_rides/models/ride.dart';
import 'package:raider_rides/state/ride_filter.dart';

final now = DateTime(2026, 11, 19, 12);

Ride ride(String id, String destination, DateTime departure,
        {int seats = 3, Map<String, String> passengers = const {}, String driverId = 'u_other'}) =>
    Ride(
      id: id,
      driverId: driverId,
      driverName: 'Driver',
      origin: 'Lubbock',
      destination: destination,
      departure: departure,
      totalSeats: seats,
      totalCost: 60,
      passengers: passengers,
    );

void main() {
  final rides = [
    ride('austin', 'Austin', DateTime(2026, 11, 21, 9)),
    ride('dallas', 'Dallas (DFW Airport)', DateTime(2026, 11, 20, 7)),
    ride('past', 'Houston', DateTime(2026, 11, 18, 9)),
    ride('full', 'Amarillo', DateTime(2026, 11, 20, 17), seats: 1, passengers: {'u_x': 'X'}),
    ride('mine', 'El Paso', DateTime(2026, 11, 25, 8), driverId: 'u_me'),
    ride('joined-full', 'Abilene', DateTime(2026, 11, 22, 8), seats: 1, passengers: {'u_me': 'Me'}),
  ];

  List<String> ids(RideFilter filter) =>
      applyFilter(rides, filter, userId: 'u_me', now: now).map((r) => r.id).toList();

  test('hides past rides and full rides, sorted by departure', () {
    expect(ids(const RideFilter()), ['dallas', 'austin', 'joined-full', 'mine']);
  });

  test('searches origin and destination, ignoring case', () {
    expect(ids(const RideFilter(query: 'dfw')), ['dallas']);
    expect(ids(const RideFilter(query: 'LUBBOCK')), ['dallas', 'austin', 'joined-full', 'mine']);
  });

  test('filters by day', () {
    expect(ids(RideFilter(date: DateTime(2026, 11, 21))), ['austin']);
  });

  test('requires enough open seats, except for rides you are in', () {
    final filter = const RideFilter(minSeats: 3);
    expect(ids(filter), ['dallas', 'austin', 'joined-full', 'mine']);
    final many = rides.where((r) => r.id != 'mine').toList()
      ..add(ride('small', 'Waco', DateTime(2026, 11, 24, 8), seats: 2));
    final result = applyFilter(many, filter, userId: 'u_me', now: now).map((r) => r.id);
    expect(result, isNot(contains('small')));
  });

  test('"My rides" shows only rides you drive or joined', () {
    expect(ids(const RideFilter(mineOnly: true)), ['joined-full', 'mine']);
  });

  test('copyWith can clear the date', () {
    final filter = RideFilter(date: DateTime(2026, 11, 21), query: 'a');
    final cleared = filter.copyWith(clearDate: true);
    expect(cleared.date, isNull);
    expect(cleared.query, 'a');
    expect(const RideFilter().isActive, isFalse);
    expect(filter.isActive, isTrue);
  });
}
