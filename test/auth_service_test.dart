import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amudu/services/auth_service.dart';

void main() {
  group('AuthService error message mapping', () {
    test('maps invalid-email properly', () {
      final error = FirebaseAuthException(code: 'invalid-email');
      expect(
        AuthService.getErrorMessage(error),
        'The email address is not properly formatted.',
      );
    });

    test('maps weak-password properly', () {
      final error = FirebaseAuthException(code: 'weak-password');
      expect(
        AuthService.getErrorMessage(error),
        'The password is too weak. Please use at least 6 characters.',
      );
    });

    test('maps email-already-in-use properly', () {
      final error = FirebaseAuthException(code: 'email-already-in-use');
      expect(
        AuthService.getErrorMessage(error),
        'An account already exists with this email address.',
      );
    });

    test('maps invalid-credential properly', () {
      final error = FirebaseAuthException(code: 'invalid-credential');
      expect(
        AuthService.getErrorMessage(error),
        'Invalid email or password. Please check your credentials.',
      );
    });

    test('maps network-request-failed properly', () {
      final error = FirebaseAuthException(code: 'network-request-failed');
      expect(
        AuthService.getErrorMessage(error),
        'Network error. Please check your internet connection.',
      );
    });

    test('handles fallback error string gracefully', () {
      expect(
        AuthService.getErrorMessage('Some unexpected error'),
        'Some unexpected error',
      );
    });
  });
}
