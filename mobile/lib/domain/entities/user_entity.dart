import 'package:equatable/equatable.dart';

/// Entidad de dominio — Usuario
/// No depende de ninguna capa externa (Supabase, JSON, etc.)
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.level,
    this.points = 0,
    this.role = UserRole.player,
  });

  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final PlayerLevel? level;
  final int points;
  final UserRole role;

  @override
  List<Object?> get props => [id, email, name, phone, avatarUrl, level, points, role];
}

enum PlayerLevel { beginner, intermediate, advanced }

enum UserRole { player, courtAdmin, superAdmin }
