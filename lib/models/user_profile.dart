/// Public user profile returned by the Amudhu API. Password fields are never
/// included in API responses or represented by this client model.
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String role;

  const UserProfile({required this.uid, required this.email, this.displayName, this.createdAt, this.updatedAt, this.role = 'user'});

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    DateTime? parseDate(dynamic value) => value is String ? DateTime.tryParse(value) : null;
    return UserProfile(
      uid: data['uid'] as String? ?? data['_id'] as String? ?? uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      role: data['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid, 'email': email, if (displayName != null) 'displayName': displayName,
    'role': role, if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  UserProfile copyWith({String? uid, String? email, String? displayName, DateTime? createdAt, DateTime? updatedAt, String? role}) => UserProfile(
    uid: uid ?? this.uid, email: email ?? this.email, displayName: displayName ?? this.displayName,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt, role: role ?? this.role,
  );

  @override
  String toString() => 'UserProfile(uid: $uid, email: $email, displayName: $displayName, role: $role)';
}
