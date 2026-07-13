import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';
import '../services/payu_service.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._supabase);
  final SupabaseClient _supabase;

  @override
  Future<PaymentInitResult> initiatePayment({
    required String reservationId,
    required double amount,
    required String currency,
    required String description,
    required String buyerEmail,
    required String buyerName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final paymentId = const Uuid().v4();
    final referenceCode = 'ROSP-$reservationId-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Crear registro de pago en estado initiated
    await _supabase.from(AppConstants.tablePayments).insert({
      'id': paymentId,
      'reservation_id': reservationId,
      'user_id': user.id,
      'provider': 'payu',
      'amount': amount,
      'currency': currency,
      'status': 'initiated',
      'raw_response': {'reference_code': referenceCode},
    });

    // 2. Actualizar reserva con el payment_id
    await _supabase
        .from(AppConstants.tableReservations)
        .update({'payment_id': paymentId})
        .eq('id', reservationId);

    // 3. Generar URL de checkout
    final redirectUrl = PayUService.buildCheckoutUrl(
      referenceCode: referenceCode,
      amount: amount,
      currency: currency,
      description: description,
      buyerEmail: buyerEmail,
      buyerName: buyerName,
    );

    return PaymentInitResult(
      paymentId: paymentId,
      redirectUrl: redirectUrl,
    );
  }

  @override
  Future<PaymentEntity> getPaymentStatus(String paymentId) async {
    final data = await _supabase
        .from(AppConstants.tablePayments)
        .select()
        .eq('id', paymentId)
        .single();

    return PaymentModel.fromJson(data).toEntity();
  }

  @override
  Future<List<PaymentEntity>> getMyPayments() async {
    final userId = _supabase.auth.currentUser!.id;

    final data = await _supabase
        .from(AppConstants.tablePayments)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((j) => PaymentModel.fromJson(j).toEntity()).toList();
  }
}
