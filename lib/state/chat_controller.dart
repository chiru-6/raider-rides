import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import 'auth_controller.dart';
import 'providers.dart';

/// Messages for one ride. The chat screen polls [refresh]; with Firestore
/// this becomes a live snapshot stream.
class ChatController extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String arg) => ref.watch(rideRepositoryProvider).loadMessages(arg);

  Future<void> refresh() async {
    final next = await AsyncValue.guard(() => ref.read(rideRepositoryProvider).loadMessages(arg));
    // Keep showing what we have if a background poll fails.
    if (next.hasValue || !state.hasValue) state = next;
  }

  Future<void> send(String text) async {
    final user = ref.read(authControllerProvider);
    final trimmed = text.trim();
    if (user == null || trimmed.isEmpty) return;
    await ref.read(rideRepositoryProvider).sendMessage(ChatMessage(
          id: '',
          rideId: arg,
          senderId: user.id,
          senderName: user.name,
          text: trimmed,
          sentAt: ref.read(clockProvider)(),
        ));
    await refresh();
  }
}

final chatControllerProvider =
    AsyncNotifierProvider.family<ChatController, List<ChatMessage>, String>(ChatController.new);
