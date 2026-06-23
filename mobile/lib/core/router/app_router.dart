import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/courts/courts_screen.dart';
import '../../presentation/screens/courts/court_detail_screen.dart';
import '../../presentation/screens/booking/booking_summary_screen.dart';
import '../../presentation/screens/booking/booking_confirmation_screen.dart';
import '../../presentation/screens/matches/matches_screen.dart';
import '../../presentation/screens/matches/match_detail_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/splash_screen.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const splash          = '/';
  static const login           = '/login';
  static const register        = '/register';
  static const forgotPassword  = '/forgot-password';
  static const home            = '/home';
  static const courts          = '/courts';
  static const courtDetail     = '/courts/:id';
  static const bookingSummary  = '/booking/summary';
  static const bookingConfirm  = '/booking/confirmation';
  static const matches         = '/matches';
  static const matchDetail     = '/matches/:id';
  static const profile         = '/profile';
  static const admin           = '/admin';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: AppRoutes.splash,         builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,          builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,       builder: (c, s) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.home,           builder: (c, s) => const HomeScreen()),
      GoRoute(path: AppRoutes.courts,         builder: (c, s) => const CourtsScreen()),
      GoRoute(
        path: AppRoutes.courtDetail,
        builder: (c, s) => CourtDetailScreen(courtId: s.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.bookingSummary, builder: (c, s) => const BookingSummaryScreen()),
      GoRoute(path: AppRoutes.bookingConfirm, builder: (c, s) => const BookingConfirmationScreen()),
      GoRoute(path: AppRoutes.matches,        builder: (c, s) => const MatchesScreen()),
      GoRoute(
        path: AppRoutes.matchDetail,
        builder: (c, s) => MatchDetailScreen(matchId: s.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.profile, builder: (c, s) => const ProfileScreen()),
      GoRoute(path: AppRoutes.admin,   builder: (c, s) => const AdminDashboardScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
}
