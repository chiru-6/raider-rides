import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ride_repository.dart';
import '../../models/reminder.dart';
import '../../models/ride.dart';
import '../../state/auth_controller.dart';
import '../../state/reminder_controller.dart';
import '../../state/rides_controller.dart';
import '../widgets/filter_bar.dart';
import '../widgets/offline_banner.dart';
import '../widgets/ride_card.dart';
import 'post_ride_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'ride_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Reminder?>(deliveredReminderProvider, (previous, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${next.title}. ${next.body}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => Navigator.of(context).push(RideDetailScreen.route(next.rideId)),
          ),
        ),
      );
    });

    final user = ref.watch(authControllerProvider);
    final feed = ref.watch(ridesControllerProvider);
    final rides = ref.watch(visibleRidesProvider);
    final pending = ref.watch(reminderControllerProvider).where((r) => !r.delivered).length;
    final fromCache = feed.valueOrNull?.fromCache ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raider Rides', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Reminders',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RemindersScreen()),
            ),
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            icon: CircleAvatar(radius: 14, child: Text(user?.initials ?? '?', style: const TextStyle(fontSize: 12))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PostRideScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Offer a ride'),
      ),
      body: Column(
        children: [
          if (fromCache) OfflineBanner(syncedAt: feed.valueOrNull?.syncedAt),
          const FilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(ridesControllerProvider.notifier).refresh(),
              child: rides.when(
                data: (list) => list.isEmpty
                    ? const _MessageView(
                        icon: Icons.search_off,
                        title: 'No rides match',
                        body: 'Try another destination or day, or offer the ride yourself.',
                      )
                    : _RideList(rides: list, currentUserId: user?.id),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _MessageView(
                  icon: error is OfflineException ? Icons.cloud_off : Icons.error_outline,
                  title: error is OfflineException ? "You're offline" : 'Something went wrong',
                  body: error is OfflineException
                      ? 'Connect to the internet to load rides. Rides you load once stay available offline.'
                      : '$error',
                  actionLabel: 'Try again',
                  onAction: () => ref.read(ridesControllerProvider.notifier).refresh(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideList extends StatelessWidget {
  const _RideList({required this.rides, required this.currentUserId});

  final List<Ride> rides;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: rides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ride = rides[index];
        return RideCard(
          ride: ride,
          currentUserId: currentUserId,
          onTap: () => Navigator.of(context).push(RideDetailScreen.route(ride.id)),
        );
      },
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A ListView so pull-to-refresh still works on empty and error states.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
      children: [
        Icon(icon, size: 56, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          Center(child: OutlinedButton(onPressed: onAction, child: Text(actionLabel!))),
        ],
      ],
    );
  }
}
