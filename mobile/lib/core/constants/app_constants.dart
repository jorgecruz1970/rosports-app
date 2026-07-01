/// Constantes globales de la aplicación
class AppConstants {
  AppConstants._();

  // Comisión ROSports Año 1
  static const double commissionRate = 0.10;

  // Tiempo máximo de bloqueo de slot durante checkout (minutos)
  static const int slotLockMinutes = 10;

  // Versión mínima de la app
  static const String appVersion = '1.0.0';

  // Tabla names — Supabase
  static const String tableProfiles       = 'profiles';
  static const String tableVenues         = 'venues';
  static const String tableCourts         = 'courts';
  static const String tableSlots          = 'availability_slots';
  static const String tableReservations   = 'reservations';
  static const String tablePayments       = 'payments';
  static const String tableMatches        = 'matches';
  static const String tableMatchSignups   = 'match_signups';
  static const String tableNotifications  = 'notifications';
  static const String tableUserTokens     = 'user_tokens';
  static const String tableSports         = 'sports';
  static const String tableCities         = 'cities';
  static const String tableCourtPolicies  = 'court_policies';

  // Storage buckets
  static const String bucketAvatars = 'avatars';
  static const String bucketCourts  = 'court-photos';

  // Shared preferences keys
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefThemeMode      = 'theme_mode';
}
