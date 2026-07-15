import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_provider.dart';

typedef ProfileState = AsyncValue<UserEntity>;

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._client, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId.isNotEmpty) loadProfile();
  }

  final SupabaseClient _client;
  final String _userId;

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final data = await _client
          .from(AppConstants.tableProfiles)
          .select()
          .eq('id', _userId)
          .maybeSingle();

      if (data == null) {
        final authUser = _client.auth.currentUser;
        if (authUser != null) {
          state =
              AsyncValue.data(UserModel.fromSupabaseUser(authUser).toEntity());
        } else {
          state = const AsyncValue.error(
              'No se encontró el perfil', StackTrace.empty);
        }
        return;
      }

      state = AsyncValue.data(
        UserModel.fromJson({
          ...data,
          'email': _client.auth.currentUser?.email ?? '',
        }).toEntity(),
      );
    } catch (e, st) {
      state = AsyncValue.error('Error al cargar el perfil: $e', st);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    PlayerLevel? level,
  }) async {
    if (state.valueOrNull == null) return;
    try {
      await _client.from(AppConstants.tableProfiles).update({
        'updated_at': DateTime.now().toIso8601String(),
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (level != null) 'level': level.name,
      }).eq('id', _userId);

      await loadProfile();
    } catch (e, st) {
      state = AsyncValue.error('Error al actualizar el perfil: $e', st);
    }
  }
}

/// Provider del perfil — se recrea automáticamente cuando el usuario cambia
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  // Escuchar cambios de auth para recrear el provider
  final authState = ref.watch(authNotifierProvider);
  final userId = client.auth.currentUser?.id ?? '';
  return ProfileNotifier(client, userId);
});
