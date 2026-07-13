import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../providers/payment_provider.dart';

/// Provider de historial de pagos
final paymentHistoryProvider = FutureProvider<List<PaymentEntity>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getMyPayments();
});

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pagos')),
      body: paymentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No tienes pagos registrados',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => ref.invalidate(paymentHistoryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (_, i) => _PaymentCard(payment: payments[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final PaymentEntity payment;

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'es_CO');
    final dateFmt = DateFormat('d MMM yyyy — HH:mm', 'es_CO');

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (payment.status) {
      case PaymentStatus.captured:
      case PaymentStatus.authorized:
        statusColor = Colors.green;
        statusLabel = 'Aprobado';
        statusIcon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
        statusColor = Colors.red;
        statusLabel = 'Rechazado';
        statusIcon = Icons.cancel;
        break;
      case PaymentStatus.refunded:
        statusColor = Colors.blue;
        statusLabel = 'Reembolsado';
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Pendiente';
        statusIcon = Icons.hourglass_top;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${moneyFmt.format(payment.amount)} ${payment.currency}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payment.createdAt != null
                        ? dateFmt.format(payment.createdAt!)
                        : 'Sin fecha',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
