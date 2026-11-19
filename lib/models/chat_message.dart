class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String rideId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  ChatMessage copyWith({String? id}) => ChatMessage(
        id: id ?? this.id,
        rideId: rideId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        sentAt: sentAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        rideId: json['rideId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}
