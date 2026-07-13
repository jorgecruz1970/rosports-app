import '../entities/reservation_entity.dart';

/// Contrato del repositorio de reservas
abstract class ReservationRepository {
  /// Crear una reserva (estado inicial: pending)
  Future<ReservationEntity> createReservation({
    required String courtId,
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
    required double pricePerHour,
  });

  /// Obtener reservas del usuario autenticado
  Future<List<ReservationEntity>> getMyReservations();

  /// Cancelar una reserva
  Future<ReservationEntity> cancelReservation(String reservationId);

  /// Marcar no-show (solo admin)
  Future<ReservationEntity> markNoShow(String reservationId);
}
