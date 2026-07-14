import '../../../core/network/api_client.dart';

class ChordSummary {
  const ChordSummary({
    required this.id,
    required this.name,
    required this.symbol,
    required this.category,
    required this.difficulty,
    required this.isVip,
    required this.instrumentName,
  });

  final String id;
  final String? name;
  final String? symbol;
  final String category;
  final String difficulty;
  final bool isVip;
  final String? instrumentName;

  factory ChordSummary.fromJson(Map<String, dynamic> json) {
    final instrument = _asMap(json['instruments']);

    return ChordSummary(
      id: json['id'] as String,
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
      category: json['category'] as String? ?? 'other',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      isVip: json['is_vip'] == true,
      instrumentName: instrument?['name'] as String?,
    );
  }
}

class ChordDetail {
  const ChordDetail({
    required this.id,
    required this.name,
    required this.symbol,
    required this.category,
    required this.difficulty,
    required this.isVip,
    required this.canAccess,
    required this.diagramUrl,
    required this.audioUrl,
    required this.description,
    required this.instrumentName,
  });

  final String id;
  final String? name;
  final String? symbol;
  final String category;
  final String difficulty;
  final bool isVip;
  final bool canAccess;
  final String? diagramUrl;
  final String? audioUrl;
  final String? description;
  final String? instrumentName;

  factory ChordDetail.fromJson(Map<String, dynamic> json) {
    final instrument = _asMap(json['instrument']);

    return ChordDetail(
      id: json['id'] as String,
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
      category: json['category'] as String? ?? 'other',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      isVip: json['isVip'] == true,
      canAccess: json['canAccess'] == true,
      diagramUrl: json['diagramUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      description: json['description'] as String?,
      instrumentName: instrument?['name'] as String?,
    );
  }
}

class ChordsApi {
  ChordsApi(this._client);

  final ApiClient _client;

  Future<List<ChordSummary>> getChords({
    String? instrumentId,
    String? category,
  }) async {
    final query = <String, String>{
      'limit': '50',
      if (instrumentId != null) 'instrumentId': instrumentId,
      if (category != null) 'category': category,
    };

    final queryString = Uri(queryParameters: query).query;
    final response = Map<String, dynamic>.from(
      await _client.get('/api/chords?$queryString') as Map,
    );

    final items = response['items'];
    if (items is! List) return [];

    return items
        .map(
          (item) =>
              ChordSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ChordDetail> getChord(String chordId) async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/chords/${Uri.encodeComponent(chordId)}') as Map,
    );

    return ChordDetail.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}
