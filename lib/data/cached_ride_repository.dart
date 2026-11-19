import 'dart:convert';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/ride.dart';
import 'key_value_store.dart';
import 'ride_repository.dart';

/// The ride list plus where it came from.
class RideFeed {
  const RideFeed({required this.rides, required this.fromCache, this.syncedAt});

  final List<Ride> rides;

  /// True when the backend was unreachable and these are saved rides.
  final bool fromCache;

  /// When the rides were last fetched from the backend.
  final DateTime? syncedAt;
}

/// Offline-first wrapper: every successful read is saved on the device, and
/// when the backend can't be reached, reads fall back to the saved copy.
/// Writes need a connection and throw [OfflineException] without one.
class CachedRideRepository {
  CachedRideRepository({required this.remote, required this.store, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const ridesKey = 'cache.rides';
  static const syncedAtKey = 'cache.rides.syncedAt';
  static const messagesKeyPrefix = 'cache.messages.';

  final RideRepository remote;
  final KeyValueStore store;
  final DateTime Function() _clock;

  Future<RideFeed> loadFeed() async {
    try {
      final rides = await remote.fetchRides();
      final now = _clock();
      await store.setString(ridesKey, jsonEncode(rides.map((r) => r.toJson()).toList()));
      await store.setString(syncedAtKey, now.toIso8601String());
      return RideFeed(rides: rides, fromCache: false, syncedAt: now);
    } on OfflineException {
      final cached = _readCachedRides();
      if (cached == null) rethrow;
      final synced = store.getString(syncedAtKey);
      return RideFeed(
        rides: cached,
        fromCache: true,
        syncedAt: synced == null ? null : DateTime.tryParse(synced),
      );
    }
  }

  Future<List<ChatMessage>> loadMessages(String rideId) async {
    final key = '$messagesKeyPrefix$rideId';
    try {
      final messages = await remote.fetchMessages(rideId);
      await store.setString(key, jsonEncode(messages.map((m) => m.toJson()).toList()));
      return messages;
    } on OfflineException {
      final raw = store.getString(key);
      if (raw == null) rethrow;
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<Ride> createRide(Ride draft) => remote.createRide(draft);

  Future<Ride> joinRide(String rideId, AppUser user) => remote.joinRide(rideId, user);

  Future<Ride> leaveRide(String rideId, String userId) => remote.leaveRide(rideId, userId);

  Future<void> deleteRide(String rideId) async {
    await remote.deleteRide(rideId);
    await store.remove('$messagesKeyPrefix$rideId');
  }

  Future<ChatMessage> sendMessage(ChatMessage message) => remote.sendMessage(message);

  List<Ride>? _readCachedRides() {
    final raw = store.getString(ridesKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => Ride.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      return null;
    }
  }
}
