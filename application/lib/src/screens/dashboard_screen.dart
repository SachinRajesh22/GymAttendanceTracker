import 'package:flutter/material.dart';

import '../controller/tracker_controller.dart';
import '../widgets/detail_card.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
  });

  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics = controller.yearMetrics(controller.selectedYear);
    final years = controller.availableYears();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yearly gym, nutrition, and workout split summary.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: controller.selectedYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: years
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectYear(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              MetricCard(
                label: 'Gym days',
                value: '${metrics.presentDays}',
                subtext: 'Total present days',
              ),
              MetricCard(
                label: 'Absent days',
                value: '${metrics.absentDays}',
                subtext: 'Total missed days',
              ),
              MetricCard(
                label: 'Holiday days',
                value: '${metrics.holidayDays}',
                subtext: 'Manual holidays marked',
              ),
              MetricCard(
                label: 'Sunday days',
                value: '${metrics.sundayDays}',
                subtext: 'Auto-counted Sundays',
              ),
              MetricCard(
                label: 'Protein average',
                value: '${metrics.averageProteinPerLoggedDay} g',
                subtext: 'Average across logged entries',
              ),
              MetricCard(
                label: 'Total protein',
                value: '${metrics.totalProtein} g',
                subtext: 'All logged protein values',
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                DetailCard(
                  title: 'Attendance Summary',
                  rows: [
                    MapEntry('Attendance rate', '${metrics.attendanceRate}%'),
                    MapEntry('Tracked days', '${metrics.trackedDays}'),
                    MapEntry('Unmarked days', '${metrics.unmarkedDays}'),
                    MapEntry('Current streak', '${metrics.currentStreak} days'),
                    MapEntry('Best streak', '${metrics.longestStreak} days'),
                  ],
                ),
                const SizedBox(height: 12),
                DetailCard(
                  title: 'Protein Summary',
                  rows: [
                    MapEntry('Protein entries', '${metrics.proteinLoggedDays}'),
                    MapEntry('Average per month', '${metrics.averageProteinPerMonth} g'),
                    MapEntry('Best protein day', metrics.bestProteinDayLabel),
                    MapEntry('Best protein month', metrics.bestProteinMonth),
                  ],
                ),
                const SizedBox(height: 12),
                DetailCard(
                  title: 'Best Month Summary',
                  rows: [
                    MapEntry('Best attendance month', metrics.bestAttendanceMonth),
                    MapEntry('Lowest absence month', metrics.lowestAbsenceMonth),
                    MapEntry('Year selected', '${controller.selectedYear}'),
                  ],
                ),
                const SizedBox(height: 12),
                DetailCard(
                  title: 'Workout Split',
                  rows: controller.yearMetrics(controller.selectedYear).workoutCounts.entries
                      .map(
                        (entry) => MapEntry(
                          controller.formatWorkoutLabel(entry.key),
                          '${entry.value}',
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
