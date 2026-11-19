import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/ride.dart';

/// The backend contract. [DemoRideRepository] implements it on the device;
/// a Firestore implementation can be dropped in without touching the UI.
abstract class RideRepository {
  Future<List<Ride>> fetchRides();
  Future<Ride> createRide(Ride draft);
  Future<Ride> joinRide(String rideId, AppUser user);
  Future<Ride> leaveRide(String rideId, String userId);
  Future<void> deleteRide(String rideId);
  Future<List<ChatMessage>> fetchMessages(String rideId);
  Future<ChatMessage> sendMessage(ChatMessage message);
}

/// Thrown when the backend can't be reached.
class OfflineException implements Exception {
  const OfflineException([this.message = "You're offline. Try again once you're connected."]);

  final String message;

  @override
  String toString() => 'OfflineException: $message';
}

/// Thrown when an action isn't allowed, such as joining a full ride.
class RideException implements Exception {
  const RideException(this.message);

  final String message;

  @override
  String toString() => 'RideException: $message';
}
