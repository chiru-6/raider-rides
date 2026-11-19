import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_format.dart';
import '../../state/ride_filter.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rideFilterProvider);
    final controller = ref.read(rideFilterProvider.notifier);
    final date = filter.date;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: controller.setQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Where to? Try Dallas, Austin, airport…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              InputChip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text(date == null ? 'Any day' : formatDay(date)),
                selected: date != null,
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? now,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: now.add(const Duration(days: 120)),
                  );
                  if (picked != null) controller.setDate(picked);
                },
                onDeleted: date == null ? null : () => controller.setDate(null),
              ),
              ActionChip(
                avatar: const Icon(Icons.event_seat_outlined, size: 16),
                label: Text(filter.minSeats == 1 ? 'Any seats' : '${filter.minSeats}+ seats'),
                onPressed: controller.cycleSeats,
              ),
              FilterChip(
                label: const Text('My rides'),
                selected: filter.mineOnly,
                onSelected: (_) => controller.toggleMine(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
