import 'package:equatable/equatable.dart';

/// Entidad de dominio — Partido abierto
class MatchEntity extends Equatable {
  const MatchEntity({
    required this.id,
    required this.creatorUserId,
    required this.courtId,
    required this.courtName,
    required this.sportName,
    required this.startTime,
    required this.endTime,
    required this.spotsTotal,
    required this.spotsTaken,
    required this.pricePerPlayer,
    required this.status,
    this.levelMin,
    this.levelMax,
    this.isPublic = true,
    this.signupPolicy = 'auto',
    this.venueName,
  });

  final String id;
  final String creatorUserId;
  final String courtId;
  final String courtName;
  final String sportName;
  final DateTime startTime;
  final DateTime endTime;
  final int spotsTotal;
  final int spotsTaken;
  final double pricePerPlayer;
  final MatchStatus status;
  final String? levelMin;
  final String? levelMax;
  final bool isPublic;
  final String signupPolicy;
  final String? venueName;

  int get spotsAvailable => spotsTotal - spotsTaken;
  bool get isFull => spotsTaken >= spotsTotal;
  bool get isOpen => status == MatchStatus.open;

  @override
  List<Object?> get props => [id, courtId, startTime, status];
}

enum MatchStatus { open, full, cancelled, completed }
