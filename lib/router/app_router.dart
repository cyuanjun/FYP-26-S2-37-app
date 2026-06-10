import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../boundaries/gateways/auth_gateway.dart';
import '../boundaries/ui/home/home_screen.dart';
import '../boundaries/ui/splash/splash_screen.dart';

/// App router. Role-based redirects (free/premium/expert/admin) land here as the
/// vertical slice grows — for now it gates only on auth presence.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authGatewayProvider);

  return GoRouter(
    initialLocation: SplashScreen.path,
    routes: [
      GoRoute(
        path: SplashScreen.path,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: HomeScreen.path,
        builder: (context, state) => const HomeScreen(),
      ),
      // TODO(vertical-slice): /login, /record, /history, /summary, /social
    ],
    redirect: (context, state) {
      // Splash is always allowed; auth-aware redirects arrive with the login route.
      if (state.matchedLocation == SplashScreen.path) return null;
      return auth.isSignedIn ? null : null; // placeholder: no login route yet
    },
  );
});
