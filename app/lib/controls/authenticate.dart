import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import '../entities/profile.dart';

// (#) Emits every login/logout event; the router listens so it can redirect.
final authChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authGatewayProvider).onAuthStateChange,
);

// (#) The signed-in user's id, or null when signed out. Controls read this
// (#) instead of touching Supabase's User type, and tests can override it.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authChangesProvider);
  return ref.watch(authGatewayProvider).currentUser?.id;
});

// (#) The signed-in user's full Profile row, refetched whenever auth changes;
// (#) null when nobody is signed in.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authChangesProvider);
  final auth = ref.watch(authGatewayProvider);
  final userId = auth.currentUser?.id;
  if (userId == null) return null;
  SeqLog.msg('authenticate', 'Authenticate', 'ProfileGateway', 'fetchProfile($userId)');
  return ref.watch(profileGatewayProvider).fetchProfile(userId);
});

// (#) The login and logout use case. It passes email and password to the auth
// (#) gateway and flips the signed-in state. The login screen just watches this
// (#) notifier's AsyncValue for loading and errors; it never talks to Supabase.
class Authenticate extends AsyncNotifier<void> {
  // (#) Nothing to load at startup; the notifier just sits idle until called.
  @override
  Future<void> build() async {}

  // (#) Signs the user in via the auth gateway (trims the email), then refreshes
  // (#) their profile. Wrapped in guard so loading and errors land in state.
  Future<void> signIn({required String email, required String password}) async {
    SeqLog.msg('authenticate', 'LoginScreen', 'Authenticate', 'signIn($email)');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      SeqLog.msg('authenticate', 'Authenticate', 'AuthGateway', 'signInWithPassword');
      await ref
          .read(authGatewayProvider)
          .signInWithPassword(email: email.trim(), password: password);
      ref.invalidate(currentProfileProvider);
    });
  }

  // (#) Signs the user out through the gateway and clears the cached profile.
  Future<void> signOut() async {
    SeqLog.msg('authenticate', 'HomeShell', 'Authenticate', 'signOut');
    await ref.read(authGatewayProvider).signOut();
    ref.invalidate(currentProfileProvider);
  }
}

// (#) Exposes the Authenticate control to the login screen and shell.
final authenticateProvider =
    AsyncNotifierProvider<Authenticate, void>(Authenticate.new);
