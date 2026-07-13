import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/court_repository_impl.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/repositories/court_repository.dart';
import 'auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final courtRepositoryProvider = Provider<CourtRepository>((ref) {
  return CourtRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Filtros activos ───────────────────────────────────────────────────────────

class CourtFilters {
  const CourtFilters({this.sportId, this.cityId, this.date});
  final String? sportId;
  final String? cityId;
  final DateTime? date;

  CourtFilters copyWith({
    String? sportId,
    String? cityId,
    DateTime? date,
    bool clearSport = false,
    bool clearCity = false,
  }) =>
      CourtFilters(
        sportId: clearSport ? null : (sportId ?? this.sportId),
        cityId: clearCity ? null : (cityId ?? this.cityId),
        date: date ?? this.date,
      );
}

final courtFiltersProvider =
    StateProvider<CourtFilters>((ref) => const CourtFilters());

// ── Listado de canchas ────────────────────────────────────────────────────────

final courtsProvider =
    FutureProvider.family<List<CourtEntity>, CourtFilters>((ref, filters) {
  final repo = ref.watch(courtRepositoryProvider);
  return repo.getCourts(
    cityId: filters.cityId,
    sportId: filters.sportId,
    date: filters.date,
  );
});

// ── Detalle de cancha ─────────────────────────────────────────────────────────

final courtDetailProvider =
    FutureProvider.family<CourtEntity, String>((ref, courtId) {
  final repo = ref.watch(courtRepositoryProvider);
  return repo.getCourtById(courtId);
});

// ── Disponibilidad de una cancha (2 semanas desde hoy) ───────────────────────

final courtAvailabilityProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>((ref, courtId) {
  final repo = ref.watch(courtRepositoryProvider);
  final now = DateTime.now();
  return repo.getAvailability(
    courtId: courtId,
    start: now,
    end: now.add(const Duration(days: 14)),
  );
});

// ── Stream Realtime de disponibilidad ────────────────────────────────────────

final courtAvailabilityStreamProvider =
    StreamProvider.family<List<AvailabilitySlot>, String>((ref, courtId) {
  final repo = ref.watch(courtRepositoryProvider) as CourtRepositoryImpl;
  final now = DateTime.now();
  return repo.watchAvailability(
    courtId: courtId,
    start: now,
    end: now.add(const Duration(days: 14)),
  );
});

// ── Slot seleccionado para reserva ───────────────────────────────────────────

final selectedSlotProvider = StateProvider<AvailabilitySlot?>((ref) => null);
final selectedCourtProvider = StateProvider<CourtEntity?>((ref) => null);
