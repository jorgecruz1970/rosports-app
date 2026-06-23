/// Centraliza el acceso a variables de entorno.
/// Inyectadas en compilación con --dart-define-from-file=.env
class Env {
  Env._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const String sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  static const String payuApiKey =
      String.fromEnvironment('PAYU_API_KEY', defaultValue: '');

  static const String payuMerchantId =
      String.fromEnvironment('PAYU_MERCHANT_ID', defaultValue: '');

  static const String payuEnv =
      String.fromEnvironment('PAYU_ENV', defaultValue: 'sandbox');

  static const String environment =
      String.fromEnvironment('ENV', defaultValue: 'development');

  static bool get isProduction => environment == 'production';
  static bool get isSandbox => payuEnv == 'sandbox';
}
