import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// A standardized Auth model to wrap Supabase user or other providers.
class AuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final Map<String, dynamic>? metadata;

  /// Compatibility getter for legacy uid references.
  String get uid => id;

  AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.metadata,
  });

  /// Factory to create from Supabase User.
  factory AuthUser.fromSupabase(supabase.User user) {
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['full_name'] as String? ?? 
                   user.userMetadata?['display_name'] as String?,
      photoUrl: user.userMetadata?['avatar_url'] as String?,
      metadata: user.userMetadata,
    );
  }

  /// Helper to check if user is empty or not.
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Copy with utility for updates.
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, displayName: $displayName)';
  }
}
