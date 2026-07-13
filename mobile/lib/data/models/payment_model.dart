import '../../domain/entities/payment_entity.dart';

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.status,
    this.providerPaymentId,
    this.matchId,
    this.refundedAt,
    this.createdAt,
  });

  final String id;
  final String reservationId;
  final String userId;
  final String provider;
  final double amount;
  final String currency;
  final String status;
  final String? providerPaymentId;
  final String? matchId;
  final DateTime? refundedAt;
  final DateTime? createdAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        reservationId: json['reservation_id'] as String? ?? '',
        userId: json['user_id'] as String,
        provider: json['provider'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'COP',
        status: json['status'] as String? ?? 'initiated',
        providerPaymentId: json['provider_payment_id'] as String?,
        matchId: json['match_id'] as String?,
        refundedAt: json['refunded_at'] != null
            ? DateTime.parse(json['refunded_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  PaymentEntity toEntity() => PaymentEntity(
        id: id,
        reservationId: reservationId,
        userId: userId,
        provider: provider,
        amount: amount,
        currency: currency,
        status: _parseStatus(status),
        providerPaymentId: providerPaymentId,
        createdAt: createdAt,
      );

  static PaymentStatus _parseStatus(String s) {
    switch (s) {
      case 'authorized':
        return PaymentStatus.authorized;
      case 'captured':
        return PaymentStatus.captured;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.initiated;
    }
  }
}
