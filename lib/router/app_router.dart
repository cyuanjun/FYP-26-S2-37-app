import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../boundaries/ui/auth/login_screen.dart';
import '../boundaries/ui/home/home_shell.dart';
import '../boundaries/ui/splash/splash_screen.dart';

/// App router. Splash decides the first destination; thereafter the redirect
/// gates on auth presence (role-based redirects for premium/expert/admin land later).
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authGatewayProvider);

  return GoRouter(
    initialLocation: SplashScreen.path,
    refreshListenable: _GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == SplashScreen.path) return null; // splash routes itself
      final signedIn = auth.isSignedIn;
      final atLogin = loc == LoginScreen.path;
      if (!signedIn && !atLogin) return LoginScreen.path;
      if (signedIn && atLogin) return HomeShell.path;
      return null;
    },
    routes: [
      GoRoute(path: SplashScreen.path, builder: (_, _) => const SplashScreen()),
      GoRoute(path: LoginScreen.path, builder: (_, _) => const LoginScreen()),
      GoRoute(path: HomeShell.path, builder: (_, _) => const HomeShell()),
    ],
  );
});

/// Bridges a [Stream] to a [Listenable] so go_router re-evaluates redirects on auth changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
