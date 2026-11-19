/// A departure reminder for a ride the user is driving or riding in.
class Reminder {
  const Reminder({
    required this.id,
    required this.rideId,
    required this.title,
    required this.body,
    required this.fireAt,
    this.delivered = false,
  });

  final String id;
  final String rideId;
  final String title;
  final String body;
  final DateTime fireAt;
  final bool delivered;

  Reminder copyWith({bool? delivered}) => Reminder(
        id: id,
        rideId: rideId,
        title: title,
        body: body,
        fireAt: fireAt,
        delivered: delivered ?? this.delivered,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'title': title,
        'body': body,
        'fireAt': fireAt.toIso8601String(),
        'delivered': delivered,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        rideId: json['rideId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        fireAt: DateTime.parse(json['fireAt'] as String),
        delivered: (json['delivered'] as bool?) ?? false,
      );
}
