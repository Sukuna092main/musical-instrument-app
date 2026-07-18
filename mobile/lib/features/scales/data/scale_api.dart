import '../../../core/network/api_client.dart';

class ScaleSummary {
  const ScaleSummary({
    required this.id,
    required this.name,
    required this.key,
    required this.scaleType,
    required this.difficulty,
    required this.isVip,
    required this.instrumentName,
  });

  final String id;
  final String name;
  final String? key;
  final String scaleType;
  final String difficulty;
  final bool isVip;
  final String? instrumentName;

  factory ScaleSummary.fromJson(Map<String, dynamic> json) {
    final instrument = _asMap(json['instruments']);

    return ScaleSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      key: json['key'] as String?,
      scaleType: json['scale_type'] as String? ?? 'other',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      isVip: json['is_vip'] == true,
      instrumentName: instrument?['name'] as String?,
    );
  }
}

class ScaleDetail {
  const ScaleDetail({
    required this.id,
    required this.name,
    required this.key,
    required this.scaleType,
    required this.difficulty,
    required this.isVip,
    required this.canAccess,
    required this.diagramUrl,
    required this.audioUrl,
    required this.description,
    required this.instrumentName,
  });

  final String id;
  final String name;
  final String? key;
  final String scaleType;
  final String difficulty;
  final bool isVip;
  final bool canAccess;
  final String? diagramUrl;
  final String? audioUrl;
  final String? description;
  final String? instrumentName;

  factory ScaleDetail.fromJson(Map<String, dynamic> json) {
    final instrument = _asMap(json['instrument']);

    return ScaleDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      key: json['key'] as String?,
      scaleType: json['scaleType'] as String? ?? 'other',
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

class ScalesApi {
  ScalesApi(this._client);

  final ApiClient _client;

  Future<List<ScaleSummary>> getScales({
    String? instrumentId,
    String? scaleType,
  }) async {
    final query = <String, String>{
      'limit': '50',
      'instrumentId': ?instrumentId,
      'scaleType': ?scaleType,
    };

    final queryString = Uri(queryParameters: query).query;
    final response = Map<String, dynamic>.from(
      await _client.get('/api/scales?$queryString') as Map,
    );

    final items = response['items'];
    if (items is! List) return [];

    return items
        .map(
          (item) =>
              ScaleSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ScaleDetail> getScale(String scaleId) async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/scales/${Uri.encodeComponent(scaleId)}') as Map,
    );

    return ScaleDetail.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}
