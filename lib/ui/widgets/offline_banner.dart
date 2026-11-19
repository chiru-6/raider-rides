import 'package:flutter/material.dart';

import '../../core/date_format.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.syncedAt});

  final DateTime? syncedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final synced = syncedAt;
    final when = synced == null ? '' : ' from ${formatDay(synced)}, ${formatTime(synced)}';
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 20, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "You're offline. Showing rides saved$when.",
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
