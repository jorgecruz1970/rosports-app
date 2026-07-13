import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/court_entity.dart';
import '../../providers/court_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/reservation_provider.dart';

/// Pantalla para crear un partido abierto.
/// Flujo: el usuario ya reservó una cancha → desde confirmación puede
/// "abrir el partido" → se divide el costo entre los jugadores inscritos.
class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  int _spotsTotal = 10;
  String _levelMin = 'beginner';
  String _levelMax = 'advanced';
  bool _isPublic = true;

  @override
  Widget build(BuildContext context) {
    final court = ref.watch(selectedCourtProvider);
    final slot = ref.watch(selectedSlotProvider);
    final matchState = ref.watch(matchNotifierProvider);

    if (court == null || slot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear partido')),
        body: const Center(
          child: Text(
            'Primero reserva una cancha para abrir un partido.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final pricePerPlayer = court.pricePerHour / _spotsTotal;
    final moneyFmt = NumberFormat('#,###', 'es_CO');
    final dateFmt = DateFormat('EEEE d MMM — HH:mm', 'es_CO');

    ref.listen(matchNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (match) {
          if (match != null) {
            ref.read(matchNotifierProvider.notifier).reset();
            ref.invalidate(openMatchesProvider(null));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Partido creado! Los jugadores ya pueden unirse.'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Crear partido abierto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info de la cancha reservada
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(court.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(dateFmt.format(slot.startTime),
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Jugadores totales
            const Text('Jugadores totales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _spotsTotal > 2
                      ? () => setState(() => _spotsTotal--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.primary,
                ),
                Text('$_spotsTotal',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _spotsTotal < 22
                      ? () => setState(() => _spotsTotal++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Precio por jugador: \$${moneyFmt.format(pricePerPlayer)} COP',
                    style: const TextStyle(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nivel
            const Text('Nivel de juego',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _levelMin,
                    decoration: const InputDecoration(
                      labelText: 'Mínimo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'beginner', child: Text('Principiante')),
                      DropdownMenuItem(
                          value: 'intermediate', child: Text('Intermedio')),
                      DropdownMenuItem(
                          value: 'advanced', child: Text('Avanzado')),
                    ],
                    onChanged: (v) => setState(() => _levelMin = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _levelMax,
                    decoration: const InputDecoration(
                      labelText: 'Máximo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'beginner', child: Text('Principiante')),
                      DropdownMenuItem(
                          value: 'intermediate', child: Text('Intermedio')),
                      DropdownMenuItem(
                          value: 'advanced', child: Text('Avanzado')),
                    ],
                    onChanged: (v) => setState(() => _levelMax = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Público
            SwitchListTile(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              title: const Text('Partido público'),
              subtitle: const Text(
                'Cualquier jugador puede unirse desde la app',
              ),
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            // Resumen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Costo total cancha',
                    value: '\$${moneyFmt.format(court.pricePerHour)} COP',
                  ),
                  _SummaryRow(
                    label: 'Jugadores',
                    value: '$_spotsTotal',
                  ),
                  const Divider(),
                  _SummaryRow(
                    label: 'Cada jugador paga',
                    value: '\$${moneyFmt.format(pricePerPlayer)} COP',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón crear
            ElevatedButton.icon(
              onPressed: matchState.isLoading
                  ? null
                  : () async {
                      // Primero creamos la reserva
                      final reservation = await ref
                          .read(reservationNotifierProvider.notifier)
                          .createReservation(
                            courtId: court.id,
                            slotId: slot.id,
                            startTime: slot.startTime,
                            endTime: slot.endTime,
                            pricePerHour: court.pricePerHour,
                          );
                      if (reservation == null) return;

                      // Luego creamos el partido
                      await ref
                          .read(matchNotifierProvider.notifier)
                          .createMatch(
                            courtId: court.id,
                            sportId: court.sportId,
                            reservationId: reservation.id,
                            startTime: slot.startTime,
                            endTime: slot.endTime,
                            spotsTotal: _spotsTotal,
                            pricePerPlayer: pricePerPlayer,
                            levelMin: _levelMin,
                            levelMax: _levelMax,
                          );
                    },
              icon: matchState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sports),
              label: Text(matchState.isLoading
                  ? 'Creando...'
                  : 'Crear partido abierto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: bold ? AppTheme.primary : Colors.black87,
              )),
        ],
      ),
    );
  }
}
