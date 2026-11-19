import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_format.dart';
import '../models/reminder.dart';
import '../models/ride.dart';
import 'providers.dart';

/// The most recent reminder that came due. The home screen listens to this
/// and shows it as a notification banner.
final deliveredReminderProvider = StateProvider<Reminder?>((ref) => null);

/// Departure reminders, saved on the device and checked every 15 seconds
/// while the app is open. With Firebase, the same reminders would be sent as
/// push notifications by Cloud Messaging.
class ReminderController extends Notifier<List<Reminder>> {
  static const _key = 'reminders';
  static const leadTime = Duration(hours: 1);

  Timer? _timer;

  @override
  List<Reminder> build() {
    final store = ref.watch(keyValueStoreProvider);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => checkDue());
    ref.onDispose(() => _timer?.cancel());

    final raw = store.getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      return const [];
    }
  }

  int get pendingCount => state.where((r) => !r.delivered).length;

  /// Reminds the user an hour before [ride] leaves (or shortly, if it leaves sooner).
  Future<void> scheduleFor(Ride ride) async {
    final now = ref.read(clockProvider)();
    var fireAt = ride.departure.subtract(leadTime);
    if (fireAt.isBefore(now)) fireAt = now.add(const Duration(seconds: 10));
    final reminder = Reminder(
      id: 'rem_${ride.id}',
      rideId: ride.id,
      title: 'Your ride to ${ride.destination} leaves soon',
      body: 'Departs ${formatTime(ride.departure)} from ${ride.origin}.',
      fireAt: fireAt,
    );
    state = [...state.where((r) => r.rideId != ride.id), reminder]
      ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    await _save();
  }

  Future<void> cancelFor(String rideId) async {
    state = state.where((r) => r.rideId != rideId).toList();
    await _save();
  }

  Future<void> clearAll() async {
    state = const [];
    await _save();
  }

  /// Marks due reminders as delivered and announces them.
  Future<void> checkDue() async {
    final now = ref.read(clockProvider)();
    final due = state.where((r) => !r.delivered && !r.fireAt.isAfter(now)).toList();
    if (due.isEmpty) return;
    final dueIds = due.map((r) => r.id).toSet();
    state = [for (final r in state) dueIds.contains(r.id) ? r.copyWith(delivered: true) : r];
    await _save();
    for (final reminder in due) {
      ref.read(deliveredReminderProvider.notifier).state = reminder;
    }
  }

  Future<void> _save() =>
      ref.read(keyValueStoreProvider).setString(_key, jsonEncode(state.map((r) => r.toJson()).toList()));
}

final reminderControllerProvider =
    NotifierProvider<ReminderController, List<Reminder>>(ReminderController.new);
