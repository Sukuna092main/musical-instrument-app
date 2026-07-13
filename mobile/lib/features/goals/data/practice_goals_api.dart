import '../../../core/network/api_client.dart';

class GoalType {
  const GoalType._();

  static const dailyMinutes = 'daily_minutes';
  static const weeklyMinutes = 'weekly_minutes';
  static const weeklyDays = 'weekly_days';
  static const streakDays = 'streak_days';

  static const values = [dailyMinutes, weeklyMinutes, weeklyDays, streakDays];

  static String label(String type) {
    switch (type) {
      case dailyMinutes:
        return 'Daily practice';
      case weeklyMinutes:
        return 'Weekly practice time';
      case weeklyDays:
        return 'Weekly practice days';
      case streakDays:
        return 'Practice streak';
      default:
        return 'Practice goal';
    }
  }

  static String unit(String type) {
    switch (type) {
      case dailyMinutes:
      case weeklyMinutes:
        return 'minutes';
      default:
        return 'days';
    }
  }

  static int defaultTarget(String type) {
    switch (type) {
      case dailyMinutes:
        return 30;
      case weeklyMinutes:
        return 180;
      case weeklyDays:
        return 5;
      case streakDays:
        return 7;
      default:
        return 1;
    }
  }
}

class PracticeGoalProgress {
  PracticeGoalProgress({
    required this.id,
    required this.goalType,
    required this.currentValue,
    required this.targetValue,
    required this.progress,
    required this.completed,
    required this.instrumentName,
  });

  final String id;
  final String goalType;
  final int currentValue;
  final int targetValue;
  final int progress;
  final bool completed;
  final String? instrumentName;

  factory PracticeGoalProgress.fromJson(Map<String, dynamic> json) {
    final goal = Map<String, dynamic>.from(json['goal'] as Map);
    final instrument = goal['instrument'];

    return PracticeGoalProgress(
      id: goal['id'] as String,
      goalType: goal['goalType'] as String,
      currentValue: _toInt(json['currentValue']),
      targetValue: _toInt(json['targetValue']),
      progress: _toInt(json['progress']),
      completed: json['completed'] as bool? ?? false,
      instrumentName: instrument is Map ? instrument['name'] as String? : null,
    );
  }
}

class PracticeGoalsApi {
  PracticeGoalsApi(this._client);

  final ApiClient _client;

  Future<List<PracticeGoalProgress>> getProgress() async {
    final response =
        await _client.get('/api/practice-goals/progress')
            as Map<String, dynamic>;

    final data = response['data'];

    if (data is! List) {
      return [];
    }

    return data
        .map(
          (item) => PracticeGoalProgress.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> createGoal({
    required String goalType,
    required int targetValue,
    String? instrumentId,
  }) async {
    await _client.post('/api/practice-goals', {
      'goalType': goalType,
      'targetValue': targetValue,
      if (instrumentId != null) 'instrumentId': instrumentId,
    });
  }

  Future<void> updateGoal({
    required String goalId,
    String? goalType,
    int? targetValue,
    bool? isActive,
  }) async {
    await _client.put('/api/practice-goals/$goalId', {
      if (goalType != null) 'goalType': goalType,
      if (targetValue != null) 'targetValue': targetValue,
      if (isActive != null) 'isActive': isActive,
    });
  }

  Future<void> deleteGoal(String goalId) async {
    await _client.delete('/api/practice-goals/$goalId');
  }
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
