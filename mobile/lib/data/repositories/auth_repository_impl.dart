import 'package:supabase_flutter/supabase_flutter.dart'
    hide
        AuthException; // ocultar AuthException de supabase para usar la nuestra

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/profile_model.dart';

/// Implementación real del AuthRepository usando Supabase Auth
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;

  // ── Registro ──────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      final user = response.user;
      if (user == null) {
        throw const RoAuthException(
            'No se pudo crear la cuenta. Intenta de nuevo.');
      }

      await _supabase.from(AppConstants.tableProfiles).upsert({
        'id': user.id,
        'email': email,
        'name': name,
        'role': 'player',
      });

      return await _getProfile(user.id, email);
    } on RoAuthException {
      rethrow;
    } catch (e) {
      final code = _extractCode(e);
      throw RoAuthException(mapAuthError(code), code: code);
    }
  }

  // ── Login con email ───────────────────────────────────────────────────────

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      print('[AUTH] Attempting login with email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      print('[AUTH] Login response user: ${user?.id}');
      if (user == null)
        throw const RoAuthException('No se pudo iniciar sesión.');

      return await _getProfile(user.id, email);
    } on RoAuthException {
      rethrow;
    } catch (e) {
      print('[AUTH] Login error: $e');
      final code = _extractCode(e);
      throw RoAuthException(mapAuthError(code), code: code);
    }
  }

  // ── Login con Google ──────────────────────────────────────────────────────

  @override
  Future<UserEntity> loginWithGoogle() async {
    try {
      print('[AUTH] Starting Google OAuth...');
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'app.rosports.mobile://login-callback',
      );
      print('[AUTH] OAuth launched: $success');
      
      // signInWithOAuth abre el navegador — el flujo continúa vía deep link.
      // Esperamos a que onAuthStateChange detecte la sesión (máx 60s).
      final user = await _waitForAuthUser(timeout: const Duration(seconds: 60));
      if (user == null) {
        throw const RoAuthException('Login con Google cancelado o expirado.');
      }
      return await _getOrCreateProfile(user);
    } on RoAuthException {
      rethrow;
    } catch (e) {
      print('[AUTH] Google error: $e');
      throw RoAuthException('Error con Google: $e');
    }
  }

  // ── Login con Apple ───────────────────────────────────────────────────────

  @override
  Future<UserEntity> loginWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'app.rosports.mobile://login-callback',
      );
      
      final user = await _waitForAuthUser(timeout: const Duration(seconds: 60));
      if (user == null) {
        throw const RoAuthException('Login con Apple cancelado o expirado.');
      }
      return await _getOrCreateProfile(user);
    } on RoAuthException {
      rethrow;
    } catch (e) {
      throw RoAuthException('Error con Apple: $e');
    }
  }

  /// Espera a que el usuario se autentique vía OAuth (deep link callback)
  Future<User?> _waitForAuthUser({required Duration timeout}) async {
    // Si ya hay usuario (raro pero posible), retornar inmediatamente
    if (_supabase.auth.currentUser != null) {
      return _supabase.auth.currentUser;
    }

    // Escuchar cambios de auth hasta obtener un signedIn
    try {
      final event = await _supabase.auth.onAuthStateChange
          .where((e) => e.event == AuthChangeEvent.signedIn)
          .first
          .timeout(timeout);
      return event.session?.user;
    } catch (_) {
      // Timeout o error — usuario canceló o no volvió
      return null;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw RoAuthException('Error al cerrar sesión: $e');
    }
  }

  // ── Reset de contraseña ───────────────────────────────────────────────────

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'app.rosports.mobile://reset-password',
      );
    } catch (e) {
      final code = _extractCode(e);
      throw RoAuthException(mapAuthError(code), code: code);
    }
  }

  // ── Usuario actual ────────────────────────────────────────────────────────

  @override
  UserEntity? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return UserEntity(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String? ?? '',
    );
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String? ?? '',
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<UserEntity> _getProfile(String userId, String fallbackEmail) async {
    final data = await _supabase
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null)
      return UserEntity(id: userId, email: fallbackEmail, name: '');
    return ProfileModel.fromJson(data).toEntity();
  }

  Future<UserEntity> _getOrCreateProfile(User user) async {
    final existing = await _supabase
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) return ProfileModel.fromJson(existing).toEntity();

    final name = user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        user.email?.split('@').first ??
        'Usuario';

    await _supabase.from(AppConstants.tableProfiles).insert({
      'id': user.id,
      'email': user.email ?? '',
      'name': name,
      'role': 'player',
    });

    return UserEntity(id: user.id, email: user.email ?? '', name: name);
  }

  /// Extrae el code de error de excepciones de Supabase/GoTrue
  String _extractCode(Object e) {
    final str = e.toString();
    // AuthApiException tiene campo code — extraer con regex
    final match = RegExp(r'code[=:]\s*(\w+)').firstMatch(str);
    return match?.group(1) ?? '';
  }
}
