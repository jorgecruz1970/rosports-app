import '../../domain/entities/match_entity.dart';

class MatchModel {
  const MatchModel({
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
  final String status;
  final String? levelMin;
  final String? levelMax;
  final bool isPublic;
  final String signupPolicy;
  final String? venueName;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final court = json['courts'] as Map<String, dynamic>? ?? {};
    final venue = court['venues'] as Map<String, dynamic>? ?? {};
    final sport = json['sports'] as Map<String, dynamic>? ??
        (court['sports'] as Map<String, dynamic>? ?? {});

    return MatchModel(
      id: json['id'] as String,
      creatorUserId: json['creator_user_id'] as String,
      courtId: json['court_id'] as String,
      courtName: court['name'] as String? ?? 'Cancha',
      sportName: sport['name'] as String? ?? '',
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      spotsTotal: json['spots_total'] as int,
      spotsTaken: (json['spots_taken'] as int?) ?? 0,
      pricePerPlayer: (json['price_per_player'] as num).toDouble(),
      status: json['status'] as String? ?? 'open',
      levelMin: json['level_min'] as String?,
      levelMax: json['level_max'] as String?,
      isPublic: (json['is_public'] as bool?) ?? true,
      signupPolicy: json['signup_policy'] as String? ?? 'auto',
      venueName: venue['name'] as String?,
    );
  }

  MatchEntity toEntity() => MatchEntity(
        id: id,
        creatorUserId: creatorUserId,
        courtId: courtId,
        courtName: courtName,
        sportName: sportName,
        startTime: startTime,
        endTime: endTime,
        spotsTotal: spotsTotal,
        spotsTaken: spotsTaken,
        pricePerPlayer: pricePerPlayer,
        status: _parseStatus(status),
        levelMin: levelMin,
        levelMax: levelMax,
        isPublic: isPublic,
        signupPolicy: signupPolicy,
        venueName: venueName,
      );

  static MatchStatus _parseStatus(String s) {
    switch (s) {
      case 'full':
        return MatchStatus.full;
      case 'cancelled':
        return MatchStatus.cancelled;
      case 'completed':
        return MatchStatus.completed;
      default:
        return MatchStatus.open;
    }
  }
}
