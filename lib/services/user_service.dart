import 'dart:async';
import '../models/user_profile.dart';
import 'api_client.dart';
import 'auth_service.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();
  final ApiClient _api = ApiClient.instance;
  final StreamController<UserProfile?> _profileChanges = StreamController<UserProfile?>.broadcast();
  UserProfile? _profile;

  Future<void> refreshProfile() async {
    if (!AuthService.instance.isAuthenticated) return clearProfile();
    final response = await _api.get('/api/auth/me');
    final user = response['user'] as Map<String, dynamic>;
    _profile = UserProfile.fromMap(user, user['uid'] as String? ?? '');
    if (!_profileChanges.isClosed) _profileChanges.add(_profile);
  }

  void clearProfile() {
    _profile = null;
    if (!_profileChanges.isClosed) _profileChanges.add(null);
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    if (AuthService.instance.currentUser?.uid != uid) return null;
    if (_profile?.uid != uid) await refreshProfile();
    return _profile;
  }

  Stream<UserProfile?> streamUserProfile(String uid) async* {
    yield await getUserProfile(uid);
    yield* _profileChanges.stream.where((profile) => profile == null || profile.uid == uid);
  }

  Future<void> updateUserProfile({required String uid, String? displayName, Map<String, dynamic>? additionalFields}) async {
    if (AuthService.instance.currentUser?.uid != uid) throw StateError('Cannot update another user profile');
    if (displayName == null) return;
    final response = await _api.patch('/api/auth/me', body: {'displayName': displayName.trim()});
    final user = response['user'] as Map<String, dynamic>;
    _profile = UserProfile.fromMap(user, user['uid'] as String? ?? uid);
    if (!_profileChanges.isClosed) _profileChanges.add(_profile);
  }
}
