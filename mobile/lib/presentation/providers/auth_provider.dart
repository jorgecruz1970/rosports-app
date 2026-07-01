import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ── Supabase client provider ──────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ── Repository provider ───────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Auth state (sesión activa) ────────────────────────────────────────────

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Notifier para operaciones de auth ─────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthRepository _repo;

  void _init() {
    final user = _repo.currentUser;
    state = AsyncValue.data(user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.register(email: email, password: password, name: name),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.login(email: email, password: password),
    );
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.loginWithGoogle());
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.loginWithApple());
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> requestPasswordReset(String email) async {
    await _repo.requestPasswordReset(email);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
