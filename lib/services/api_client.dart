import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  const ApiException(this.statusCode, this.code, this.message);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static const _storage = FlutterSecureStorage();
  static String? _baseUrlOverride;
  String? _token;

  static String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride!;
    const mode = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    const devUrl = String.fromEnvironment('API_BASE_URL_DEV');
    const prodUrl = String.fromEnvironment('API_BASE_URL_PROD');
    if (mode == 'production') return prodUrl.isNotEmpty ? prodUrl : 'https://api.amudhu.example.com';
    if (devUrl.isNotEmpty) return devUrl;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
  static set baseUrlOverride(String value) => _baseUrlOverride = value.trim().replaceFirst(RegExp(r'/$'), '');

  Future<void> initialize() async => _token = await _storage.read(key: 'amudhu_access_token');
  Future<Map<String, dynamic>?> readCachedUser() async {
    final value = await _storage.read(key: 'amudhu_user');
    if (value == null) return null;
    try { return jsonDecode(value) as Map<String, dynamic>; } catch (_) { return null; }
  }
  Future<void> cacheUser(Map<String, dynamic>? user) async {
    if (user == null) { await _storage.delete(key: 'amudhu_user'); return; }
    await _storage.write(key: 'amudhu_user', value: jsonEncode(user));
  }
  String? get token => _token;

  Future<void> setToken(String? token) async {
    _token = token;
    if (token == null || token.isEmpty) {
      await _storage.delete(key: 'amudhu_access_token');
      await _storage.delete(key: 'amudhu_user');
    } else {
      await _storage.write(key: 'amudhu_access_token', value: token);
    }
  }

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) => _send('GET', path, authenticated: authenticated);
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, bool authenticated = true}) => _send('POST', path, body: body, authenticated: authenticated);
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) => _send('PATCH', path, body: body);
  Future<void> delete(String path) async { await _send('DELETE', path); }

  Future<Map<String, dynamic>> _send(String method, String path, {Map<String, dynamic>? body, bool authenticated = true}) async {
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated && _token != null) headers['Authorization'] = 'Bearer $_token';
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 204 || response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        if (response.statusCode == 401 && authenticated) await setToken(null);
        throw ApiException(response.statusCode, map['code'] as String? ?? 'REQUEST_FAILED', map['error'] as String? ?? 'Request failed');
      }
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on ApiException { rethrow; }
    on SocketException { throw const ApiException(0, 'NETWORK_ERROR', 'Cannot connect to Amudhu. Check the API address and network connection.'); }
    on http.ClientException { throw const ApiException(0, 'NETWORK_ERROR', 'Cannot connect to Amudhu. Check the API address and network connection.'); }
    on FormatException { throw const ApiException(0, 'INVALID_RESPONSE', 'The server returned an invalid response.'); }
  }
}
