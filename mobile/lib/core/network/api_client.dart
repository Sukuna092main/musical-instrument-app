import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiClient {
  static const _tokenKey = 'accessToken';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http.get(uri, headers: await _headers());

    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] ?? 'Request failed'
          : 'Request failed';

      throw Exception(message);
    }

    return decoded;
  }
}
