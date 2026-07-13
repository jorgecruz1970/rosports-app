import '../entities/match_entity.dart';

/// Contrato del repositorio de partidos
abstract class MatchRepository {
  /// Listar partidos abiertos (públicos)
  Future<List<MatchEntity>> getOpenMatches({
    String? sportId,
    String? cityId,
  });

  /// Detalle de un partido
  Future<MatchEntity> getMatchById(String matchId);

  /// Crear partido abierto
  Future<MatchEntity> createMatch({
    required String courtId,
    required String sportId,
    required String reservationId,
    required DateTime startTime,
    required DateTime endTime,
    required int spotsTotal,
    required double pricePerPlayer,
    String? levelMin,
    String? levelMax,
    bool isPublic = true,
  });

  /// Inscribirse a un partido
  Future<void> joinMatch(String matchId);

  /// Cancelar inscripción
  Future<void> leaveMatch(String matchId);

  /// Cancelar partido (solo creador)
  Future<void> cancelMatch(String matchId);
}
