/// Excepción base de la aplicación
class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

/// Errores de autenticación — prefijado con Ro para evitar colisión con supabase_flutter
class RoAuthException extends AppException {
  const RoAuthException(super.message, {super.code});
}

/// Errores de red / Supabase
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Errores de validación
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Errores de pago
class PaymentException extends AppException {
  const PaymentException(super.message, {super.code});
}

/// Mapea errores de Supabase Auth a mensajes en español
String mapAuthError(String code) {
  switch (code) {
    case 'invalid_credentials':
      return 'Email o contraseña incorrectos';
    case 'email_not_confirmed':
      return 'Debes confirmar tu email antes de iniciar sesión';
    case 'user_already_exists':
      return 'Ya existe una cuenta con ese email';
    case 'weak_password':
      return 'La contraseña es muy débil. Usa al menos 6 caracteres';
    case 'email_address_invalid':
      return 'El formato del email no es válido';
    case 'over_email_send_rate_limit':
      return 'Demasiados intentos. Espera unos minutos e intenta de nuevo';
    case 'session_not_found':
      return 'Tu sesión expiró. Inicia sesión de nuevo';
    default:
      return 'Ocurrió un error inesperado. Intenta de nuevo';
  }
}
