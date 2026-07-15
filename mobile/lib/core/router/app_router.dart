import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/create_court_screen.dart';
import '../../presentation/screens/admin/create_venue_screen.dart';
import '../../presentation/screens/admin/generate_slots_screen.dart';
import '../../presentation/screens/admin/manage_slots_screen.dart';
import '../../presentation/screens/admin/my_venues_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/booking/booking_confirmation_screen.dart';
import '../../presentation/screens/booking/booking_summary_screen.dart';
import '../../presentation/screens/courts/court_detail_screen.dart';
import '../../presentation/screens/courts/courts_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/matches/create_match_screen.dart';
import '../../presentation/screens/matches/match_detail_screen.dart';
import '../../presentation/screens/matches/matches_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/payment/payment_result_screen.dart';
import '../../presentation/screens/payment/payment_webview_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/my_matches_screen.dart';
import '../../presentation/screens/profile/payment_history_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/splash_screen.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const courts = '/courts';
  static const courtDetail = '/courts/:id';
  static const bookingSummary = '/booking/summary';
  static const bookingConfirm = '/booking/confirmation';
  static const matches = '/matches';
  static const matchDetail = '/matches/:id';
  static const createMatch = '/matches/create';
  static const paymentWebview = '/payment/webview';
  static const paymentResult = '/payment/result';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const myMatches = '/profile/matches';
  static const paymentHistory = '/profile/payments';
  static const notifications = '/notifications';
  static const admin = '/admin';
  static const adminSlots = '/admin/slots';
  static const adminVenues = '/admin/venues';
  static const adminCreateVenue = '/admin/venues/create';
  static const adminCreateCourt = '/admin/courts/create';
  static const adminGenerateSlots = '/admin/slots/generate';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // Redirige según sesión activa de Supabase
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding;

      if (!isAuth && !isOnAuthRoute) return AppRoutes.login;
      // Solo redirigir a home si la sesión NO ha expirado
      if (isAuth && state.matchedLocation == AppRoutes.login) {
        // Verificar que la sesión no esté expirada
        final expiresAt = session.expiresAt;
        if (expiresAt != null &&
            DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
                .isAfter(DateTime.now())) {
          return AppRoutes.home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (c, s) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.home, builder: (c, s) => const HomeScreen()),
      GoRoute(path: AppRoutes.courts, builder: (c, s) => const CourtsScreen()),
      GoRoute(
        path: AppRoutes.courtDetail,
        builder: (c, s) => CourtDetailScreen(courtId: s.pathParameters['id']!),
      ),
      GoRoute(
          path: AppRoutes.bookingSummary,
          builder: (c, s) => const BookingSummaryScreen()),
      GoRoute(
          path: AppRoutes.bookingConfirm,
          builder: (c, s) => const BookingConfirmationScreen()),
      GoRoute(
          path: AppRoutes.matches, builder: (c, s) => const MatchesScreen()),
      GoRoute(
        path: AppRoutes.createMatch,
        builder: (c, s) => const CreateMatchScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchDetail,
        builder: (c, s) => MatchDetailScreen(matchId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.paymentWebview,
        builder: (c, s) {
          final extra = s.extra as Map<String, String>;
          return PaymentWebViewScreen(
            checkoutUrl: extra['checkoutUrl']!,
            paymentId: extra['paymentId']!,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentResult,
        builder: (c, s) => PaymentResultScreen(
          paymentId: s.uri.queryParameters['paymentId'] ?? '',
        ),
      ),
      GoRoute(
          path: AppRoutes.profile, builder: (c, s) => const ProfileScreen()),
      GoRoute(
          path: AppRoutes.editProfile,
          builder: (c, s) => const EditProfileScreen()),
      GoRoute(
          path: AppRoutes.myMatches,
          builder: (c, s) => const MyMatchesScreen()),
      GoRoute(
          path: AppRoutes.paymentHistory,
          builder: (c, s) => const PaymentHistoryScreen()),
      GoRoute(
          path: AppRoutes.notifications,
          builder: (c, s) => const NotificationsScreen()),
      GoRoute(
          path: AppRoutes.admin,
          builder: (c, s) => const AdminDashboardScreen()),
      GoRoute(
        path: AppRoutes.adminSlots,
        builder: (c, s) {
          final extra = s.extra as Map<String, String>;
          return ManageSlotsScreen(
            courtId: extra['courtId']!,
            courtName: extra['courtName']!,
          );
        },
      ),
      GoRoute(
          path: AppRoutes.adminVenues,
          builder: (c, s) => const MyVenuesScreen()),
      GoRoute(
          path: AppRoutes.adminCreateVenue,
          builder: (c, s) => const CreateVenueScreen()),
      GoRoute(
        path: AppRoutes.adminCreateCourt,
        builder: (c, s) {
          final extra = s.extra as Map<String, String>;
          return CreateCourtScreen(
            venueId: extra['venueId']!,
            venueName: extra['venueName']!,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminGenerateSlots,
        builder: (c, s) {
          final extra = s.extra as Map<String, dynamic>;
          final courts = extra['courts'] as List<dynamic>;
          return GenerateSlotsScreen(courts: courts.cast<Map<String, dynamic>>());
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
}
