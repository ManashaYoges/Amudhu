import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile stored in Cloud Firestore under `users/{uid}`.
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String role;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.createdAt,
    this.updatedAt,
    this.role = 'user',
  });

  /// Factory constructor to create a [UserProfile] from a Firestore DocumentSnapshot.
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return UserProfile.fromMap(data, snapshot.id);
  }

  /// Factory constructor to create a [UserProfile] from a Map and UID.
  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return UserProfile(
      uid: (data['uid'] as String?) ?? uid,
      email: (data['email'] as String?) ?? '',
      displayName: data['displayName'] as String?,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
      role: (data['role'] as String?) ?? 'user',
    );
  }

  /// Converts the profile data to a Map suitable for Firestore writes.
  /// Note: [createdAt] and [updatedAt] are typically written using FieldValue.serverTimestamp().
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      if (displayName != null) 'displayName': displayName,
      'role': role,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }

  @override
  String toString() =>
      'UserProfile(uid: $uid, email: $email, displayName: $displayName, role: $role)';
}
