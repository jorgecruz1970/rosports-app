import '../entities/payment_entity.dart';

/// Contrato del repositorio de pagos
abstract class PaymentRepository {
  /// Iniciar un pago para una reserva — retorna URL de redirect PayU
  Future<PaymentInitResult> initiatePayment({
    required String reservationId,
    required double amount,
    required String currency,
    required String description,
    required String buyerEmail,
    required String buyerName,
  });

  /// Consultar estado de un pago
  Future<PaymentEntity> getPaymentStatus(String paymentId);

  /// Listar pagos del usuario autenticado
  Future<List<PaymentEntity>> getMyPayments();
}

/// Resultado de iniciar un pago
class PaymentInitResult {
  const PaymentInitResult({
    required this.paymentId,
    required this.redirectUrl,
  });

  /// ID interno del registro de pago
  final String paymentId;

  /// URL de PayU para abrir en WebView
  final String redirectUrl;
}
