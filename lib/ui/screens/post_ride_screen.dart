import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_format.dart';
import '../../core/validators.dart';
import '../../data/ride_repository.dart';
import '../../models/ride.dart';
import '../../state/auth_controller.dart';
import '../../state/reminder_controller.dart';
import '../../state/rides_controller.dart';

const popularDestinations = [
  'Dallas (DFW Airport)',
  'Austin',
  'Houston',
  'San Antonio',
  'Amarillo',
  'El Paso',
  'Lubbock Airport (LBB)',
];

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});

  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _origin = TextEditingController(text: 'Lubbock · Texas Tech campus');
  final _destination = TextEditingController();
  final _cost = TextEditingController(text: '60');
  final _notes = TextEditingController();

  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _seats = 3;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day + 1);
  }

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _departure => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  double get _costValue => double.tryParse(_cost.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 120)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!_departure.isAfter(DateTime.now())) {
      messenger.showSnackBar(const SnackBar(content: Text('Pick a departure time in the future.')));
      return;
    }
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final ride = await ref.read(ridesControllerProvider.notifier).createRide(Ride(
            id: '',
            driverId: user.id,
            driverName: user.name,
            origin: _origin.text.trim(),
            destination: _destination.text.trim(),
            departure: _departure,
            totalSeats: _seats,
            totalCost: _costValue,
            notes: _notes.text.trim(),
          ));
      await ref.read(reminderControllerProvider.notifier).scheduleFor(ride);
      messenger.showSnackBar(SnackBar(content: Text('Ride to ${ride.destination} posted.')));
      navigator.pop();
    } on OfflineException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on RideException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final split = _costValue / (_seats + 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Offer a ride')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _origin,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Pickup',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
              ),
              validator: (v) => validateRequired(v, 'a pickup spot'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destination,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => validateRequired(v, 'a destination'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final place in popularDestinations)
                  ActionChip(
                    label: Text(place),
                    onPressed: () => setState(() => _destination.text = place),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(formatDay(_date)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_seat_outlined),
                title: const Text('Seats for riders'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Fewer seats',
                      onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_seats', style: theme.textTheme.titleMedium),
                    IconButton(
                      tooltip: 'More seats',
                      onPressed: _seats < 6 ? () => setState(() => _seats++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Total trip cost (gas, tolls, parking)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: validateCost,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Split ${_seats + 1} ways when full: ${formatMoney(split)} per person, you included.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Luggage space, exact pickup spot, stops on the way…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.check),
              label: Text(_busy ? 'Posting…' : 'Post ride'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}
