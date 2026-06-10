import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import '../entities/profile.dart';

/// Stream of auth state changes — the router refreshes on this.
final authChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authGatewayProvider).onAuthStateChange,
);

/// The signed-in user's Profile (null when signed out). Re-fetches on auth change.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authChangesProvider);
  final auth = ref.watch(authGatewayProvider);
  final userId = auth.currentUser?.id;
  if (userId == null) return null;
  SeqLog.msg('authenticate', 'Authenticate', 'ProfileGateway', 'fetchProfile($userId)');
  return ref.watch(profileGatewayProvider).fetchProfile(userId);
});

/// CONTROL — the Authenticate use case (login / logout). The LoginScreen watches
/// this notifier's [AsyncValue] for loading/error; success flips the auth stream,
/// which refreshes the router redirect.
class Authenticate extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

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

  Future<void> signOut() async {
    SeqLog.msg('authenticate', 'HomeShell', 'Authenticate', 'signOut');
    await ref.read(authGatewayProvider).signOut();
    ref.invalidate(currentProfileProvider);
  }
}

final authenticateProvider =
    AsyncNotifierProvider<Authenticate, void>(Authenticate.new);
