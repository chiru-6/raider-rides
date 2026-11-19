import '../models/chat_message.dart';
import '../models/ride.dart';

/// Fictional sample rides, always dated relative to [now] so the demo never
/// looks stale. Seeded drivers have ids starting with `seed_`.
class SeedData {
  const SeedData(this.rides, this.messages);

  final List<Ride> rides;
  final Map<String, List<ChatMessage>> messages;
}

SeedData buildSeed(DateTime now) {
  DateTime at(int daysFromToday, int hour, [int minute = 0]) =>
      DateTime(now.year, now.month, now.day + daysFromToday, hour, minute);

  final soon = now.add(const Duration(hours: 3));
  final soonRounded = DateTime(soon.year, soon.month, soon.day, soon.hour, (soon.minute ~/ 15) * 15);

  final rides = <Ride>[
    Ride(
      id: 'seed_r1',
      driverId: 'seed_maya',
      driverName: 'Maya Patel',
      origin: 'Lubbock · TTU Rec Center',
      destination: 'Dallas (DFW Airport)',
      departure: at(1, 7, 30),
      totalSeats: 3,
      totalCost: 90,
      notes: 'Two carry-ons per person. Meet at the Rec Center lot.',
      passengers: const {'seed_luis': 'Luis Ortega'},
    ),
    Ride(
      id: 'seed_r2',
      driverId: 'seed_jordan',
      driverName: 'Jordan Lee',
      origin: 'Lubbock · Texas Tech campus',
      destination: 'Austin',
      departure: at(2, 14),
      totalSeats: 4,
      totalCost: 120,
      notes: 'Heading down for the weekend. One gas stop in Abilene.',
    ),
    Ride(
      id: 'seed_r3',
      driverId: 'seed_sam',
      driverName: 'Sam Rivera',
      origin: 'Lubbock · Texas Tech campus',
      destination: 'Amarillo',
      departure: at(1, 17),
      totalSeats: 2,
      totalCost: 40,
      passengers: const {'seed_ava': 'Ava Nguyen', 'seed_noah': 'Noah Brooks'},
    ),
    Ride(
      id: 'seed_r4',
      driverId: 'seed_priya',
      driverName: 'Priya Shah',
      origin: 'Lubbock · Overton',
      destination: 'Houston',
      departure: at(4, 6),
      totalSeats: 3,
      totalCost: 150,
      notes: 'Thanksgiving break. Flexible on pickup near campus.',
      passengers: const {'seed_ben': 'Ben Carter'},
    ),
    Ride(
      id: 'seed_r5',
      driverId: 'seed_ethan',
      driverName: 'Ethan Brooks',
      origin: 'Lubbock · TTU Library',
      destination: 'Lubbock Airport (LBB)',
      departure: soonRounded,
      totalSeats: 2,
      totalCost: 15,
    ),
    Ride(
      id: 'seed_r6',
      driverId: 'seed_carmen',
      driverName: 'Carmen Diaz',
      origin: 'Lubbock · Texas Tech campus',
      destination: 'San Antonio',
      departure: at(6, 10),
      totalSeats: 3,
      totalCost: 130,
      notes: 'Room for a small cooler. No smoking.',
    ),
    Ride(
      id: 'seed_r7',
      driverId: 'seed_owen',
      driverName: 'Owen Kim',
      origin: 'Lubbock · Texas Tech campus',
      destination: 'El Paso',
      departure: at(9, 8),
      totalSeats: 2,
      totalCost: 110,
    ),
  ];

  final messages = <String, List<ChatMessage>>{
    'seed_r1': [
      ChatMessage(
        id: 'seed_m1',
        rideId: 'seed_r1',
        senderId: 'seed_luis',
        senderName: 'Luis Ortega',
        text: 'Is there room for a guitar case?',
        sentAt: now.subtract(const Duration(hours: 5)),
      ),
      ChatMessage(
        id: 'seed_m2',
        rideId: 'seed_r1',
        senderId: 'seed_maya',
        senderName: 'Maya Patel',
        text: "Yes, there's space in the trunk.",
        sentAt: now.subtract(const Duration(hours: 4, minutes: 40)),
      ),
    ],
  };

  return SeedData(rides, messages);
}

/// Replies seeded drivers send in demo mode so the chat feels alive.
const demoReplies = [
  'Sounds good! See you at pickup.',
  'Yep, that works for me.',
  "I'll message here if anything changes.",
  'Running about 5 min late, sorry!',
];
