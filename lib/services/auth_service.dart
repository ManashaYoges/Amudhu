import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

/// Reusable authentication service managing Firebase Authentication flows
/// and orchestrating initial Firestore user profile creation.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final UserService _userService = UserService.instance;

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Stream of authentication state changes.
  /// Emits the current [User] when signed in, or null when signed out.
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream<User?>.empty();

  /// Returns the currently authenticated Firebase [User], or null if not signed in.
  User? get currentUser => _auth?.currentUser;

  /// Returns true if a user is currently signed in.
  bool get isAuthenticated => currentUser != null;

  /// Registers a new user with [email] and [password].
  ///
  /// Upon successful Firebase Auth registration:
  /// 1. Updates the Firebase user's display name (if provided).
  /// 2. Creates the corresponding Firestore document at `users/{uid}`.
  /// 3. Returns the [UserCredential].
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-initialized',
        message: 'Firebase is not initialized.',
      );
    }

    final cleanEmail = email.trim();
    final cleanName = displayName?.trim();

    final credential = await auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      if (cleanName != null && cleanName.isNotEmpty) {
        await user.updateDisplayName(cleanName);
      }

      // Create the user profile document in Firestore
      await _userService.createUserProfile(
        uid: user.uid,
        email: user.email ?? cleanEmail,
        displayName: cleanName,
      );
    }

    return credential;
  }

  /// Signs in an existing user with [email] and [password].
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-initialized',
        message: 'Firebase is not initialized.',
      );
    }

    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sends a password reset email to the specified [email].
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-initialized',
        message: 'Firebase is not initialized.',
      );
    }

    await auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Translates [FirebaseAuthException] and other errors into clean,
  /// user-friendly error messages.
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not properly formatted.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'operation-not-allowed':
          return 'Email and password accounts are not enabled in Firebase Console.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please try again later.';
        case 'channel-error':
          return 'Please provide both email and password.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    } else if (error is FirebaseException) {
      return error.message ?? 'A database error occurred.';
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
