import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service handling Supabase Authentication.
class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Current authenticated user (null if signed out).
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Whether the user is currently signed in.
  bool get isSignedIn => _supabase.auth.currentUser != null;

  /// Sign in with Email and Password.
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('AUTH: Attempting email sign-in for $email');
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('AUTH: Sign-in successful, user: ${response.user?.id}');
      return response.user;
    } on AuthException catch (e) {
      debugPrint('AUTH: Sign-in AuthException: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AUTH: Sign-in error: $e');
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  /// Register with Email and Password.
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      debugPrint('AUTH: Attempting registration for $email');
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('AUTH: Registration response - user: ${response.user?.id}, session: ${response.session != null ? "active" : "null"}, emailConfirmed: ${response.user?.emailConfirmedAt}');
      return response.user;
    } on AuthException catch (e) {
      debugPrint('AUTH: Registration AuthException: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AUTH: Registration error: $e');
      throw 'An unexpected error occurred during registration: ${e.toString()}';
    }
  }

  /// Sign in with Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'scorecaddie://login-callback',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during Google Sign-In: ${e.toString()}';
    }
  }

  /// Helper to convert Supabase Auth codes into user-friendly messages.
  String _handleAuthException(AuthException e) {
    // Basic mapping of Supabase AuthException to user-facing strings
    switch (e.statusCode) {
      case '400':
        if (e.message.toLowerCase().contains('invalid login credentials')) {
           return 'Invalid login credentials. Please try again.';
        }
        return e.message;
      case '404':
        return 'No user found with this email.';
      case '422':
        if (e.message.toLowerCase().contains('already registered')) {
          return 'An account already exists for this email.';
        }
        return e.message;
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get user display name (metadata).
  String? get displayName => currentUser?.userMetadata?['full_name'];

  /// Get user email.
  String? get email => currentUser?.email;

  /// Get user photo URL (metadata).
  String? get photoUrl => currentUser?.userMetadata?['avatar_url'];

  /// Get Supabase UID.
  String? get uid => currentUser?.id;

  /// Update user email.
  Future<void> updateEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user password.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete user account. (Requires service role in Supabase typically or Rpc, but we implement basic signout here for the client side depending on specific backend RPC configurations.)
  Future<void> deleteAccount() async {
    // Note: Supabase client libraries generally do not expose a user.delete() 
    // method for security. An edge function or an RPC call should handle account deletion.
    // Assuming you have an RPC called `delete_user_account`. 
    try {
      await _supabase.rpc('delete_user_account');
      await signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {}
  }
}
