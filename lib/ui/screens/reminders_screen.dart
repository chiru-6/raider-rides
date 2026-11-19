import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_format.dart';
import '../../state/reminder_controller.dart';
import 'ride_detail_screen.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderControllerProvider);
    final upcoming = reminders.where((r) => !r.delivered).toList();
    final sent = reminders.where((r) => r.delivered).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: reminders.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "Join or post a ride and we'll remind you an hour before it leaves.",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: [
                if (upcoming.isNotEmpty) const _Header('Upcoming'),
                for (final r in upcoming)
                  ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(r.title),
                    subtitle: Text('${formatDay(r.fireAt)}, ${formatTime(r.fireAt)} · ${r.body}'),
                    onTap: () => Navigator.of(context).push(RideDetailScreen.route(r.rideId)),
                  ),
                if (sent.isNotEmpty) const _Header('Sent'),
                for (final r in sent)
                  ListTile(
                    leading: const Icon(Icons.alarm_on),
                    title: Text(r.title),
                    subtitle: Text('${formatDay(r.fireAt)}, ${formatTime(r.fireAt)}'),
                    onTap: () => Navigator.of(context).push(RideDetailScreen.route(r.rideId)),
                  ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
