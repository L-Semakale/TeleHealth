import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../features/admin/admin_shell.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screens.dart';
import '../features/landing/landing_screen.dart';
import '../features/patient/patient_shell.dart';
import '../features/provider/provider_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final user = auth.user;
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordPlaceholderScreen()),
      GoRoute(
        path: '/home',
        builder: (_, __) {
          if (user == null) return const LoginScreen();
          switch (user.role) {
            case UserRole.patient:
              return const PatientShell();
            case UserRole.provider:
              return const ProviderShell();
            case UserRole.admin:
              return const AdminShell();
          }
        },
      ),
    ],
    redirect: (_, state) {
      final path = state.uri.path;
      final isPublicRoute = path == '/' || path == '/login' || path == '/register' || path == '/forgot-password';
      if (user == null) return isPublicRoute ? null : '/login';
      if (isPublicRoute) return '/home';
      return null;
    },
  );
});
