class DayEntry {
  const DayEntry({
    this.status = 'unmarked',
    this.proteinText = '',
    this.workoutType = '',
  });

  final String status;
  final String proteinText;
  final String workoutType;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'proteinText': proteinText,
      'workoutType': workoutType,
    };
  }

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    return DayEntry(
      status: (json['status'] as String?) ?? 'unmarked',
      proteinText: (json['proteinText'] as String?) ?? '',
      workoutType: (json['workoutType'] as String?) ?? '',
    );
  }

  DayEntry copyWith({
    String? status,
    String? proteinText,
    String? workoutType,
  }) {
    return DayEntry(
      status: status ?? this.status,
      proteinText: proteinText ?? this.proteinText,
      workoutType: workoutType ?? this.workoutType,
    );
  }

  bool get isEmpty =>
      status == 'unmarked' && proteinText.isEmpty && workoutType.isEmpty;
}
