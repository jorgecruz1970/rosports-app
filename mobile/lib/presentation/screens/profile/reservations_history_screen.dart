import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/reservation_entity.dart';
import '../../providers/reservation_provider.dart';

class ReservationsHistoryScreen extends ConsumerStatefulWidget {
  const ReservationsHistoryScreen({super.key});

  @override
  ConsumerState<ReservationsHistoryScreen> createState() =>
      _ReservationsHistoryScreenState();
}

class _ReservationsHistoryScreenState
    extends ConsumerState<ReservationsHistoryScreen> {
  ReservationStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(myReservationsProvider);
    final dateFmt = DateFormat('EEE d MMM — HH:mm', 'es_CO');
    final moneyFmt = NumberFormat('#,###', 'es_CO');

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de reservas')),
      body: Column(
        children: [
          // Filtros
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _buildChip(null, 'Todas'),
                _buildChip(ReservationStatus.pending, 'Pendientes'),
                _buildChip(ReservationStatus.confirmed, 'Confirmadas'),
                _buildChip(ReservationStatus.cancelled, 'Canceladas'),
                _buildChip(ReservationStatus.completed, 'Completadas'),
              ],
            ),
          ),
          Expanded(
            child: reservationsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reservations) {
                final filtered = _statusFilter == null
                    ? reservations
                    : reservations.where((r) => r.status == _statusFilter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _statusFilter == null
                              ? 'No tienes reservas'
                              : 'No hay reservas con este estado',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () async => ref.invalidate(myReservationsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      return _ReservationCard(
                        reservation: r,
                        dateFmt: dateFmt,
                        moneyFmt: moneyFmt,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(ReservationStatus? status, String label) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _statusFilter = status),
        selectedColor: AppTheme.primary.withOpacity(0.15),
        checkmarkColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.dateFmt,
    required this.moneyFmt,
  });
  final ReservationEntity reservation;
  final DateFormat dateFmt;
  final NumberFormat moneyFmt;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (reservation.status) {
      case ReservationStatus.confirmed:
        statusColor = Colors.green;
        statusLabel = 'Confirmada';
        break;
      case ReservationStatus.cancelled:
        statusColor = Colors.red;
        statusLabel = 'Cancelada';
        break;
      case ReservationStatus.completed:
        statusColor = Colors.blue;
        statusLabel = 'Completada';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Pendiente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reservation.courtName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(dateFmt.format(reservation.startTime),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text('\$${moneyFmt.format(reservation.totalAmount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
