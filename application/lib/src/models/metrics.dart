class MonthMetrics {
  const MonthMetrics({
    required this.presentDays,
    required this.absentDays,
    required this.holidayDays,
    required this.sundayDays,
    required this.proteinLoggedDays,
    required this.totalProtein,
    required this.attendanceRate,
    required this.averageProteinPerLoggedDay,
    required this.workoutCounts,
  });

  final int presentDays;
  final int absentDays;
  final int holidayDays;
  final int sundayDays;
  final int proteinLoggedDays;
  final double totalProtein;
  final double attendanceRate;
  final double averageProteinPerLoggedDay;
  final Map<String, int> workoutCounts;
}

class YearMetrics {
  const YearMetrics({
    required this.presentDays,
    required this.absentDays,
    required this.holidayDays,
    required this.sundayDays,
    required this.trackedDays,
    required this.unmarkedDays,
    required this.proteinLoggedDays,
    required this.totalProtein,
    required this.attendanceRate,
    required this.averageProteinPerLoggedDay,
    required this.averageProteinPerMonth,
    required this.bestProteinDayLabel,
    required this.bestAttendanceMonth,
    required this.lowestAbsenceMonth,
    required this.bestProteinMonth,
    required this.currentStreak,
    required this.longestStreak,
    required this.workoutCounts,
  });

  final int presentDays;
  final int absentDays;
  final int holidayDays;
  final int sundayDays;
  final int trackedDays;
  final int unmarkedDays;
  final int proteinLoggedDays;
  final double totalProtein;
  final double attendanceRate;
  final double averageProteinPerLoggedDay;
  final double averageProteinPerMonth;
  final String bestProteinDayLabel;
  final String bestAttendanceMonth;
  final String lowestAbsenceMonth;
  final String bestProteinMonth;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> workoutCounts;
}
