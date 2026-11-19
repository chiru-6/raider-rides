/// A ride someone is offering. The driver splits [totalCost] evenly with
/// everyone in the car, themselves included.
class Ride {
  const Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.totalSeats,
    required this.totalCost,
    this.notes = '',
    this.passengers = const {},
  });

  final String id;
  final String driverId;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime departure;

  /// Seats offered to riders (the driver's seat is not counted).
  final int totalSeats;

  /// Total trip cost (gas, tolls, parking) to split.
  final double totalCost;
  final String notes;

  /// Riders who joined, keyed by user id, with their display names.
  final Map<String, String> passengers;

  int get seatsTaken => passengers.length;
  int get seatsLeft => totalSeats - seatsTaken;
  bool get isFull => seatsLeft <= 0;

  /// What each person pays right now (driver + current riders).
  double get currentSplit => totalCost / (seatsTaken + 1);

  /// What each person would pay if one more rider joined.
  double get splitIfOneMoreJoins => totalCost / (seatsTaken + 2);

  /// What each person pays once every seat is filled.
  double get splitWhenFull => totalCost / (totalSeats + 1);

  bool isDriver(String userId) => driverId == userId;
  bool isPassenger(String userId) => passengers.containsKey(userId);
  bool involves(String userId) => isDriver(userId) || isPassenger(userId);

  Ride copyWith({
    String? id,
    String? origin,
    String? destination,
    DateTime? departure,
    int? totalSeats,
    double? totalCost,
    String? notes,
    Map<String, String>? passengers,
  }) {
    return Ride(
      id: id ?? this.id,
      driverId: driverId,
      driverName: driverName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departure: departure ?? this.departure,
      totalSeats: totalSeats ?? this.totalSeats,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
      passengers: passengers ?? this.passengers,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverId': driverId,
        'driverName': driverName,
        'origin': origin,
        'destination': destination,
        'departure': departure.toIso8601String(),
        'totalSeats': totalSeats,
        'totalCost': totalCost,
        'notes': notes,
        'passengers': passengers,
      };

  factory Ride.fromJson(Map<String, dynamic> json) {
    final rawPassengers = (json['passengers'] as Map<String, dynamic>?) ?? const {};
    return Ride(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      departure: DateTime.parse(json['departure'] as String),
      totalSeats: (json['totalSeats'] as num).toInt(),
      totalCost: (json['totalCost'] as num).toDouble(),
      notes: (json['notes'] as String?) ?? '',
      passengers: rawPassengers.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

/// Returns the ride with [id], or null.
Ride? findRide(Iterable<Ride> rides, String id) {
  for (final ride in rides) {
    if (ride.id == id) return ride;
  }
  return null;
}
