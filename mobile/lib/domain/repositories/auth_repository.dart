import '../entities/user_entity.dart';

/// Contrato del repositorio de autenticación.
/// La implementación real vive en data/repositories/
abstract class AuthRepository {
  /// Registrar nuevo usuario con email y contraseña
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
  });

  /// Login con email y contraseña
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  /// Login con Google
  Future<UserEntity> loginWithGoogle();

  /// Login con Apple
  Future<UserEntity> loginWithApple();

  /// Cerrar sesión
  Future<void> logout();

  /// Solicitar reset de contraseña
  Future<void> requestPasswordReset(String email);

  /// Usuario autenticado actualmente (null si no hay sesión)
  UserEntity? get currentUser;

  /// Stream de cambios de sesión
  Stream<UserEntity?> get authStateChanges;
}
