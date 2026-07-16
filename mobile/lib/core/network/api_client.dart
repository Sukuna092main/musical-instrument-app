import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiClient {
  static const _tokenKey = 'accessToken';

  Future<Map<String, String>> _headers({
    bool includeJsonContentType = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    return {
      if (includeJsonContentType) 'Content-Type': 'application/json',
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
      headers: await _headers(includeJsonContentType: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http.put(
      uri,
      headers: await _headers(includeJsonContentType: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http.patch(
      uri,
      headers: await _headers(includeJsonContentType: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.delete(uri, headers: await _headers());

    return _handleResponse(response);
  }

  Future<dynamic> postMultipartFile({
    required String path,
    required String fieldName,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$path'),
    );

    request.headers.addAll(await _headers());

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

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
