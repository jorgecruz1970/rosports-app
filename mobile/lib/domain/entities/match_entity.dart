import 'package:equatable/equatable.dart';

/// Entidad de dominio — Partido Abierto
class MatchEntity extends Equatable {
  const MatchEntity({
    required this.id,
    required this.creatorUserId,
    required this.sportId,
    required this.sportName,
    required this.startTime,
    required this.endTime,
    required this.spotsTotal,
    required this.spotsTaken,
    required this.isPublic,
    this.courtId,
    this.courtName,
    this.levelMin,
    this.levelMax,
    this.signupPolicy = MatchSignupPolicy.auto,
  });

  final String id;
  final String creatorUserId;
  final String sportId;
  final String sportName;
  final DateTime startTime;
  final DateTime endTime;
  final int spotsTotal;
  final int spotsTaken;
  final bool isPublic;
  final String? courtId;
  final String? courtName;
  final String? levelMin;
  final String? levelMax;
  final MatchSignupPolicy signupPolicy;

  int get spotsAvailable => spotsTotal - spotsTaken;
  bool get isFull => spotsAvailable == 0;

  @override
  List<Object?> get props => [id, creatorUserId, startTime, sportId];
}

enum MatchSignupPolicy { auto, manual }
