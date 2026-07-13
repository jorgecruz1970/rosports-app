import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/court_entity.dart';
import '../../../domain/repositories/court_repository.dart';
import '../../providers/court_provider.dart';

class CourtDetailScreen extends ConsumerWidget {
  const CourtDetailScreen({super.key, required this.courtId});
  final String courtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtAsync = ref.watch(courtDetailProvider(courtId));
    final slotsAsync = ref.watch(courtAvailabilityStreamProvider(courtId));

    return courtAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (court) => _CourtDetailContent(
        court: court,
        slotsAsync: slotsAsync,
      ),
    );
  }
}

class _CourtDetailContent extends ConsumerWidget {
  const _CourtDetailContent({
    required this.court,
    required this.slotsAsync,
  });
  final CourtEntity court;
  final AsyncValue<List<AvailabilitySlot>> slotsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,###', 'es_CO');
    final dateFmt = DateFormat('EEE d MMM', 'es_CO');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar con imagen
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(court.displayName,
                  style: const TextStyle(fontSize: 14)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.secondary,
                      AppTheme.primary.withOpacity(0.7)
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.sports_soccer,
                      size: 80, color: Colors.white54),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sede y ubicación
                  Text(court.venueName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  if (court.address != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(court.address!,
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 16),

                  // Características
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                          icon: Icons.sports_soccer,
                          label: court.sportName),
                      if (court.hasLights)
                        const _InfoChip(
                            icon: Icons.wb_incandescent_outlined,
                            label: 'Con iluminación'),
                      if (court.surfaceType != null)
                        _InfoChip(
                            icon: Icons.grass,
                            label: court.surfaceType!),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Precio
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Precio por hora',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        Text(
                          '\$${fmt.format(court.pricePerHour)} COP',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Disponibilidad
                  const Text('Horarios disponibles',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Viernes, sábados y domingos',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),

                  slotsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            color: AppTheme.primary),
                      ),
                    ),
                    error: (e, _) => Text('Error al cargar slots: $e'),
                    data: (slots) {
                      if (slots.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No hay horarios disponibles\npara las próximas 2 semanas',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        );
                      }

                      // Agrupar slots por fecha
                      final byDate = <String, List<AvailabilitySlot>>{};
                      for (final slot in slots) {
                        final key = DateFormat('yyyy-MM-dd')
                            .format(slot.startTime);
                        byDate.putIfAbsent(key, () => []).add(slot);
                      }

                      return Column(
                        children: byDate.entries.map((entry) {
                          final date = DateTime.parse(entry.key);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  dateFmt.format(date).toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      letterSpacing: 0.8),
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: entry.value
                                    .map((slot) => _SlotChip(
                                          slot: slot,
                                          court: court,
                                          onTap: slot.isAvailable
                                              ? () {
                                                  ref
                                                      .read(
                                                          selectedSlotProvider
                                                              .notifier)
                                                      .state = slot;
                                                  ref
                                                      .read(
                                                          selectedCourtProvider
                                                              .notifier)
                                                      .state = court;
                                                  context.push(
                                                      AppRoutes
                                                          .bookingSummary);
                                                }
                                              : null,
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.court,
    required this.onTap,
  });
  final AvailabilitySlot slot;
  final CourtEntity court;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final isAvailable = slot.isAvailable;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isAvailable) {
      bgColor = AppTheme.primary.withOpacity(0.1);
      borderColor = AppTheme.primary;
      textColor = AppTheme.primary;
    } else if (slot.status == SlotStatus.booked) {
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey;
    } else {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade300;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeFmt.format(slot.startTime),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 15),
            ),
            Text(
              isAvailable ? 'Disponible' : (slot.status == SlotStatus.booked ? 'Ocupado' : 'Bloqueado'),
              style: TextStyle(fontSize: 10, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
