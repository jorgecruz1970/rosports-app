import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/court_entity.dart';
import '../../../domain/repositories/court_repository.dart';
import '../../providers/court_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/reservation_provider.dart';

/// Pantalla para crear un partido abierto.
/// Flujo independiente: seleccionar cancha → seleccionar slot → configurar partido → crear.
class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  // Paso actual del wizard
  int _step = 0; // 0: cancha, 1: slot, 2: configurar

  // Selecciones
  CourtEntity? _selectedCourt;
  AvailabilitySlot? _selectedSlot;

  // Config del partido
  int _spotsTotal = 10;
  String _levelMin = 'beginner';
  String _levelMax = 'advanced';
  bool _isPublic = true;

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchNotifierProvider);

    ref.listen(matchNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (match) {
          if (match != null) {
            ref.read(matchNotifierProvider.notifier).reset();
            ref.invalidate(openMatchesProvider(null));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('¡Partido creado! Los jugadores ya pueden unirse.'),
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
      appBar: AppBar(
        title: Text(_step == 0
            ? 'Selecciona cancha'
            : _step == 1
                ? 'Selecciona horario'
                : 'Configurar partido'),
      ),
      body: _step == 0
          ? _buildCourtSelection()
          : _step == 1
              ? _buildSlotSelection()
              : _buildMatchConfig(matchState),
    );
  }

  // ── Paso 1: Seleccionar cancha ─────────────────────────────────────────────

  Widget _buildCourtSelection() {
    final filters = ref.watch(courtFiltersProvider);
    final courtsAsync = ref.watch(courtsProvider(filters));

    return courtsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (courts) {
        if (courts.isEmpty) {
          return const Center(child: Text('No hay canchas disponibles'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courts.length,
          itemBuilder: (_, i) {
            final court = courts[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_soccer,
                      color: AppTheme.primary, size: 24),
                ),
                title: Text(court.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(court.venueName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedCourt = court;
                    _step = 1;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  // ── Paso 2: Seleccionar slot ───────────────────────────────────────────────

  Widget _buildSlotSelection() {
    final slotsAsync =
        ref.watch(courtAvailabilityStreamProvider(_selectedCourt!.id));
    final dateFmt = DateFormat('EEE d MMM', 'es_CO');
    final timeFmt = DateFormat('HH:mm');

    return slotsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (slots) {
        final available = slots.where((s) => s.isAvailable).toList();
        if (available.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay horarios disponibles\npara las próximas 2 semanas',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Agrupar por fecha
        final byDate = <String, List<AvailabilitySlot>>{};
        for (final slot in available) {
          final key = DateFormat('yyyy-MM-dd').format(slot.startTime);
          byDate.putIfAbsent(key, () => []).add(slot);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedCourt!.displayName} — ${_selectedCourt!.venueName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 16),
              ...byDate.entries.map((entry) {
                final date = DateTime.parse(entry.key);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        dateFmt.format(date).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((slot) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSlot = slot;
                              _step = 2;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primary),
                            ),
                            child: Text(
                              timeFmt.format(slot.startTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Paso 3: Configurar partido ─────────────────────────────────────────────

  Widget _buildMatchConfig(AsyncValue matchState) {
    final court = _selectedCourt!;
    final slot = _selectedSlot!;
    final pricePerPlayer = court.pricePerHour / _spotsTotal;
    final moneyFmt = NumberFormat('#,###', 'es_CO');
    final dateFmt = DateFormat('EEEE d MMM — HH:mm', 'es_CO');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info de la cancha y horario seleccionados
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
                  style:
                      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  '\$${moneyFmt.format(pricePerPlayer)} COP / jugador',
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
                    // Primero creamos la reserva (bloquea el slot)
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
            label: Text(
                matchState.isLoading ? 'Creando...' : 'Crear partido abierto'),
          ),
        ],
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
