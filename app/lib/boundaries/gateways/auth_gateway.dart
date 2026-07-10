import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// (#) The app's front door to Supabase Auth. Controls use it to sign a user in
// (#) or out, send a password reset email, and watch whether someone is logged in.
class AuthGateway {
  // (#) Keeps the Supabase client that owns the auth session.
  AuthGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client backing all auth calls

  Session? get currentSession => _client.auth.currentSession; // (#) the live login session, or null
  User? get currentUser => _client.auth.currentUser; // (#) the logged in user, or null
  bool get isSignedIn => currentSession != null; // (#) quick yes/no for logged in

  // (#) Fires every time the login state changes, so the router can redirect.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // (#) Signs a user in with their email and password against Supabase Auth.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  // (#) Logs the current user out and clears their session.
  Future<void> signOut() => _client.auth.signOut();

  // (#) Emails a reset link. Stays quiet for unknown emails so it never leaks
  // (#) whether an address is registered.
  Future<void> sendPasswordResetEmail(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
}

// (#) Riverpod provider that shares one auth gateway on the live Supabase client.
final authGatewayProvider = Provider<AuthGateway>(
  (ref) => AuthGateway(Supabase.instance.client),
);
