import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raider_rides/core/theme.dart';
import 'package:raider_rides/models/ride.dart';
import 'package:raider_rides/ui/widgets/ride_card.dart';

void main() {
  final ride = Ride(
    id: 'r1',
    driverId: 'u_driver',
    driverName: 'Maya Patel',
    origin: 'Lubbock · TTU Rec Center',
    destination: 'Dallas (DFW Airport)',
    departure: DateTime(2026, 11, 20, 7, 30),
    totalSeats: 3,
    totalCost: 90,
    passengers: const {'u_luis': 'Luis Ortega'},
  );

  Future<void> pumpCard(WidgetTester tester, {String? userId, VoidCallback? onTap}) {
    return tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: RideCard(ride: ride, currentUserId: userId, onTap: onTap)),
    ));
  }

  testWidgets('RideCard shows route, time, driver and cost', (tester) async {
    await pumpCard(tester);
    expect(find.text('Dallas (DFW Airport)'), findsOneWidget);
    expect(find.text('from Lubbock · TTU Rec Center'), findsOneWidget);
    expect(find.text('Fri, Nov 20 · 7:30 AM'), findsOneWidget);
    expect(find.text('Driver: Maya Patel'), findsOneWidget);
    expect(find.text('\$22.50 each'), findsOneWidget); // 90 / (3 riders + driver)
    expect(find.text('2 open'), findsOneWidget);
  });

  testWidgets('RideCard labels rides you drive or joined', (tester) async {
    await pumpCard(tester, userId: 'u_driver');
    expect(find.text('Driving'), findsOneWidget);

    await pumpCard(tester, userId: 'u_luis');
    expect(find.text('Joined'), findsOneWidget);
  });

  testWidgets('RideCard is tappable', (tester) async {
    var tapped = false;
    await pumpCard(tester, onTap: () => tapped = true);
    await tester.tap(find.byType(RideCard));
    expect(tapped, isTrue);
  });
}
