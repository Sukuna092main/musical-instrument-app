import '../../../core/network/api_client.dart';

class PracticeHistoryInstrument {
  PracticeHistoryInstrument({required this.id, required this.name});

  final String id;
  final String name;

  factory PracticeHistoryInstrument.fromJson(Map<String, dynamic> json) {
    final instrument = json['instruments'] as Map<String, dynamic>? ?? {};

    return PracticeHistoryInstrument(
      id: instrument['id'] as String,
      name: instrument['name'] as String? ?? 'Unknown instrument',
    );
  }
}

class PracticeHistorySession {
  PracticeHistorySession({
    required this.id,
    required this.instrumentId,
    required this.instrumentName,
    required this.durationMinutes,
    required this.startedAt,
    required this.notes,
    required this.mood,
  });

  final String id;
  final String instrumentId;
  final String instrumentName;
  final int durationMinutes;
  final DateTime startedAt;
  final String? notes;
  final String? mood;

  factory PracticeHistorySession.fromJson(Map<String, dynamic> json) {
    final instrument = json['instruments'] as Map<String, dynamic>? ?? {};

    return PracticeHistorySession(
      id: json['id'] as String,
      instrumentId:
          json['instrument_id'] as String? ?? instrument['id'] as String? ?? '',
      instrumentName: instrument['name'] as String? ?? 'Unknown instrument',
      durationMinutes: (json['duration_mins'] as num? ?? 0).toInt(),
      startedAt: DateTime.parse(json['started_at'] as String),
      notes: json['notes'] as String?,
      mood: json['mood'] as String?,
    );
  }
}

class PracticeHistoryPage {
  PracticeHistoryPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<PracticeHistorySession> items;
  final int page;
  final int totalPages;

  factory PracticeHistoryPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final items = json['items'] as List<dynamic>? ?? [];

    return PracticeHistoryPage(
      items: items
          .map(
            (item) => PracticeHistorySession.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      page: pagination['page'] as int? ?? 1,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }
}

class PracticeHistoryApi {
  PracticeHistoryApi(this._client);

  final ApiClient _client;

  Future<List<PracticeHistoryInstrument>> getUserInstruments() async {
    final response =
        await _client.get('/api/user-instruments') as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? [];

    return items
        .map(
          (item) => PracticeHistoryInstrument.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<PracticeHistoryPage> getSessions({
    required int page,
    required int limit,
    String? instrumentId,
  }) async {
    final query = <String>[
      'page=$page',
      'limit=$limit',
      if (instrumentId != null)
        'instrumentId=${Uri.encodeQueryComponent(instrumentId)}',
    ].join('&');

    final response =
        await _client.get('/api/practice-sessions?$query')
            as Map<String, dynamic>;

    return PracticeHistoryPage.fromJson(response);
  }
}
