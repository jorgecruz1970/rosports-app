import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservation_repository.dart';
import 'auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Mis reservas ─────────────────────────────────────────────────────────────

final myReservationsProvider =
    FutureProvider<List<ReservationEntity>>((ref) async {
  final repo = ref.watch(reservationRepositoryProvider);
  return repo.getMyReservations();
});

// ── Notifier para crear / cancelar reservas ──────────────────────────────────

class ReservationNotifier
    extends StateNotifier<AsyncValue<ReservationEntity?>> {
  ReservationNotifier(this._repo) : super(const AsyncValue.data(null));

  final ReservationRepository _repo;

  Future<ReservationEntity?> createReservation({
    required String courtId,
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
    required double pricePerHour,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _repo.createReservation(
          courtId: courtId,
          slotId: slotId,
          startTime: startTime,
          endTime: endTime,
          pricePerHour: pricePerHour,
        ));
    state = result;
    return result.valueOrNull;
  }

  Future<void> cancelReservation(String reservationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.cancelReservation(reservationId),
    );
  }

  void reset() => state = const AsyncValue.data(null);
}

final reservationNotifierProvider =
    StateNotifierProvider<ReservationNotifier, AsyncValue<ReservationEntity?>>(
  (ref) => ReservationNotifier(ref.watch(reservationRepositoryProvider)),
);
