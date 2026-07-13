import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import 'auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ── Notifier para iniciar pago ───────────────────────────────────────────────

class PaymentNotifier extends StateNotifier<AsyncValue<PaymentInitResult?>> {
  PaymentNotifier(this._repo) : super(const AsyncValue.data(null));

  final PaymentRepository _repo;

  Future<PaymentInitResult?> initiatePayment({
    required String reservationId,
    required double amount,
    required String currency,
    required String description,
    required String buyerEmail,
    required String buyerName,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _repo.initiatePayment(
          reservationId: reservationId,
          amount: amount,
          currency: currency,
          description: description,
          buyerEmail: buyerEmail,
          buyerName: buyerName,
        ));
    state = result;
    return result.valueOrNull;
  }

  void reset() => state = const AsyncValue.data(null);
}

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<PaymentInitResult?>>(
  (ref) => PaymentNotifier(ref.watch(paymentRepositoryProvider)),
);

// ── Estado del pago (polling después del WebView) ────────────────────────────

final paymentStatusProvider =
    FutureProvider.family<PaymentEntity, String>((ref, paymentId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentStatus(paymentId);
});
