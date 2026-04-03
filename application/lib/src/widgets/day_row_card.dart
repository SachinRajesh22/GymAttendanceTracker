import 'package:flutter/material.dart';

import '../constants/tracker_constants.dart';
import '../controller/tracker_controller.dart';
import '../models/day_entry.dart';

class DayRowCard extends StatefulWidget {
  const DayRowCard({
    super.key,
    required this.date,
    required this.entry,
    required this.effectiveStatus,
    required this.controller,
  });

  final DateTime date;
  final DayEntry entry;
  final String effectiveStatus;
  final TrackerController controller;

  @override
  State<DayRowCard> createState() => _DayRowCardState();
}

class _DayRowCardState extends State<DayRowCard> {
  late final TextEditingController proteinController;

  @override
  void initState() {
    super.initState();
    proteinController = TextEditingController(text: widget.entry.proteinText);
  }

  @override
  void didUpdateWidget(covariant DayRowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.proteinText != widget.entry.proteinText) {
      proteinController.text = widget.entry.proteinText;
    }
  }

  @override
  void dispose() {
    proteinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _statusColors(widget.effectiveStatus);

    return Card(
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.date.day}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _weekdayLabel(widget.date.weekday),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => widget.controller.updateHoliday(widget.date),
                  child: const Text('Holiday'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          widget.entry.status == 'present' ? const Color(0xFF218652) : Colors.white,
                      foregroundColor:
                          widget.entry.status == 'present' ? Colors.white : const Color(0xFF1F1B18),
                    ),
                    onPressed: () => widget.controller.updateStatus(widget.date, 'present'),
                    child: const Text('Present'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          widget.entry.status == 'absent' ? const Color(0xFFC94D44) : Colors.white,
                      foregroundColor:
                          widget.entry.status == 'absent' ? Colors.white : const Color(0xFF1F1B18),
                    ),
                    onPressed: () => widget.controller.updateStatus(widget.date, 'absent'),
                    child: const Text('Absent'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: proteinController,
              decoration: const InputDecoration(
                labelText: 'Protein',
                hintText: '120g',
              ),
              onChanged: (value) => widget.controller.updateProtein(widget.date, value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.entry.workoutType.isEmpty ? null : widget.entry.workoutType,
              decoration: const InputDecoration(labelText: 'Workout'),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Select workout'),
                ),
                ..._workoutItems(widget.controller),
              ],
              onChanged: (value) => widget.controller.updateWorkout(widget.date, value ?? ''),
            ),
            const SizedBox(height: 10),
            Text(
              _statusLabel(widget.effectiveStatus),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _workoutItems(TrackerController controller) {
    return workoutOptions
        .map(
          (value) => DropdownMenuItem<String>(
            value: value,
            child: Text(controller.formatWorkoutLabel(value)),
          ),
        )
        .toList();
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return 'Sun';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Marked present';
      case 'absent':
        return 'Marked absent';
      case 'holiday':
        return 'Manual holiday';
      case 'sunday':
        return 'Auto Sunday rest';
      default:
        return 'Not marked yet';
    }
  }

  ({Color background}) _statusColors(String status) {
    switch (status) {
      case 'present':
        return (background: const Color(0xFFDFF5E8));
      case 'absent':
        return (background: const Color(0xFFFFE2DE));
      case 'holiday':
        return (background: const Color(0xFFFFF0CA));
      case 'sunday':
        return (background: const Color(0xFFE4EAFF));
      default:
        return (background: const Color(0xFFFFFBF6));
    }
  }
}
