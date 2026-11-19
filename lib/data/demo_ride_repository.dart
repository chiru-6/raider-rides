import 'dart:async';
import 'dart:convert';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/ride.dart';
import 'key_value_store.dart';
import 'ride_repository.dart';
import 'seed_data.dart';

/// A fake backend that runs on the device, so the app works with no
/// Firebase project. It adds network latency and can pretend to be offline
/// to show the cache in action.
class DemoRideRepository implements RideRepository {
  DemoRideRepository({
    required this.store,
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 350),
    this.autoReply = true,
  }) : _clock = clock ?? DateTime.now;

  static const _ridesKey = 'demo_server.rides';
  static const _messagesKey = 'demo_server.messages';

  final KeyValueStore store;
  final Duration latency;

  /// Seeded drivers answer chat messages after a short delay.
  final bool autoReply;
  final DateTime Function() _clock;

  /// When true, every call fails with [OfflineException].
  bool simulateOffline = false;

  List<Ride>? _rides;
  Map<String, List<ChatMessage>>? _messages;
  int _idCounter = 0;

  // ---------------------------------------------------------------- rides

  @override
  Future<List<Ride>> fetchRides() async {
    await _network();
    await _ensureLoaded();
    return List.unmodifiable(_rides!);
  }

  @override
  Future<Ride> createRide(Ride draft) async {
    await _network();
    await _ensureLoaded();
    if (!draft.departure.isAfter(_clock())) {
      throw const RideException('Pick a departure time in the future.');
    }
    if (draft.totalSeats < 1) {
      throw const RideException('Offer at least one seat.');
    }
    final ride = draft.id.isEmpty ? draft.copyWith(id: _newId('ride')) : draft;
    _rides!.add(ride);
    await _persist();
    return ride;
  }

  @override
  Future<Ride> joinRide(String rideId, AppUser user) async {
    await _network();
    await _ensureLoaded();
    final ride = _require(rideId);
    if (ride.isDriver(user.id)) throw const RideException("You're driving this ride.");
    if (ride.isPassenger(user.id)) return ride;
    if (ride.isFull) throw const RideException('Sorry, this ride just filled up.');
    if (!ride.departure.isAfter(_clock())) throw const RideException('This ride already left.');
    final updated = ride.copyWith(passengers: {...ride.passengers, user.id: user.name});
    _replace(updated);
    await _persist();
    return updated;
  }

  @override
  Future<Ride> leaveRide(String rideId, String userId) async {
    await _network();
    await _ensureLoaded();
    final ride = _require(rideId);
    final passengers = Map<String, String>.from(ride.passengers)..remove(userId);
    final updated = ride.copyWith(passengers: passengers);
    _replace(updated);
    await _persist();
    return updated;
  }

  @override
  Future<void> deleteRide(String rideId) async {
    await _network();
    await _ensureLoaded();
    _rides!.removeWhere((r) => r.id == rideId);
    _messages!.remove(rideId);
    await _persist();
  }

  // ----------------------------------------------------------------- chat

  @override
  Future<List<ChatMessage>> fetchMessages(String rideId) async {
    await _network();
    await _ensureLoaded();
    final list = [...?_messages![rideId]]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return list;
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    await _network();
    await _ensureLoaded();
    final ride = _require(message.rideId);
    final saved = message.id.isEmpty ? message.copyWith(id: _newId('msg')) : message;
    _messages!.putIfAbsent(message.rideId, () => []).add(saved);
    await _persist();

    final driverIsSeeded = ride.driverId.startsWith('seed_');
    if (autoReply && driverIsSeeded && message.senderId != ride.driverId) {
      unawaited(_replyLater(ride));
    }
    return saved;
  }

  // ----------------------------------------------------------- demo tools

  /// Restores the sample rides and clears everything users created.
  Future<void> resetDemo() async {
    final seed = buildSeed(_clock());
    _rides = [...seed.rides];
    _messages = {for (final e in seed.messages.entries) e.key: [...e.value]};
    await _persist();
  }

  // -------------------------------------------------------------- helpers

  Future<void> _network() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (simulateOffline) throw const OfflineException();
  }

  Future<void> _ensureLoaded() async {
    if (_rides != null) return;
    final raw = store.getString(_ridesKey);
    if (raw == null) {
      await resetDemo();
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _rides = decoded.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
      final rawMessages = store.getString(_messagesKey);
      final decodedMessages = rawMessages == null
          ? <String, dynamic>{}
          : jsonDecode(rawMessages) as Map<String, dynamic>;
      _messages = decodedMessages.map(
        (rideId, list) => MapEntry(
          rideId,
          (list as List<dynamic>)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
    } on Object {
      await resetDemo();
      return;
    }
    // Sample rides go stale after a week or so; refresh them if nothing is upcoming.
    final now = _clock();
    if (!_rides!.any((r) => r.departure.isAfter(now))) await resetDemo();
  }

  Future<void> _persist() async {
    await store.setString(_ridesKey, jsonEncode(_rides!.map((r) => r.toJson()).toList()));
    await store.setString(
      _messagesKey,
      jsonEncode(_messages!.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList()))),
    );
  }

  Ride _require(String rideId) {
    final ride = findRide(_rides!, rideId);
    if (ride == null) throw const RideException('This ride is no longer available.');
    return ride;
  }

  void _replace(Ride ride) {
    final index = _rides!.indexWhere((r) => r.id == ride.id);
    if (index >= 0) _rides![index] = ride;
  }

  String _newId(String prefix) => '${prefix}_${_clock().microsecondsSinceEpoch}_${_idCounter++}';

  Future<void> _replyLater(Ride ride) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final list = _messages?.putIfAbsent(ride.id, () => []);
    if (list == null || findRide(_rides!, ride.id) == null) return;
    list.add(ChatMessage(
      id: _newId('msg'),
      rideId: ride.id,
      senderId: ride.driverId,
      senderName: ride.driverName,
      text: demoReplies[list.length % demoReplies.length],
      sentAt: _clock(),
    ));
    await _persist();
  }
}
