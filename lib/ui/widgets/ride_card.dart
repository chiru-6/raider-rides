import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../models/ride.dart';
import 'seat_indicator.dart';

class RideCard extends StatelessWidget {
  const RideCard({super.key, required this.ride, required this.currentUserId, this.onTap});

  final Ride ride;
  final String? currentUserId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = _status(scheme);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ride.destination,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (status != null) ...[const SizedBox(width: 8), status],
                ],
              ),
              const SizedBox(height: 2),
              Text('from ${ride.origin}', style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              _IconLine(icon: Icons.schedule, text: formatDeparture(ride.departure)),
              const SizedBox(height: 4),
              _IconLine(icon: Icons.person_outline, text: 'Driver: ${ride.driverName}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  SeatIndicator(total: ride.totalSeats, taken: ride.seatsTaken),
                  const Spacer(),
                  Text(
                    '${formatMoney(ride.splitWhenFull)} each',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _status(ColorScheme scheme) {
    final uid = currentUserId;
    if (uid != null && ride.isDriver(uid)) {
      return StatusChip(label: 'Driving', background: scheme.primary, foreground: scheme.onPrimary);
    }
    if (uid != null && ride.isPassenger(uid)) {
      return StatusChip(label: 'Joined', background: scheme.tertiaryContainer, foreground: scheme.onTertiaryContainer);
    }
    if (ride.isFull) {
      return StatusChip(label: 'Full', background: scheme.surfaceContainerHighest, foreground: scheme.onSurfaceVariant);
    }
    if (ride.seatsLeft == 1) {
      return StatusChip(label: '1 seat left', background: scheme.errorContainer, foreground: scheme.onErrorContainer);
    }
    return null;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
