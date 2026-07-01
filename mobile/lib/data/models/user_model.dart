import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../domain/entities/user_entity.dart';

/// Modelo que adapta tanto la tabla `profiles` como el objeto User de Supabase Auth
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.level,
    this.points = 0,
    this.role = 'player',
  });

  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? level;
  final int points;
  final String role;

  /// Desde JSON de la tabla profiles
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        level: json['level'] as String?,
        points: (json['points'] as int?) ?? 0,
        role: (json['role'] as String?) ?? 'player',
      );

  /// Desde objeto User de Supabase Auth (cuando el perfil aún no está en DB)
  factory UserModel.fromSupabaseUser(User user) => UserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String? ??
            user.userMetadata?['full_name'] as String? ??
            '',
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      );

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
        level: _parseLevel(level),
        points: points,
        role: _parseRole(role),
      );

  static PlayerLevel? _parseLevel(String? l) {
    switch (l) {
      case 'beginner':
        return PlayerLevel.beginner;
      case 'intermediate':
        return PlayerLevel.intermediate;
      case 'advanced':
        return PlayerLevel.advanced;
      default:
        return null;
    }
  }

  static UserRole _parseRole(String r) {
    switch (r) {
      case 'court_admin':
        return UserRole.courtAdmin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.player;
    }
  }
}
