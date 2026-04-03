import 'package:flutter/material.dart';

import 'controller/tracker_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'theme/app_theme.dart';

class GymAttendanceApp extends StatefulWidget {
  const GymAttendanceApp({super.key});

  @override
  State<GymAttendanceApp> createState() => _GymAttendanceAppState();
}

class _GymAttendanceAppState extends State<GymAttendanceApp> {
  late final TrackerController controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = TrackerController()..load();
    controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChange);
    controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: currentIndex == 0
                ? CalendarScreen(
                    key: const ValueKey('calendar'),
                    controller: controller,
                  )
                : DashboardScreen(
                    key: const ValueKey('dashboard'),
                    controller: controller,
                  ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }
}
