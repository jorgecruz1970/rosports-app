import 'package:equatable/equatable.dart';

/// Entidad de dominio — Pago
class PaymentEntity extends Equatable {
  const PaymentEntity({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.status,
    this.providerPaymentId,
    this.createdAt,
  });

  final String id;
  final String reservationId;
  final String userId;
  final String provider;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? providerPaymentId;
  final DateTime? createdAt;

  bool get isPaid =>
      status == PaymentStatus.authorized || status == PaymentStatus.captured;

  bool get isFailed => status == PaymentStatus.failed;

  @override
  List<Object?> get props => [id, reservationId, status];
}

enum PaymentStatus { initiated, authorized, captured, refunded, failed }
