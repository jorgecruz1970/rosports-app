import '../../domain/entities/reservation_entity.dart';

class ReservationModel {
  const ReservationModel({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.commission,
    required this.netAmount,
    required this.status,
    this.currency = 'COP',
    this.paymentId,
  });

  final String id;
  final String courtId;
  final String courtName;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalAmount;
  final double commission;
  final double netAmount;
  final String status;
  final String currency;
  final String? paymentId;

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final court = json['courts'] as Map<String, dynamic>? ?? {};
    final venue = court['venues'] as Map<String, dynamic>? ?? {};
    final courtName = court['name'] as String? ??
        (venue['name'] as String? ?? 'Cancha');

    return ReservationModel(
      id: json['id'] as String,
      courtId: json['court_id'] as String,
      courtName: courtName,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      currency: json['currency'] as String? ?? 'COP',
      paymentId: json['payment_id'] as String?,
    );
  }

  ReservationEntity toEntity() => ReservationEntity(
        id: id,
        courtId: courtId,
        courtName: courtName,
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        totalAmount: totalAmount,
        status: _parseStatus(status),
        paymentId: paymentId,
      );

  static ReservationStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'completed':
        return ReservationStatus.completed;
      default:
        return ReservationStatus.pending;
    }
  }
}
