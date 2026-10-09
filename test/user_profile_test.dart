import 'package:flutter_test/flutter_test.dart';
import 'package:amudu/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('creates UserProfile from valid map', () {
      final now = DateTime.now();
      final map = {
        'uid': 'user_123',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'createdAt': now.toIso8601String(),
        'role': 'user',
      };

      final profile = UserProfile.fromMap(map, 'user_123');

      expect(profile.uid, 'user_123');
      expect(profile.email, 'test@example.com');
      expect(profile.displayName, 'Test User');
      expect(profile.role, 'user');
    });

    test('toMap converts fields properly', () {
      const profile = UserProfile(
        uid: 'user_456',
        email: 'hello@amudhu.com',
        displayName: 'Chef Amudhu',
        role: 'user',
      );

      final map = profile.toMap();

      expect(map['uid'], 'user_456');
      expect(map['email'], 'hello@amudhu.com');
      expect(map['displayName'], 'Chef Amudhu');
      expect(map['role'], 'user');
    });

    test('copyWith updates specified fields', () {
      const profile = UserProfile(
        uid: 'user_789',
        email: 'initial@amudhu.com',
        displayName: 'Old Name',
      );

      final updated = profile.copyWith(displayName: 'New Name');

      expect(updated.displayName, 'New Name');
      expect(updated.email, 'initial@amudhu.com');
      expect(updated.uid, 'user_789');
    });
  });
}
