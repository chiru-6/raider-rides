import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'providers.dart';

/// Demo sign-in with a TTU email, saved on the device.
/// Replace with Firebase Auth email-link sign-in for production.
class AuthController extends Notifier<AppUser?> {
  static const _key = 'auth.user';

  @override
  AppUser? build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> signIn({required String name, required String email}) async {
    final user = AppUser.fromEmail(name: name, email: email);
    await ref.read(keyValueStoreProvider).setString(_key, jsonEncode(user.toJson()));
    state = user;
  }

  Future<void> signOut() async {
    await ref.read(keyValueStoreProvider).remove(_key);
    state = null;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AppUser?>(AuthController.new);
