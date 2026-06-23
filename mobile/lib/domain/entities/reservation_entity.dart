import 'package:equatable/equatable.dart';

/// Entidad de dominio — Reserva
class ReservationEntity extends Equatable {
  const ReservationEntity({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.status,
    this.paymentId,
  });

  final String id;
  final String courtId;
  final String courtName;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalAmount;
  final ReservationStatus status;
  final String? paymentId;

  /// Monto de comisión ROSports (10% Año 1)
  double get commission => totalAmount * 0.10;

  /// Monto neto para la cancha
  double get netAmount => totalAmount - commission;

  @override
  List<Object?> get props => [id, courtId, userId, startTime, status];
}

enum ReservationStatus { pending, confirmed, cancelled, completed }
