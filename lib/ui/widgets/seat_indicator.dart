import 'package:flutter/material.dart';

/// Filled seats for riders who joined, outlined seats for open ones.
class SeatIndicator extends StatelessWidget {
  const SeatIndicator({super.key, required this.total, required this.taken});

  final int total;
  final int taken;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = (total - taken).clamp(0, total);
    return Semantics(
      label: '$left of $total seats open',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Icon(
              i < taken ? Icons.event_seat : Icons.event_seat_outlined,
              size: 18,
              color: i < taken ? scheme.outline : scheme.primary,
            ),
          const SizedBox(width: 6),
          Text(
            left == 0 ? 'Full' : '$left open',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
