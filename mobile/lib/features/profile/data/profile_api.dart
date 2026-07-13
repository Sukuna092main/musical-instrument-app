import 'dart:typed_data';

import '../../../core/network/api_client.dart';

class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final response =
        await _client.postMultipartFile(
              path: '/api/users/me/avatar',
              fieldName: 'avatar',
              bytes: bytes,
              filename: filename,
              mimeType: mimeType,
            )
            as Map<String, dynamic>;

    final data = Map<String, dynamic>.from(response['data'] as Map);

    return data['avatarUrl'] as String;
  }
}
