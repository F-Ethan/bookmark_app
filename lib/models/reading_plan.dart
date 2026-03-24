class ReadingPlan {
  final String id;
  final String userId;
  final String name;
  final int currentDay;
  final DateTime startDate;

  const ReadingPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.currentDay,
    required this.startDate,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      currentDay: json['current_day'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
    );
  }

  ReadingPlan copyWith({
    String? id,
    String? userId,
    String? name,
    int? currentDay,
    DateTime? startDate,
  }) {
    return ReadingPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      currentDay: currentDay ?? this.currentDay,
      startDate: startDate ?? this.startDate,
    );
  }
}
