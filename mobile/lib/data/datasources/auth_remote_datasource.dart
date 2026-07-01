import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

/// Excepciones tipadas para errores de autenticación.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

/// Excepción para errores de red o servicio no disponible.
class NetworkAuthException extends AuthException {
  const NetworkAuthException()
      : super('Sin conexión. Verifica tu internet.', code: 'network_error');
}

/// Datasource remoto — toda la comunicación con Supabase Auth.
/// Solo conoce modelos (UserModel), nunca entidades de dominio directamente.
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final SupabaseClient _client;

  // ── Registro ─────────────────────────────────────────────────────────────────
  /// Registra un nuevo usuario con email, contraseña y nombre completo.
  /// Lanza [AuthException] si Supabase devuelve un error.
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'No se pudo crear la cuenta. Intenta de nuevo.',
          code: 'signup_null_user',
        );
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseMessage(e.message), code: e.statusCode?.toString());
    } catch (e) {
      throw AuthException('Error inesperado: ${e.toString()}', code: 'unknown');
    }
  }

  // ── Login con email ──────────────────────────────────────────────────────────
  /// Inicia sesión con email y contraseña.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'No se pudo iniciar sesión. Intenta de nuevo.',
          code: 'signin_null_user',
        );
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseMessage(e.message), code: e.statusCode?.toString());
    } catch (e) {
      throw AuthException('Error inesperado: ${e.toString()}', code: 'unknown');
    }
  }

  // ── Login con Google ─────────────────────────────────────────────────────────
  /// Inicia el flujo OAuth con Google.
  /// En mobile usa el plugin google_sign_in; aquí delegamos al OAuth de Supabase.
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'rosports://auth/callback',
      );
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseMessage(e.message), code: e.statusCode?.toString());
    } catch (e) {
      throw AuthException('Error con Google Sign In: ${e.toString()}', code: 'google_error');
    }
  }

  // ── Login con Apple ──────────────────────────────────────────────────────────
  /// Inicia el flujo OAuth con Apple (solo iOS).
  Future<void> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'rosports://auth/callback',
      );
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseMessage(e.message), code: e.statusCode?.toString());
    } catch (e) {
      throw AuthException('Error con Apple Sign In: ${e.toString()}', code: 'apple_error');
    }
  }

  // ── Cerrar sesión ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      // Ignorar errores de signOut para no bloquear al usuario
    }
  }

  // ── Reset de contraseña ──────────────────────────────────────────────────────
  /// Envía un email de recuperación de contraseña.
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'rosports://auth/reset-password',
      );
    } on AuthApiException catch (e) {
      throw AuthException(_mapSupabaseMessage(e.message), code: e.statusCode?.toString());
    } catch (e) {
      throw AuthException('Error al enviar el correo: ${e.toString()}', code: 'reset_error');
    }
  }

  // ── Usuario actual ───────────────────────────────────────────────────────────
  /// Retorna el usuario autenticado actualmente, o null si no hay sesión.
  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabaseUser(user);
  }

  // ── Stream de cambios de autenticación ───────────────────────────────────────
  /// Stream que emite el usuario cuando cambia el estado de sesión.
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return UserModel.fromSupabaseUser(user);
    });
  }

  // ── Mapeo de mensajes de Supabase a español ──────────────────────────────────
  String _mapSupabaseMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesión';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Ya existe una cuenta con ese email';
    }
    if (lower.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (lower.contains('rate limit')) {
      return 'Demasiados intentos. Espera unos minutos';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Error de conexión. Verifica tu internet';
    }
    // Retornar el mensaje original si no hay traducción
    return message;
  }
}
