import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/auth_session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import 'app_routes.dart';
import 'deep_link_coordinator.dart';

final deepLinkCoordinatorProvider = Provider<DeepLinkCoordinator>((ref) {
  return DeepLinkCoordinator();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.onDispose(refresh.dispose);
  ref.listen<AuthSessionState>(authSessionControllerProvider, (_, next) {
    refresh.notify();
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, routerState) {
      final auth = ref.read(authSessionControllerProvider);
      final location = routerState.matchedLocation;
      final isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;

      return switch (auth.status) {
        AuthSessionStatus.restoring =>
          location == AppRoutes.splash ? null : AppRoutes.splash,
        AuthSessionStatus.unauthenticated =>
          isAuthRoute ? null : AppRoutes.login,
        AuthSessionStatus.authenticated =>
          location == AppRoutes.splash || isAuthRoute ? AppRoutes.home : null,
      };
    },
  );
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
