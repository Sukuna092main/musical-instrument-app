import '../../../core/network/api_client.dart';
import 'practice_api.dart';

class UserPracticeInstrument {
  UserPracticeInstrument({
    required this.instrumentId,
    required this.name,
    required this.type,
    required this.skillLevel,
    required this.isPrimary,
  });

  final String instrumentId;
  final String name;
  final String type;
  final String skillLevel;
  final bool isPrimary;

  factory UserPracticeInstrument.fromJson(Map<String, dynamic> json) {
    final instrument = json['instruments'] as Map<String, dynamic>? ?? {};

    return UserPracticeInstrument(
      instrumentId: instrument['id'] as String,
      name: instrument['name'] as String? ?? 'Unknown instrument',
      type: instrument['type'] as String? ?? '',
      skillLevel: json['skill_level'] as String? ?? 'beginner',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class PracticeTimerApi {
  PracticeTimerApi(this._client);

  final ApiClient _client;

  Future<List<UserPracticeInstrument>> getUserInstruments() async {
    final response =
        await _client.get('/api/user-instruments') as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? [];

    return items
        .map(
          (item) => UserPracticeInstrument.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<ActivePracticeSession?> getActiveSession() async {
    final response =
        await _client.get('/api/practice-sessions/active')
            as Map<String, dynamic>;
    final data = response['data'];

    if (data == null) {
      return null;
    }

    return ActivePracticeSession.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<ActivePracticeSession> startSession(String instrumentId) async {
    final response =
        await _client.post('/api/practice-sessions/start', {
              'instrumentId': instrumentId,
            })
            as Map<String, dynamic>;

    return ActivePracticeSession.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<void> endSession({
    required String sessionId,
    String? notes,
    String? mood,
  }) async {
    await _client.post('/api/practice-sessions/$sessionId/end', {
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (mood != null) 'mood': mood,
    });
  }
}
