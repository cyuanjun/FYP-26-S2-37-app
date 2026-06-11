import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// BOUNDARY (gateway) — system-facing adapter over Supabase Auth.
///
/// Controls call this; the UI and Entities never touch Supabase directly.
/// See CLAUDE.md "BCE — the architectural rule": Actor ─ Boundary ─ Control ─ Entity.
class AuthGateway {
  AuthGateway(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentSession != null;

  /// Emits on sign-in / sign-out / token refresh — drives router redirects.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  /// Emails a password-reset link (#4 Forgot Password, #13.3 Change Password).
  /// Succeeds silently for unknown emails — never reveals registration status.
  Future<void> sendPasswordResetEmail(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
}

/// Singleton gateway bound to the initialized Supabase client.
final authGatewayProvider = Provider<AuthGateway>(
  (ref) => AuthGateway(Supabase.instance.client),
);
