import 'package:flutter/material.dart';

import '../constants/tracker_constants.dart';
import '../controller/tracker_controller.dart';
import '../widgets/day_row_card.dart';
import '../widgets/detail_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.controller,
  });

  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final year = controller.selectedYear;
    final monthIndex = controller.selectedMonth;
    final metrics = controller.monthMetrics(year, monthIndex);
    final daysInMonth = DateTime(year, monthIndex + 2, 0).day;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gym Attendance',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'One month at a time, optimized for mobile entry.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.changeMonth(-1),
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(
                            monthNames[monthIndex],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text('$year'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.changeMonth(1),
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: controller.goToToday,
                        child: const Text('Go to current month'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: controller.resetCurrentMonth,
                        child: const Text('Reset this month'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DetailCard(
                  title: 'Month Summary',
                  rows: [
                    MapEntry('Attendance', '${metrics.presentDays} present'),
                    MapEntry('Absent days', '${metrics.absentDays}'),
                    MapEntry('Holiday days', '${metrics.holidayDays}'),
                    MapEntry('Sunday rests', '${metrics.sundayDays}'),
                    MapEntry('Protein average', '${metrics.averageProteinPerLoggedDay} g'),
                    MapEntry('Protein total', '${metrics.totalProtein} g'),
                    MapEntry('Attendance rate', '${metrics.attendanceRate}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.builder(
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final date = DateTime(year, monthIndex + 1, index + 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DayRowCard(
                  date: date,
                  entry: controller.entryFor(date),
                  effectiveStatus: controller.effectiveStatus(date),
                  controller: controller,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
