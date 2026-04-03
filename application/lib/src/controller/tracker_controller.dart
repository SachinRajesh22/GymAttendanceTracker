import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../constants/tracker_constants.dart';
import '../models/day_entry.dart';
import '../models/metrics.dart';
import '../services/storage_service.dart';

class TrackerController extends ChangeNotifier {
  TrackerController({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  final StorageService _storageService;

  bool isLoaded = false;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month - 1;
  Map<String, Map<String, DayEntry>> years = {};

  Future<void> load() async {
    final raw = await _storageService.load();
    if (raw != null && raw['years'] is Map<String, dynamic>) {
      selectedYear = (raw['selectedYear'] as int?) ?? DateTime.now().year;
      selectedMonth = (raw['selectedMonth'] as int?) ?? DateTime.now().month - 1;
      years = (raw['years'] as Map<String, dynamic>).map((year, value) {
        final entries = (value as Map<String, dynamic>).map((dateKey, entry) {
          return MapEntry(
            dateKey,
            DayEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
          );
        });
        return MapEntry(year, entries);
      });
    }

    isLoaded = true;
    notifyListeners();
  }

  Future<void> persist() async {
    final data = {
      'selectedYear': selectedYear,
      'selectedMonth': selectedMonth,
      'years': years.map((year, entries) {
        return MapEntry(
          year,
          entries.map((dateKey, entry) => MapEntry(dateKey, entry.toJson())),
        );
      }),
    };
    await _storageService.save(jsonDecode(jsonEncode(data)) as Map<String, dynamic>);
  }

  void goToToday() {
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month - 1;
    persist();
    notifyListeners();
  }

  void changeMonth(int step) {
    selectedMonth += step;
    if (selectedMonth < 0) {
      selectedMonth = 11;
      selectedYear -= 1;
    } else if (selectedMonth > 11) {
      selectedMonth = 0;
      selectedYear += 1;
    }
    persist();
    notifyListeners();
  }

  void selectYear(int year) {
    selectedYear = year;
    persist();
    notifyListeners();
  }

  void resetCurrentMonth() {
    final yearEntries = _yearData(selectedYear);
    final prefix = '${selectedYear}-${_pad(selectedMonth + 1)}-';
    yearEntries.removeWhere((key, value) => key.startsWith(prefix));
    persist();
    notifyListeners();
  }

  DayEntry entryFor(DateTime date) {
    return _yearData(date.year)[_dateKey(date)] ?? const DayEntry();
  }

  void updateStatus(DateTime date, String status) {
    final current = entryFor(date);
    final nextStatus = current.status == status ? 'unmarked' : status;
    _writeEntry(date, current.copyWith(status: nextStatus));
  }

  void updateHoliday(DateTime date) {
    final current = entryFor(date);
    final nextStatus = current.status == 'holiday' ? 'unmarked' : 'holiday';
    _writeEntry(date, current.copyWith(status: nextStatus));
  }

  void updateProtein(DateTime date, String value) {
    final current = entryFor(date);
    _writeEntry(date, current.copyWith(proteinText: _sanitizeProtein(value)));
  }

  void updateWorkout(DateTime date, String value) {
    final current = entryFor(date);
    _writeEntry(date, current.copyWith(workoutType: _sanitizeWorkout(value)));
  }

  String effectiveStatus(DateTime date) {
    final entry = entryFor(date);
    if (entry.status != 'unmarked') {
      return entry.status;
    }
    return date.weekday == DateTime.sunday ? 'sunday' : 'unmarked';
  }

  MonthMetrics monthMetrics(int year, int monthIndex) {
    final daysInMonth = DateTime(year, monthIndex + 2, 0).day;
    int presentDays = 0;
    int absentDays = 0;
    int holidayDays = 0;
    int sundayDays = 0;
    int proteinLoggedDays = 0;
    double totalProtein = 0;
    final workoutCounts = _emptyWorkoutCounts();

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, monthIndex + 1, day);
      final entry = entryFor(date);
      final status = effectiveStatus(date);
      final protein = _parseProtein(entry.proteinText);

      if (status == 'present') presentDays++;
      if (status == 'absent') absentDays++;
      if (status == 'holiday') holidayDays++;
      if (status == 'sunday') sundayDays++;

      if (protein != null) {
        proteinLoggedDays++;
        totalProtein += protein;
      }

      if (status == 'present' && entry.workoutType.isNotEmpty) {
        workoutCounts[entry.workoutType] = (workoutCounts[entry.workoutType] ?? 0) + 1;
      }
    }

    final trackedDays = presentDays + absentDays;
    return MonthMetrics(
      presentDays: presentDays,
      absentDays: absentDays,
      holidayDays: holidayDays,
      sundayDays: sundayDays,
      proteinLoggedDays: proteinLoggedDays,
      totalProtein: _round(totalProtein),
      attendanceRate: trackedDays == 0 ? 0 : _round((presentDays / trackedDays) * 100),
      averageProteinPerLoggedDay:
          proteinLoggedDays == 0 ? 0 : _round(totalProtein / proteinLoggedDays),
      workoutCounts: workoutCounts,
    );
  }

  YearMetrics yearMetrics(int year) {
    final months = List.generate(
      12,
      (index) => monthMetrics(year, index),
    );

    final presentDays = months.fold<int>(0, (sum, item) => sum + item.presentDays);
    final absentDays = months.fold<int>(0, (sum, item) => sum + item.absentDays);
    final holidayDays = months.fold<int>(0, (sum, item) => sum + item.holidayDays);
    final sundayDays = months.fold<int>(0, (sum, item) => sum + item.sundayDays);
    final proteinLoggedDays = months.fold<int>(0, (sum, item) => sum + item.proteinLoggedDays);
    final totalProtein = months.fold<double>(0, (sum, item) => sum + item.totalProtein);
    final trackedDays = presentDays + absentDays;
    final totalDays = _isLeapYear(year) ? 366 : 365;
    final unmarkedDays = totalDays - presentDays - absentDays - holidayDays - sundayDays;

    final workoutCounts = _emptyWorkoutCounts();
    for (final metrics in months) {
      for (final option in workoutOptions) {
        workoutCounts[option] = (workoutCounts[option] ?? 0) + (metrics.workoutCounts[option] ?? 0);
      }
    }

    int bestAttendanceIndex = 0;
    int lowestAbsenceIndex = 0;
    int bestProteinIndex = 0;
    for (int i = 1; i < months.length; i++) {
      if (months[i].presentDays > months[bestAttendanceIndex].presentDays) {
        bestAttendanceIndex = i;
      }
      if (months[i].absentDays < months[lowestAbsenceIndex].absentDays) {
        lowestAbsenceIndex = i;
      }
      if (months[i].totalProtein > months[bestProteinIndex].totalProtein) {
        bestProteinIndex = i;
      }
    }

    final streaks = _calculateStreaks(year);

    return YearMetrics(
      presentDays: presentDays,
      absentDays: absentDays,
      holidayDays: holidayDays,
      sundayDays: sundayDays,
      trackedDays: trackedDays,
      unmarkedDays: unmarkedDays,
      proteinLoggedDays: proteinLoggedDays,
      totalProtein: _round(totalProtein),
      attendanceRate: trackedDays == 0 ? 0 : _round((presentDays / trackedDays) * 100),
      averageProteinPerLoggedDay:
          proteinLoggedDays == 0 ? 0 : _round(totalProtein / proteinLoggedDays),
      averageProteinPerMonth: _round(totalProtein / 12),
      bestProteinDayLabel: _findBestProteinDay(year),
      bestAttendanceMonth:
          '${monthNames[bestAttendanceIndex]} (${months[bestAttendanceIndex].presentDays} present)',
      lowestAbsenceMonth:
          '${monthNames[lowestAbsenceIndex]} (${months[lowestAbsenceIndex].absentDays} absent)',
      bestProteinMonth:
          '${monthNames[bestProteinIndex]} (${months[bestProteinIndex].totalProtein} g)',
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      workoutCounts: workoutCounts,
    );
  }

  List<int> availableYears() {
    final current = DateTime.now().year;
    final values = <int>{current - 1, current, current + 1};
    values.addAll(years.keys.map(int.parse));
    final sorted = values.toList()..sort();
    return sorted;
  }

  String formatWorkoutLabel(String value) {
    return value
        .split('-')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _writeEntry(DateTime date, DayEntry entry) {
    final yearEntries = _yearData(date.year);
    if (entry.isEmpty) {
      yearEntries.remove(_dateKey(date));
    } else {
      yearEntries[_dateKey(date)] = entry;
    }
    persist();
    notifyListeners();
  }

  Map<String, DayEntry> _yearData(int year) {
    return years.putIfAbsent('$year', () => <String, DayEntry>{});
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  String _sanitizeProtein(String value) {
    final trimmed = value.trim();
    final safeLength = trimmed.length > 12 ? 12 : trimmed.length;
    return trimmed.substring(0, safeLength);
  }

  String _sanitizeWorkout(String value) => workoutOptions.contains(value) ? value : '';

  double? _parseProtein(String value) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(value);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1)!);
  }

  Map<String, int> _emptyWorkoutCounts() {
    return {
      for (final option in workoutOptions) option: 0,
    };
  }

  (int, int) _calculateStreaks(int year) {
    final totalDays = _isLeapYear(year) ? 366 : 365;
    int longest = 0;
    int running = 0;

    for (int i = 0; i < totalDays; i++) {
      final date = DateTime(year, 1, 1).add(Duration(days: i));
      final status = effectiveStatus(date);
      if (status == 'present') {
        running++;
        if (running > longest) {
          longest = running;
        }
      } else if (status == 'absent' || status == 'holiday' || status == 'unmarked') {
        running = 0;
      }
    }

    int current = 0;
    for (int i = totalDays - 1; i >= 0; i--) {
      final date = DateTime(year, 1, 1).add(Duration(days: i));
      final status = effectiveStatus(date);
      if (status == 'present') {
        current++;
      } else if (status != 'sunday') {
        break;
      }
    }

    return (current, longest);
  }

  String _findBestProteinDay(int year) {
    DateTime? bestDate;
    double? bestProtein;
    for (final entry in _yearData(year).entries) {
      final protein = _parseProtein(entry.value.proteinText);
      if (protein == null) continue;
      if (bestProtein == null || protein > bestProtein) {
        final parts = entry.key.split('-').map(int.parse).toList();
        bestDate = DateTime(parts[0], parts[1], parts[2]);
        bestProtein = protein;
      }
    }

    if (bestDate == null || bestProtein == null) {
      return 'No protein entries';
    }

    return '${bestDate.day} ${monthNames[bestDate.month - 1].substring(0, 3)} (${_round(bestProtein)} g)';
  }

  bool _isLeapYear(int year) {
    return DateTime(year, 2, 29).month == 2;
  }

  double _round(num value) {
    return (value * 10).roundToDouble() / 10;
  }
}
