import 'dart:async';
import 'api_client.dart';
import 'user_service.dart';

class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  const AuthUser({required this.uid, required this.email, this.displayName});
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    uid: json['uid'] as String? ?? json['_id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    displayName: json['displayName'] as String?,
  );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final ApiClient _api = ApiClient.instance;
  final StreamController<AuthUser?> _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _changes.stream;
  }

  Future<void> initialize() async {
    await _api.initialize();
    if (_api.token == null) return;
    final cachedUser = await _api.readCachedUser();
    if (cachedUser != null) _setUser(AuthUser.fromJson(cachedUser));
    try {
      final response = await _api.get('/api/auth/me');
      final user = response['user'] as Map<String, dynamic>;
      await _api.cacheUser(user);
      _setUser(AuthUser.fromJson(user));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _api.setToken(null);
        _setUser(null);
      }
    } catch (_) {
      // Keep a valid local session when the API is temporarily unreachable.
    }
  }

  Future<AuthUser> registerWithEmailAndPassword({required String email, required String password, String? displayName}) async {
    final response = await _api.post('/api/auth/register', authenticated: false, body: {
      'email': email.trim(), 'password': password, if (displayName != null) 'displayName': displayName.trim(),
    });
    return _acceptSession(response);
  }

  Future<AuthUser> signInWithEmailAndPassword({required String email, required String password}) async {
    final response = await _api.post('/api/auth/login', authenticated: false, body: {'email': email.trim(), 'password': password});
    return _acceptSession(response);
  }

  Future<AuthUser> _acceptSession(Map<String, dynamic> response) async {
    await _api.setToken(response['token'] as String?);
    final userJson = response['user'] as Map<String, dynamic>;
    await _api.cacheUser(userJson);
    final user = AuthUser.fromJson(userJson);
    _setUser(user);
    await UserService.instance.refreshProfile();
    return user;
  }

  void _setUser(AuthUser? user) {
    _currentUser = user;
    if (!_changes.isClosed) _changes.add(user);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _api.post('/api/auth/password-reset/request', authenticated: false, body: {'email': email.trim()});
  }

  Future<void> confirmPasswordReset({required String email, required String token, required String newPassword}) async {
    await _api.post('/api/auth/password-reset/confirm', authenticated: false, body: {
      'email': email.trim(), 'token': token.trim(), 'newPassword': newPassword,
    });
  }

  Future<void> directPasswordReset({required String email, required String newPassword}) async {
    await _api.post('/api/auth/password-reset/direct', authenticated: false, body: {
      'email': email.trim(),
      'newPassword': newPassword,
    });
  }

  Future<void> updateDisplayName(String displayName) async {
    final response = await _api.patch('/api/auth/me', body: {'displayName': displayName.trim()});
    final user = response['user'] as Map<String, dynamic>;
    await _api.cacheUser(user);
    _setUser(AuthUser.fromJson(user));
    await UserService.instance.refreshProfile();
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.post('/api/auth/change-password', body: {'currentPassword': currentPassword, 'newPassword': newPassword});
  }

  Future<void> signOut() async {
    try {
      if (_api.token != null) await _api.post('/api/auth/logout');
    } catch (_) {
      // Always clear the device session, even when the server cannot be reached.
    } finally {
      await _api.setToken(null);
      _setUser(null);
      UserService.instance.clearProfile();
    }
  }

  static String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 'TIMEOUT': return 'Server connection timed out (30s). Tap the Server icon at the top to check or change the server URL.';
        case 'GATEWAY_TIMEOUT': return 'Request timed out on the server. Please try again.';
        case 'EMAIL_EXISTS': return 'An account already exists with this email address.';
        case 'INVALID_CREDENTIALS': return 'Invalid email or password. Please check your credentials.';
        case 'VALIDATION_ERROR': return error.message;
        case 'RATE_LIMITED': return 'Too many attempts. Please try again later.';
        case 'EMAIL_NOT_CONFIGURED': return 'Password reset is not configured on the server yet.';
        case 'NETWORK_ERROR': return error.message;
        default: return error.message;
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
