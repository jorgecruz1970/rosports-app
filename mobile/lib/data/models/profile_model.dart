import '../../domain/entities/user_entity.dart';

/// Modelo de datos — mapea fila de la tabla `profiles` en Supabase
class ProfileModel {
  const ProfileModel({
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        level: json['level'] as String?,
        points: (json['points'] as int?) ?? 0,
        role: (json['role'] as String?) ?? 'player',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'level': level,
        'points': points,
        'role': role,
      };

  /// Convierte a entidad de dominio
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
