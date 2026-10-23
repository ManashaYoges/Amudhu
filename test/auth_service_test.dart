import 'package:flutter_test/flutter_test.dart';
import 'package:amudu/services/api_client.dart';
import 'package:amudu/services/auth_service.dart';

void main() {
  group('AuthService error message mapping', () {
    test('maps duplicate email safely', () {
      expect(AuthService.getErrorMessage(const ApiException(409, 'EMAIL_EXISTS', 'duplicate')),
          'An account already exists with this email address.');
    });
    test('maps invalid credentials without disclosing account state', () {
      expect(AuthService.getErrorMessage(const ApiException(401, 'INVALID_CREDENTIALS', 'invalid')),
          'Invalid email or password. Please check your credentials.');
    });
    test('reports missing email provider truthfully', () {
      expect(AuthService.getErrorMessage(const ApiException(503, 'EMAIL_NOT_CONFIGURED', 'not configured')),
          'Password reset is not configured on the server yet.');
    });
    test('handles fallback errors gracefully', () {
      expect(AuthService.getErrorMessage('Some unexpected error'), 'Some unexpected error');
    });
  });
}
