import '../entities/court_entity.dart';

/// Contrato del repositorio de canchas
abstract class CourtRepository {
  /// Listar canchas con filtros opcionales
  Future<List<CourtEntity>> getCourts({
    String? cityId,
    String? sportId,
    DateTime? date,
    String? timeSlot,
  });

  /// Detalle de una cancha por ID
  Future<CourtEntity> getCourtById(String courtId);

  /// Slots disponibles para una cancha en un rango de fechas
  Future<List<AvailabilitySlot>> getAvailability({
    required String courtId,
    required DateTime start,
    required DateTime end,
  });
}

/// Representa un slot de disponibilidad horaria
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.priceOverride,
  });

  final String id;
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;
  final double? priceOverride;

  bool get isAvailable => status == SlotStatus.available;
}

enum SlotStatus { available, booked, blocked }
