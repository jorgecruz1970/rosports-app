import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/court_repository.dart';
import '../../providers/auth_provider.dart';

/// Provider de todos los slots de una cancha
final adminSlotsProvider = FutureProvider.autoDispose
    .family<List<AvailabilitySlot>, String>((ref, courtId) async {
  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final end = now.add(const Duration(days: 30));

  final data = await client
      .from(AppConstants.tableSlots)
      .select()
      .eq('court_id', courtId)
      .gte('start_time', now.toUtc().toIso8601String())
      .lte('start_time', end.toUtc().toIso8601String())
      .order('start_time');

  return data
      .map((j) => AvailabilitySlot(
            id: j['id'] as String,
            courtId: j['court_id'] as String,
            startTime: DateTime.parse(j['start_time'] as String).toLocal(),
            endTime: DateTime.parse(j['end_time'] as String).toLocal(),
            status: _parseStatus(j['status'] as String? ?? 'available'),
          ))
      .toList();
});

SlotStatus _parseStatus(String s) {
  switch (s) {
    case 'booked':
      return SlotStatus.booked;
    case 'blocked':
      return SlotStatus.blocked;
    default:
      return SlotStatus.available;
  }
}

class ManageSlotsScreen extends ConsumerStatefulWidget {
  const ManageSlotsScreen({super.key, required this.courtId, required this.courtName});
  final String courtId;
  final String courtName;

  @override
  ConsumerState<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends ConsumerState<ManageSlotsScreen> {
  DateTime? _selectedDate;
  bool _isProcessing = false;

  Future<void> _toggleSlot(AvailabilitySlot slot) async {
    if (slot.status == SlotStatus.booked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes modificar un slot con reserva activa')),
      );
      return;
    }

    final newStatus = slot.status == SlotStatus.blocked ? 'available' : 'blocked';
    final action = slot.status == SlotStatus.blocked ? 'desbloquear' : 'bloquear';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿${action[0].toUpperCase()}${action.substring(1)} slot?'),
        content: Text(
          '${DateFormat('HH:mm').format(slot.startTime)} – ${DateFormat('HH:mm').format(slot.endTime)}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action.toUpperCase(),
                style: TextStyle(color: newStatus == 'blocked' ? AppTheme.error : Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from(AppConstants.tableSlots)
          .update({'status': newStatus})
          .eq('id', slot.id);
      ref.invalidate(adminSlotsProvider(widget.courtId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Slot ${newStatus == 'blocked' ? 'bloqueado' : 'desbloqueado'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(adminSlotsProvider(widget.courtId));
    final dateFmt = DateFormat('EEE d MMM', 'es_CO');
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('Slots — ${widget.courtName}')),
      body: slotsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (slots) {
          if (slots.isEmpty) {
            return const Center(child: Text('No hay slots configurados'));
          }

          // Obtener fechas únicas
          final dates = <DateTime>{};
          for (final slot in slots) {
            dates.add(DateTime(slot.startTime.year, slot.startTime.month, slot.startTime.day));
          }
          final sortedDates = dates.toList()..sort();

          // Si no hay fecha seleccionada, usar la primera
          final activeDate = _selectedDate ?? sortedDates.first;

          // Filtrar slots de la fecha activa
          final daySlots = slots.where((s) {
            final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
            return d == activeDate;
          }).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          return Column(
            children: [
              // Selector de fechas horizontal
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: sortedDates.length,
                  itemBuilder: (_, i) {
                    final date = sortedDates[i];
                    final isActive = date == activeDate;
                    final daySlotCount = slots.where((s) {
                      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
                      return d == date;
                    }).length;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE', 'es_CO').format(date).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : Colors.grey,
                              ),
                            ),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '$daySlotCount slots',
                              style: TextStyle(
                                fontSize: 9,
                                color: isActive ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Header de la fecha
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      dateFmt.format(activeDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(),
                    Text('${daySlots.length} slots',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const Divider(),

              // Lista de slots del día
              Expanded(
                child: daySlots.isEmpty
                    ? const Center(child: Text('Sin slots para esta fecha'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: daySlots.length,
                        itemBuilder: (_, i) => _SlotTile(
                          slot: daySlots[i],
                          timeFmt: timeFmt,
                          onTap: _isProcessing ? null : () => _toggleSlot(daySlots[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.timeFmt, required this.onTap});
  final AvailabilitySlot slot;
  final DateFormat timeFmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (slot.status) {
      case SlotStatus.available:
        bgColor = Colors.green.shade50;
        textColor = Colors.green;
        icon = Icons.check_circle_outline;
        label = 'Disponible';
        break;
      case SlotStatus.booked:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue;
        icon = Icons.event_busy;
        label = 'Reservado';
        break;
      case SlotStatus.blocked:
        bgColor = Colors.red.shade50;
        textColor = Colors.red;
        icon = Icons.block;
        label = 'Bloqueado';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: bgColor,
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          '${timeFmt.format(slot.startTime)} – ${timeFmt.format(slot.endTime)}',
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold)),
        ),
        onTap: onTap,
      ),
    );
  }
}
