import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'state/auth_controller.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/sign_in_screen.dart';

class RaiderRidesApp extends ConsumerWidget {
  const RaiderRidesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authControllerProvider.select((user) => user != null));
    return MaterialApp(
      title: 'Raider Rides',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: signedIn ? const HomeScreen() : const SignInScreen(),
    );
  }
}
