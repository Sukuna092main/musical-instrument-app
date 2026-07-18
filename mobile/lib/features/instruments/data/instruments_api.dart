import '../../../core/network/api_client.dart';

class InstrumentOption {
  const InstrumentOption({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.imageUrl,
    required this.isVip,
  });

  final String id;
  final String name;
  final String type;
  final String? description;
  final String? imageUrl;
  final bool isVip;

  factory InstrumentOption.fromJson(Map<String, dynamic> json) {
    return InstrumentOption(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isVip: json['is_vip'] == true,
    );
  }
}

class UserInstrument {
  const UserInstrument({
    required this.id,
    required this.instrumentId,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.description,
    required this.skillLevel,
    required this.isPrimary,
    required this.createdAt,
  });

  final String id; // user_instruments.id
  final String instrumentId; // instruments.id
  final String name;
  final String type;
  final String? imageUrl;
  final String? description;
  final String skillLevel; // beginner | intermediate | advanced
  final bool isPrimary;
  final DateTime createdAt;

  factory UserInstrument.fromJson(Map<String, dynamic> json) {
    final instrument = _asMap(json['instruments']);

    return UserInstrument(
      id: json['id'] as String,
      instrumentId: instrument?['id'] as String? ?? '',
      name: instrument?['name'] as String? ?? 'Unknown instrument',
      type: instrument?['type'] as String? ?? '',
      imageUrl: instrument?['image_url'] as String?,
      description: instrument?['description'] as String?,
      skillLevel: json['skill_level'] as String? ?? 'beginner',
      isPrimary: json['is_primary'] == true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class InstrumentsApi {
  InstrumentsApi(this._client);

  final ApiClient _client;

  /// GET /api/instruments — thư viện nhạc cụ active.
  Future<List<InstrumentOption>> getAvailable() async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/instruments') as Map,
    );

    final data = response['data'];
    if (data is! List) return [];

    return data
        .map(
          (item) =>
              InstrumentOption.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// GET /api/user-instruments — danh sách nhạc cụ user đang luyện.
  Future<List<UserInstrument>> getMine() async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/user-instruments') as Map,
    );

    final data = response['data'];
    if (data is! List) return [];

    return data
        .map(
          (item) =>
              UserInstrument.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// POST /api/user-instruments
  Future<UserInstrument> add(
    String instrumentId, {
    String skillLevel = 'beginner',
    bool isPrimary = false,
  }) async {
    final response = Map<String, dynamic>.from(
      await _client.post('/api/user-instruments', {
            'instrumentId': instrumentId,
            'skillLevel': skillLevel,
            'isPrimary': isPrimary,
          })
          as Map,
    );

    return UserInstrument.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  /// PUT /api/user-instruments/:instrumentId
  Future<UserInstrument> update(
    String instrumentId, {
    String? skillLevel,
    bool? isPrimary,
  }) async {
    final response = Map<String, dynamic>.from(
      await _client.put('/api/user-instruments/$instrumentId', {
            'skillLevel': ?skillLevel,
            'isPrimary': ?isPrimary,
          })
          as Map,
    );

    return UserInstrument.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  /// DELETE /api/user-instruments/:instrumentId
  Future<void> remove(String instrumentId) async {
    await _client.delete('/api/user-instruments/$instrumentId');
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}
