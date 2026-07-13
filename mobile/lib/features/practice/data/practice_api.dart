import '../../../core/network/api_client.dart';

class PracticeStats {
  PracticeStats({
    required this.todayMinutes,
    required this.todaySessions,
    required this.weekMinutes,
    required this.weekSessions,
    required this.monthMinutes,
    required this.monthSessions,
    required this.allTimeSessions,
  });

  final int todayMinutes;
  final int todaySessions;
  final int weekMinutes;
  final int weekSessions;
  final int monthMinutes;
  final int monthSessions;
  final int allTimeSessions;

  factory PracticeStats.fromJson(Map<String, dynamic> json) {
    return PracticeStats(
      todayMinutes: json['today']['totalMins'] as int? ?? 0,
      todaySessions: json['today']['sessions'] as int? ?? 0,
      weekMinutes: json['thisWeek']['totalMins'] as int? ?? 0,
      weekSessions: json['thisWeek']['sessions'] as int? ?? 0,
      monthMinutes: json['thisMonth']['totalMins'] as int? ?? 0,
      monthSessions: json['thisMonth']['sessions'] as int? ?? 0,
      allTimeSessions: json['allTime']['sessions'] as int? ?? 0,
    );
  }
}

class PracticeStreak {
  PracticeStreak({required this.currentStreak, required this.longestStreak});

  final int currentStreak;
  final int longestStreak;

  factory PracticeStreak.fromJson(Map<String, dynamic> json) {
    return PracticeStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
    );
  }
}

class ActivePracticeSession {
  ActivePracticeSession({
    required this.id,
    required this.instrumentName,
    required this.startedAt,
  });

  final String id;
  final String instrumentName;
  final DateTime startedAt;

  factory ActivePracticeSession.fromJson(Map<String, dynamic> json) {
    final instrument = json['instruments'] as Map<String, dynamic>?;

    return ActivePracticeSession(
      id: json['id'] as String,
      instrumentName: instrument?['name'] as String? ?? 'Unknown instrument',
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }
}

class PracticeDashboard {
  PracticeDashboard({
    required this.stats,
    required this.streak,
    required this.activeSession,
  });

  final PracticeStats stats;
  final PracticeStreak streak;
  final ActivePracticeSession? activeSession;
}

class PracticeApi {
  PracticeApi(this._client);

  final ApiClient _client;

  Future<PracticeDashboard> getDashboard() async {
    final results = await Future.wait([
      _client.get('/api/practice-sessions/stats'),
      _client.get('/api/practice-sessions/streak'),
      _client.get('/api/practice-sessions/active'),
    ]);

    final statsJson = results[0]['data'] as Map<String, dynamic>;
    final streakJson = results[1]['data'] as Map<String, dynamic>;
    final activeJson = results[2]['data'];

    return PracticeDashboard(
      stats: PracticeStats.fromJson(statsJson),
      streak: PracticeStreak.fromJson(streakJson),
      activeSession: activeJson == null
          ? null
          : ActivePracticeSession.fromJson(activeJson as Map<String, dynamic>),
    );
  }
}
