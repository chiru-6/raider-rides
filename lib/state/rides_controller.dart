import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cached_ride_repository.dart';
import '../models/app_user.dart';
import '../models/ride.dart';
import 'auth_controller.dart';
import 'providers.dart';
import 'ride_filter.dart';

class RidesController extends AsyncNotifier<RideFeed> {
  CachedRideRepository get _repo => ref.read(rideRepositoryProvider);

  @override
  Future<RideFeed> build() => ref.watch(rideRepositoryProvider).loadFeed();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.loadFeed);
  }

  Future<Ride> createRide(Ride draft) async {
    final ride = await _repo.createRide(draft);
    await refresh();
    return ride;
  }

  Future<Ride> join(String rideId) async {
    final ride = await _repo.joinRide(rideId, _requireUser());
    await refresh();
    return ride;
  }

  Future<Ride> leave(String rideId) async {
    final ride = await _repo.leaveRide(rideId, _requireUser().id);
    await refresh();
    return ride;
  }

  Future<void> cancel(String rideId) async {
    await _repo.deleteRide(rideId);
    await refresh();
  }

  AppUser _requireUser() {
    final user = ref.read(authControllerProvider);
    if (user == null) throw StateError('Sign in first.');
    return user;
  }
}

final ridesControllerProvider = AsyncNotifierProvider<RidesController, RideFeed>(RidesController.new);

/// Upcoming rides after the search and filters are applied.
final visibleRidesProvider = Provider<AsyncValue<List<Ride>>>((ref) {
  final feed = ref.watch(ridesControllerProvider);
  final filter = ref.watch(rideFilterProvider);
  final user = ref.watch(authControllerProvider);
  final now = ref.watch(clockProvider)();
  return feed.whenData((f) => applyFilter(f.rides, filter, userId: user?.id, now: now));
});
