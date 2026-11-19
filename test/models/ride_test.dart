import 'package:flutter_test/flutter_test.dart';
import 'package:raider_rides/models/ride.dart';

Ride sampleRide({Map<String, String> passengers = const {}}) => Ride(
      id: 'r1',
      driverId: 'u_driver',
      driverName: 'Dana Driver',
      origin: 'Lubbock',
      destination: 'Austin',
      departure: DateTime(2026, 11, 21, 9),
      totalSeats: 3,
      totalCost: 120,
      notes: 'One stop',
      passengers: passengers,
    );

void main() {
  group('Ride', () {
    test('counts seats and splits cost with the driver included', () {
      final ride = sampleRide(passengers: {'u_a': 'Ann'});
      expect(ride.seatsTaken, 1);
      expect(ride.seatsLeft, 2);
      expect(ride.isFull, isFalse);
      expect(ride.currentSplit, 60); // 120 / (1 rider + driver)
      expect(ride.splitIfOneMoreJoins, 40); // 120 / 3
      expect(ride.splitWhenFull, 30); // 120 / (3 riders + driver)
    });

    test('is full when every seat is taken', () {
      final ride = sampleRide(passengers: {'u_a': 'Ann', 'u_b': 'Bo', 'u_c': 'Cy'});
      expect(ride.isFull, isTrue);
      expect(ride.seatsLeft, 0);
    });

    test('knows who is involved', () {
      final ride = sampleRide(passengers: {'u_a': 'Ann'});
      expect(ride.isDriver('u_driver'), isTrue);
      expect(ride.isPassenger('u_a'), isTrue);
      expect(ride.involves('u_a'), isTrue);
      expect(ride.involves('u_stranger'), isFalse);
    });

    test('survives a JSON round trip', () {
      final ride = sampleRide(passengers: {'u_a': 'Ann'});
      final copy = Ride.fromJson(ride.toJson());
      expect(copy.id, ride.id);
      expect(copy.destination, 'Austin');
      expect(copy.departure, ride.departure);
      expect(copy.totalCost, 120);
      expect(copy.notes, 'One stop');
      expect(copy.passengers, {'u_a': 'Ann'});
    });

    test('findRide returns null for unknown ids', () {
      final rides = [sampleRide()];
      expect(findRide(rides, 'r1')?.destination, 'Austin');
      expect(findRide(rides, 'nope'), isNull);
    });
  });
}
