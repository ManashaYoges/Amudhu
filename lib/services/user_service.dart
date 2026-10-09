import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Service responsible for managing user profile documents in Cloud Firestore.
/// Profiles are stored at `users/{firebaseAuthUid}`.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _usersCollection =>
      _firestore?.collection('users');

  /// Creates a user profile document after registration.
  /// If the document already exists, merges non-destructive fields to avoid
  /// overwriting existing profile data unnecessarily.
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final collection = _usersCollection;
    if (collection == null) return;

    final docRef = collection.doc(uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // Avoid overwriting existing profile fields (e.g. createdAt, role, custom preferences)
      final updateData = <String, dynamic>{
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null && displayName.trim().isNotEmpty) {
        updateData['displayName'] = displayName.trim();
      }
      await docRef.set(updateData, SetOptions(merge: true));
    } else {
      // First-time profile creation
      final data = <String, dynamic>{
        'uid': uid,
        'email': email,
        if (displayName != null && displayName.trim().isNotEmpty)
          'displayName': displayName.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data);
    }
  }

  /// Retrieves the user profile document for a given [uid].
  /// Returns null if the document does not exist.
  Future<UserProfile?> getUserProfile(String uid) async {
    final collection = _usersCollection;
    if (collection == null) return null;

    final docSnapshot = await collection.doc(uid).get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }
    return UserProfile.fromFirestore(docSnapshot);
  }

  /// Streams real-time updates for a user profile document.
  Stream<UserProfile?> streamUserProfile(String uid) {
    final collection = _usersCollection;
    if (collection == null) {
      return const Stream<UserProfile?>.empty();
    }

    return collection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserProfile.fromFirestore(snapshot);
    });
  }

  /// Updates profile information for the authenticated user.
  /// Restricts modification of privileged fields such as 'role', 'uid', and 'createdAt'.
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    Map<String, dynamic>? additionalFields,
  }) async {
    final collection = _usersCollection;
    if (collection == null) return;

    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) {
      data['displayName'] = displayName.trim();
    }

    if (additionalFields != null) {
      // Prevent client-side modification of privileged or immutable fields
      const protectedFields = {'role', 'uid', 'createdAt'};
      for (final entry in additionalFields.entries) {
        if (!protectedFields.contains(entry.key)) {
          data[entry.key] = entry.value;
        }
      }
    }

    await collection.doc(uid).update(data);
  }
}
