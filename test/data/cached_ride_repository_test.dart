import 'package:flutter_test/flutter_test.dart';
import 'package:raider_rides/data/cached_ride_repository.dart';
import 'package:raider_rides/data/demo_ride_repository.dart';
import 'package:raider_rides/data/key_value_store.dart';
import 'package:raider_rides/data/ride_repository.dart';
import 'package:raider_rides/models/app_user.dart';
import 'package:raider_rides/models/chat_message.dart';
import 'package:raider_rides/models/ride.dart';

void main() {
  final now = DateTime(2026, 11, 19, 12);
  DateTime clock() => now;
  const me = AppUser(id: 'u_me', name: 'Me Raider', email: 'me@ttu.edu');

  late MemoryStore store;
  late DemoRideRepository backend;
  late CachedRideRepository repo;

  setUp(() {
    store = MemoryStore();
    backend = DemoRideRepository(store: store, clock: clock, latency: Duration.zero, autoReply: false);
    repo = CachedRideRepository(remote: backend, store: store, clock: clock);
  });

  test('loads seeded rides from the backend and caches them', () async {
    final feed = await repo.loadFeed();
    expect(feed.fromCache, isFalse);
    expect(feed.rides, isNotEmpty);
    expect(feed.syncedAt, now);
    expect(store.getString(CachedRideRepository.ridesKey), isNotNull);
  });

  test('falls back to cached rides when offline', () async {
    final online = await repo.loadFeed();
    backend.simulateOffline = true;
    final offline = await repo.loadFeed();
    expect(offline.fromCache, isTrue);
    expect(offline.syncedAt, now);
    expect(offline.rides.map((r) => r.id), online.rides.map((r) => r.id));
  });

  test('throws when offline with nothing cached', () async {
    backend.simulateOffline = true;
    expect(repo.loadFeed(), throwsA(isA<OfflineException>()));
  });

  test('writes need a connection', () async {
    backend.simulateOffline = true;
    expect(repo.joinRide('seed_r2', me), throwsA(isA<OfflineException>()));
  });

  test('joining takes a seat, leaving gives it back', () async {
    final joined = await repo.joinRide('seed_r2', me);
    expect(joined.isPassenger(me.id), isTrue);
    expect(joined.seatsLeft, joined.totalSeats - 1);

    final left = await repo.leaveRide('seed_r2', me.id);
    expect(left.isPassenger(me.id), isFalse);
  });

  test('cannot join a full ride', () async {
    // seed_r3 (Amarillo) is seeded with every seat taken.
    expect(repo.joinRide('seed_r3', me), throwsA(isA<RideException>()));
  });

  test('posted rides persist across backend restarts', () async {
    final ride = await repo.createRide(Ride(
      id: '',
      driverId: me.id,
      driverName: me.name,
      origin: 'Lubbock',
      destination: 'Waco',
      departure: now.add(const Duration(days: 2)),
      totalSeats: 2,
      totalCost: 80,
    ));
    expect(ride.id, isNotEmpty);

    final restarted = DemoRideRepository(store: store, clock: clock, latency: Duration.zero, autoReply: false);
    final rides = await restarted.fetchRides();
    expect(findRide(rides, ride.id)?.destination, 'Waco');
  });

  test('rejects rides in the past', () async {
    final draft = Ride(
      id: '',
      driverId: me.id,
      driverName: me.name,
      origin: 'Lubbock',
      destination: 'Waco',
      departure: now.subtract(const Duration(hours: 1)),
      totalSeats: 2,
      totalCost: 80,
    );
    expect(repo.createRide(draft), throwsA(isA<RideException>()));
  });

  test('chat messages are saved and readable offline', () async {
    await repo.sendMessage(ChatMessage(
      id: '',
      rideId: 'seed_r2',
      senderId: me.id,
      senderName: me.name,
      text: 'Room for a backpack?',
      sentAt: now,
    ));
    final online = await repo.loadMessages('seed_r2');
    expect(online.single.text, 'Room for a backpack?');

    backend.simulateOffline = true;
    final offline = await repo.loadMessages('seed_r2');
    expect(offline.single.text, 'Room for a backpack?');
  });

  test('cancelling a ride removes it', () async {
    await repo.deleteRide('seed_r2');
    final feed = await repo.loadFeed();
    expect(findRide(feed.rides, 'seed_r2'), isNull);
  });
}
