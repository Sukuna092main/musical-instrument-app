import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String status;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
    );
  }
}

class AuthResult {
  AuthResult({required this.user, required this.accessToken});

  final AuthUser user;
  final String accessToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
    );
  }
}

class AuthApi {
  static const _tokenKey = 'accessToken';

  Future<AuthResult> login({required String email, required String password}) {
    return _postAuth('/api/auth/login', {'email': email, 'password': password});
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _postAuth('/api/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<AuthResult> _postAuth(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Authentication failed');
    }

    final result = AuthResult.fromJson(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.accessToken);

    return result;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
