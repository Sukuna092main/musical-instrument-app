import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_api.dart';

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

  /// PATCH /api/users/me — cập nhật full_name/phone, trả user mới.
  Future<AuthUser> updateProfile({String? fullName, String? phone}) async {
    final response = Map<String, dynamic>.from(
      await _client.patch('/api/users/me', {
            'fullName': ?fullName,
            'phone': ?phone,
          })
          as Map,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  /// PATCH /api/users/me/password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.patch('/api/users/me/password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }
}
