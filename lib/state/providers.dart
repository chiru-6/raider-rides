import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cached_ride_repository.dart';
import '../data/demo_ride_repository.dart';
import '../data/key_value_store.dart';
import 'rides_controller.dart';

/// Overridden in `main()` with SharedPreferences, and in tests with [MemoryStore].
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError('Override keyValueStoreProvider in main()'),
);

/// Injectable clock so tests can control "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The on-device demo backend. Swap this for a Firestore repository to go live.
final demoBackendProvider = Provider<DemoRideRepository>((ref) {
  return DemoRideRepository(
    store: ref.watch(keyValueStoreProvider),
    clock: ref.watch(clockProvider),
  );
});

final rideRepositoryProvider = Provider<CachedRideRepository>((ref) {
  return CachedRideRepository(
    remote: ref.watch(demoBackendProvider),
    store: ref.watch(keyValueStoreProvider),
    clock: ref.watch(clockProvider),
  );
});

/// "Simulate offline mode" switch on the profile screen.
class OfflineModeController extends Notifier<bool> {
  @override
  bool build() => ref.read(demoBackendProvider).simulateOffline;

  Future<void> setOffline(bool offline) async {
    ref.read(demoBackendProvider).simulateOffline = offline;
    state = offline;
    await ref.read(ridesControllerProvider.notifier).refresh();
  }
}

final offlineModeProvider = NotifierProvider<OfflineModeController, bool>(OfflineModeController.new);
