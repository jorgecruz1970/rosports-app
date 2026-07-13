import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/env.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/court_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reservation_provider.dart';

class BookingSummaryScreen extends ConsumerWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final court = ref.watch(selectedCourtProvider);
    final slot = ref.watch(selectedSlotProvider);
    final reservationState = ref.watch(reservationNotifierProvider);

    if (court == null || slot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resumen de reserva')),
        body: const Center(child: Text('No hay cancha o slot seleccionado')),
      );
    }

    final commission = court.pricePerHour * AppConstants.commissionRate;
    final total = court.pricePerHour + commission;
    final dateFmt = DateFormat('EEEE d \'de\' MMMM yyyy', 'es_CO');
    final timeFmt = DateFormat('HH:mm');
    final moneyFmt = NumberFormat('#,###', 'es_CO');

    // Manejar errores de reserva
    ref.listen(reservationNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear reserva: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        },
      );
    });

    // Manejar errores de pago
    ref.listen(paymentNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al iniciar pago: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de reserva')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de cancha
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports_soccer,
                        color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(court.displayName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(court.venueName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detalles de la reserva
            const Text('Detalle de tu reserva',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Fecha',
              value: dateFmt.format(slot.startTime),
            ),
            _DetailRow(
              label: 'Horario',
              value:
                  '${timeFmt.format(slot.startTime)} – ${timeFmt.format(slot.endTime)}',
            ),
            _DetailRow(label: 'Deporte', value: court.sportName),
            const Divider(height: 28),
            _DetailRow(
              label: 'Precio cancha',
              value: '\$${moneyFmt.format(court.pricePerHour)} COP',
            ),
            _DetailRow(
              label: 'Comisión servicio (10%)',
              value: '\$${moneyFmt.format(commission)} COP',
              subtle: true,
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                Text('\$${moneyFmt.format(total)} COP',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ],
            ),

            const Spacer(),

            // Aviso política de cancelación
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancelación gratuita hasta 24h antes. '
                      'Pasado ese plazo puede aplicar penalización.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botón reservar + pago
            ElevatedButton.icon(
              onPressed: reservationState.isLoading
                  ? null
                  : () async {
                      // 1. Crear la reserva en estado pending (bloquea el slot)
                      final reservation = await ref
                          .read(reservationNotifierProvider.notifier)
                          .createReservation(
                            courtId: court.id,
                            slotId: slot.id,
                            startTime: slot.startTime,
                            endTime: slot.endTime,
                            pricePerHour: court.pricePerHour,
                          );

                      if (reservation == null || !context.mounted) return;

                      // Invalidar cache de disponibilidad para que el slot aparezca como ocupado
                      ref.invalidate(courtAvailabilityStreamProvider(court.id));
                      ref.invalidate(myReservationsProvider);

                      // En sandbox (sin credenciales PayU), ir directo a confirmación
                      if (Env.payuApiKey.isEmpty || Env.isSandbox) {
                        ref.read(reservationNotifierProvider.notifier).reset();
                        context.go(AppRoutes.bookingConfirm);
                        return;
                      }

                      // 2. En producción: iniciar pago con PayU
                      final profile = ref.read(profileProvider).valueOrNull;
                      final email = profile?.email ??
                          ref.read(supabaseClientProvider).auth.currentUser?.email ?? '';
                      final name = profile?.name ?? 'Usuario';

                      final payResult = await ref
                          .read(paymentNotifierProvider.notifier)
                          .initiatePayment(
                            reservationId: reservation.id,
                            amount: total,
                            currency: 'COP',
                            description:
                                '${court.displayName} - ${timeFmt.format(slot.startTime)}',
                            buyerEmail: email,
                            buyerName: name,
                          );

                      if (!context.mounted) return;

                      if (payResult != null) {
                        // Abrir WebView de PayU
                        context.push(AppRoutes.paymentWebview, extra: {
                          'checkoutUrl': payResult.redirectUrl,
                          'paymentId': payResult.paymentId,
                        });
                      } else {
                        // Si el pago falla, ir a confirmación igual
                        ref.read(reservationNotifierProvider.notifier).reset();
                        context.go(AppRoutes.bookingConfirm);
                      }
                    },
              icon: reservationState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(reservationState.isLoading
                  ? 'Procesando...'
                  : 'Confirmar reserva — \$${moneyFmt.format(total)} COP'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                Env.payuApiKey.isEmpty
                    ? 'El pago online se habilitará próximamente'
                    : 'Pago seguro procesado por PayU',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.label, required this.value, this.subtle = false});
  final String label;
  final String value;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: subtle ? Colors.grey : Colors.black87,
                  fontSize: subtle ? 13 : 15)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: subtle ? Colors.grey : Colors.black,
                  fontSize: subtle ? 13 : 15)),
        ],
      ),
    );
  }
}
