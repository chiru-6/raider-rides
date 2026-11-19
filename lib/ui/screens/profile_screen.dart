import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_controller.dart';
import '../../state/providers.dart';
import '../../state/reminder_controller.dart';
import '../../state/rides_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _resetDemo(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text('This restores the sample rides and removes rides, messages and reminders you created.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(demoBackendProvider).resetDemo();
    await ref.read(reminderControllerProvider.notifier).clearAll();
    await ref.read(ridesControllerProvider.notifier).refresh();
    messenger.showSnackBar(const SnackBar(content: Text('Demo data reset.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final offline = ref.watch(offlineModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(user?.initials ?? '?', style: theme.textTheme.headlineSmall),
            ),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          Text(user?.email ?? '', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_off),
            title: const Text('Simulate offline mode'),
            subtitle: const Text('Cuts the demo backend off so you can see saved rides load with no connection.'),
            value: offline,
            onChanged: (value) => ref.read(offlineModeProvider.notifier).setOffline(value),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset demo data'),
            onTap: () => _resetDemo(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Raider Rides 1.0'),
            subtitle: Text('A student project. Not affiliated with Texas Tech University.'),
          ),
        ],
      ),
    );
  }
}
