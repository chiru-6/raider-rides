import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_format.dart';
import '../../data/ride_repository.dart';
import '../../models/reminder.dart';
import '../../models/ride.dart';
import '../../state/auth_controller.dart';
import '../../state/reminder_controller.dart';
import '../../state/rides_controller.dart';
import '../widgets/seat_indicator.dart';
import 'chat_screen.dart';

class RideDetailScreen extends ConsumerStatefulWidget {
  const RideDetailScreen({super.key, required this.rideId});

  final String rideId;

  static Route<void> route(String rideId) =>
      MaterialPageRoute<void>(builder: (_) => RideDetailScreen(rideId: rideId));

  @override
  ConsumerState<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends ConsumerState<RideDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } on OfflineException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on RideException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() => _run(() async {
        final ride = await ref.read(ridesControllerProvider.notifier).join(widget.rideId);
        await ref.read(reminderControllerProvider.notifier).scheduleFor(ride);
      }, "You're in! We'll remind you an hour before departure.");

  Future<void> _leave() => _run(() async {
        await ref.read(ridesControllerProvider.notifier).leave(widget.rideId);
        await ref.read(reminderControllerProvider.notifier).cancelFor(widget.rideId);
      }, 'You left this ride.');

  Future<void> _cancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: const Text('Riders who joined will lose their seats. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep ride')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel ride')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    var cancelled = false;
    await _run(() async {
      await ref.read(ridesControllerProvider.notifier).cancel(widget.rideId);
      await ref.read(reminderControllerProvider.notifier).cancelFor(widget.rideId);
      cancelled = true;
    }, 'Ride cancelled.');
    if (cancelled && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(ridesControllerProvider);
    final user = ref.watch(authControllerProvider);
    final reminders = ref.watch(reminderControllerProvider);
    final rides = feed.valueOrNull?.rides;
    final ride = rides == null ? null : findRide(rides, widget.rideId);

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: feed.isLoading
              ? const CircularProgressIndicator()
              : const Text('This ride is no longer available.'),
        ),
      );
    }

    final uid = user?.id ?? '';
    final theme = Theme.of(context);
    final now = DateTime.now();
    Reminder? reminder;
    for (final r in reminders) {
      if (r.rideId == ride.id) reminder = r;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(ride.destination, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${formatDeparture(ride.departure)} · ${formatRelative(ride.departure, now)}',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _InfoTile(icon: Icons.trip_origin, label: 'Pickup', value: ride.origin),
                _InfoTile(icon: Icons.place_outlined, label: 'Drop-off', value: ride.destination),
                _InfoTile(icon: Icons.person_outline, label: 'Driver', value: ride.driverName),
                ListTile(
                  leading: const Icon(Icons.event_seat_outlined),
                  title: const Text('Seats'),
                  subtitle: Align(
                    alignment: Alignment.centerLeft,
                    child: SeatIndicator(total: ride.totalSeats, taken: ride.seatsTaken),
                  ),
                ),
                _InfoTile(
                  icon: Icons.payments_outlined,
                  label: 'Cost split',
                  value: '${formatMoney(ride.currentSplit)} each right now '
                      '(${ride.seatsTaken + 1} ${ride.seatsTaken == 0 ? 'person' : 'people'}). '
                      'Drops to ${formatMoney(ride.splitWhenFull)} when full. '
                      'Total trip cost ${formatMoney(ride.totalCost)}.',
                ),
                if (ride.notes.isNotEmpty)
                  _InfoTile(icon: Icons.sticky_note_2_outlined, label: 'Notes', value: ride.notes),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Riders', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (ride.passengers.isEmpty)
            Text('No riders yet. Be the first!', style: theme.textTheme.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in ride.passengers.entries)
                  Chip(
                    avatar: const Icon(Icons.person, size: 18),
                    label: Text(entry.key == uid ? '${entry.value} (you)' : entry.value),
                  ),
              ],
            ),
          if (ride.involves(uid)) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(reminder?.delivered ?? false ? Icons.alarm_on : Icons.alarm),
                title: const Text('Departure reminder'),
                subtitle: Text(
                  reminder == null
                      ? 'No reminder set'
                      : reminder.delivered
                          ? 'Sent ${formatDay(reminder.fireAt)}, ${formatTime(reminder.fireAt)}'
                          : 'Scheduled for ${formatDay(reminder.fireAt)}, ${formatTime(reminder.fireAt)}',
                ),
                trailing: reminder == null
                    ? TextButton(
                        onPressed: () => ref.read(reminderControllerProvider.notifier).scheduleFor(ride),
                        child: const Text('Remind me'),
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(ChatScreen.route(ride)),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _primaryAction(ride, uid)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryAction(Ride ride, String uid) {
    final style = FilledButton.styleFrom(minimumSize: const Size.fromHeight(48));
    if (ride.isDriver(uid)) {
      return FilledButton.tonal(
        onPressed: _busy ? null : _cancelRide,
        style: style,
        child: const Text('Cancel ride'),
      );
    }
    if (ride.isPassenger(uid)) {
      return FilledButton.tonal(
        onPressed: _busy ? null : _leave,
        style: style,
        child: const Text('Leave ride'),
      );
    }
    return FilledButton(
      onPressed: _busy || ride.isFull ? null : _join,
      style: style,
      child: Text(ride.isFull ? 'Ride is full' : 'Join · ${formatMoney(ride.splitIfOneMoreJoins)}'),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value));
  }
}
