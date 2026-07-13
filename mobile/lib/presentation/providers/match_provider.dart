import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/match_repository_impl.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/match_repository.dart';
import 'auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Listado de partidos abiertos ─────────────────────────────────────────────

final openMatchesProvider =
    FutureProvider.family<List<MatchEntity>, String?>((ref, sportId) {
  final repo = ref.watch(matchRepositoryProvider);
  return repo.getOpenMatches(sportId: sportId);
});

// ── Detalle de un partido ────────────────────────────────────────────────────

final matchDetailProvider =
    FutureProvider.family<MatchEntity, String>((ref, matchId) {
  final repo = ref.watch(matchRepositoryProvider);
  return repo.getMatchById(matchId);
});

// ── Notifier para crear/unirse/salir de partidos ─────────────────────────────

class MatchNotifier extends StateNotifier<AsyncValue<MatchEntity?>> {
  MatchNotifier(this._repo) : super(const AsyncValue.data(null));

  final MatchRepository _repo;

  Future<MatchEntity?> createMatch({
    required String courtId,
    required String sportId,
    required String reservationId,
    required DateTime startTime,
    required DateTime endTime,
    required int spotsTotal,
    required double pricePerPlayer,
    String? levelMin,
    String? levelMax,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _repo.createMatch(
          courtId: courtId,
          sportId: sportId,
          reservationId: reservationId,
          startTime: startTime,
          endTime: endTime,
          spotsTotal: spotsTotal,
          pricePerPlayer: pricePerPlayer,
          levelMin: levelMin,
          levelMax: levelMax,
        ));
    state = result;
    return result.valueOrNull;
  }

  Future<void> joinMatch(String matchId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.joinMatch(matchId);
      return _repo.getMatchById(matchId);
    });
  }

  Future<void> leaveMatch(String matchId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.leaveMatch(matchId);
      return _repo.getMatchById(matchId);
    });
  }

  void reset() => state = const AsyncValue.data(null);
}

final matchNotifierProvider =
    StateNotifierProvider<MatchNotifier, AsyncValue<MatchEntity?>>(
  (ref) => MatchNotifier(ref.watch(matchRepositoryProvider)),
);
