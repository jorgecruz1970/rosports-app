import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double price = 120000;
    const double commission = price * 0.10;
    const double total = price + commission;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de reserva')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalle de tu reserva',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _DetailRow(label: 'Cancha', value: 'Cancha 1 - Fútbol 5'),
            _DetailRow(label: 'Sede', value: 'Complejo Deportivo Norte'),
            _DetailRow(label: 'Fecha', value: 'Viernes 27 Jun 2026'),
            _DetailRow(label: 'Horario', value: '19:00 – 20:00'),
            _DetailRow(label: 'Deporte', value: 'Fútbol 5'),
            const Divider(height: 32),
            _DetailRow(
                label: 'Precio cancha',
                value: '\$${price.toStringAsFixed(0)} COP'),
            _DetailRow(
              label: 'Comisión de servicio (10%)',
              value: '\$${commission.toStringAsFixed(0)} COP',
              subtle: true,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('\$${total.toStringAsFixed(0)} COP',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ],
            ),
            const Spacer(),
            // Política de cancelación
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
                          'Cancelación gratuita hasta 24h antes. Pasado ese plazo se aplica penalización.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.orange))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.bookingConfirm),
              icon: const Icon(Icons.payment),
              label: const Text('Proceder al pago'),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
