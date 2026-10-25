import 'dart:async';
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
  static const _baseUrlStorageKey = 'amudhu_base_url';

  // Change this if your laptop's IPv4 address changes.
  static const String _laptopBaseUrl = 'http://10.252.0.71:3000';

  static String? _baseUrlOverride;
  static String? _autoResolvedBaseUrl;

  String? _token;

  static String get baseUrl {
    if (_baseUrlOverride != null && _baseUrlOverride!.isNotEmpty) {
      return _baseUrlOverride!;
    }

    if (_autoResolvedBaseUrl != null && _autoResolvedBaseUrl!.isNotEmpty) {
      return _autoResolvedBaseUrl!;
    }

    const mode = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    const devUrl = String.fromEnvironment('API_BASE_URL_DEV');
    const prodUrl = String.fromEnvironment('API_BASE_URL_PROD');

    if (mode == 'production') {
      return prodUrl.isNotEmpty ? prodUrl : 'https://api.amudhu.example.com';
    }

    if (devUrl.isNotEmpty) {
      return devUrl;
    }

    // Physical Android phone and local development default.
    return _laptopBaseUrl;
  }

  static set baseUrlOverride(String value) {
    final clean = value.trim().replaceFirst(RegExp(r'/$'), '');

    _baseUrlOverride = clean;
    _autoResolvedBaseUrl = null;

    _storage
        .write(
          key: _baseUrlStorageKey,
          value: clean,
        )
        .catchError((_) {});
  }

  static Future<void> saveBaseUrl(String value) async {
    final clean = value.trim().replaceFirst(RegExp(r'/$'), '');

    _baseUrlOverride = clean;
    _autoResolvedBaseUrl = null;

    await _storage.write(
      key: _baseUrlStorageKey,
      value: clean,
    );
  }

  static Future<void> resetBaseUrl() async {
    _baseUrlOverride = null;
    _autoResolvedBaseUrl = null;

    await _storage.delete(key: _baseUrlStorageKey);
    await autoDetectBaseUrl();
  }

  /// Detects a reachable backend endpoint.
  ///
  /// Physical Android phone: laptop IP address.
  /// Android emulator: 10.0.2.2.
  /// Web/desktop: localhost.
  static Future<String> autoDetectBaseUrl() async {
    if (_baseUrlOverride != null && _baseUrlOverride!.isNotEmpty) {
      return _baseUrlOverride!;
    }

    const mode = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    const devUrl = String.fromEnvironment('API_BASE_URL_DEV');
    const prodUrl = String.fromEnvironment('API_BASE_URL_PROD');

    if (mode == 'production' && prodUrl.isNotEmpty) {
      _autoResolvedBaseUrl = prodUrl;
      return prodUrl;
    }

    if (devUrl.isNotEmpty) {
      _autoResolvedBaseUrl = devUrl;
      return devUrl;
    }

    final List<String> candidates = [];

    if (kIsWeb) {
      candidates.add('http://localhost:3000');
    } else if (Platform.isAndroid) {
      // Try the laptop IP first for a physical Android phone.
      candidates.add(_laptopBaseUrl);

      // Android emulator fallback.
      candidates.add('http://10.0.2.2:3000');

      // Works when USB debugging and adb reverse are configured.
      candidates.add('http://localhost:3000');
    } else {
      candidates.add('http://localhost:3000');
    }

    for (final candidate in candidates) {
      try {
        final uri = Uri.parse('$candidate/health');

        final response =
            await http.get(uri).timeout(const Duration(seconds: 2));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _autoResolvedBaseUrl = candidate;
          return candidate;
        }
      } catch (_) {
        // Try the next candidate.
      }
    }

    // Preserve the correct physical-phone development default.
    _autoResolvedBaseUrl = Platform.isAndroid && !kIsWeb
        ? _laptopBaseUrl
        : 'http://localhost:3000';

    return _autoResolvedBaseUrl!;
  }

  Future<void> initialize() async {
    _token = await _storage.read(key: 'amudhu_access_token');

    try {
      final savedUrl = await _storage.read(
        key: _baseUrlStorageKey,
      );

      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrlOverride = savedUrl.trim().replaceFirst(RegExp(r'/$'), '');
      } else {
        await autoDetectBaseUrl();
      }
    } catch (_) {
      // Use the default development URL if storage fails.
    }
  }

  Future<Map<String, dynamic>?> readCachedUser() async {
    final value = await _storage.read(key: 'amudhu_user');

    if (value == null) return null;

    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheUser(Map<String, dynamic>? user) async {
    if (user == null) {
      await _storage.delete(key: 'amudhu_user');
      return;
    }

    await _storage.write(
      key: 'amudhu_user',
      value: jsonEncode(user),
    );
  }

  String? get token => _token;

  Future<void> setToken(String? token) async {
    _token = token;

    if (token == null || token.isEmpty) {
      await _storage.delete(key: 'amudhu_access_token');
      await _storage.delete(key: 'amudhu_user');
    } else {
      await _storage.write(
        key: 'amudhu_access_token',
        value: token,
      );
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = true,
  }) {
    return _send(
      'GET',
      path,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send(
      'PATCH',
      path,
      body: body,
    );
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri.parse('$normalizedBaseUrl$normalizedPath');

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    try {
      final request = http.Request(method, uri)..headers.addAll(headers);

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 204 || response.body.isEmpty) {
        return <String, dynamic>{};
      }

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final map =
            decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

        if (response.statusCode == 401 && authenticated) {
          await setToken(null);
        }

        throw ApiException(
          response.statusCode,
          map['code'] as String? ?? 'REQUEST_FAILED',
          map['error'] as String? ?? 'Request failed',
        );
      }

      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException(
        0,
        'NETWORK_ERROR',
        'Cannot connect to Amudhu server at $baseUrl. '
            'Check that the backend is running, the URL is correct, '
            'and your phone can reach the laptop. ($e)',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        0,
        'NETWORK_ERROR',
        'Cannot connect to Amudhu server at $baseUrl. '
            'Check your backend and network configuration. ($e)',
      );
    } on TimeoutException {
      throw ApiException(
        408,
        'TIMEOUT',
        'Request to Amudhu server at $baseUrl timed out. '
            'Check your network connection and backend.',
      );
    } on FormatException {
      throw const ApiException(
        0,
        'INVALID_RESPONSE',
        'The server returned an invalid response.',
      );
    } catch (e) {
      throw ApiException(
        0,
        'UNKNOWN_ERROR',
        'Unexpected error: $e',
      );
    }
  }
}
