import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/court_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/court_provider.dart';

/// Provider de todos los slots de una cancha (incluyendo bloqueados)
final adminSlotsProvider = FutureProvider.family<List<AvailabilitySlot>, String>(
    (ref, courtId) async {
  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final end = now.add(const Duration(days: 14));

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
  bool _isProcessing = false;

  Future<void> _toggleSlot(AvailabilitySlot slot) async {
    if (slot.status == SlotStatus.booked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes modificar un slot reservado')),
      );
      return;
    }

    final newStatus =
        slot.status == SlotStatus.blocked ? 'available' : 'blocked';
    final action =
        slot.status == SlotStatus.blocked ? 'desbloquear' : 'bloquear';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿${action.substring(0, 1).toUpperCase()}${action.substring(1)} slot?'),
        content: Text(
          'Slot: ${DateFormat('EEE d MMM HH:mm', 'es_CO').format(slot.startTime)}\n'
          'Acción: $action',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action.toUpperCase(),
                style: TextStyle(
                    color: newStatus == 'blocked'
                        ? AppTheme.error
                        : Colors.green)),
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
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (slots) {
          if (slots.isEmpty) {
            return const Center(child: Text('No hay slots configurados'));
          }

          // Agrupar por fecha
          final byDate = <String, List<AvailabilitySlot>>{};
          for (final slot in slots) {
            final key = DateFormat('yyyy-MM-dd').format(slot.startTime);
            byDate.putIfAbsent(key, () => []).add(slot);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: byDate.entries.map((entry) {
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
                  ...entry.value.map((slot) => _SlotTile(
                        slot: slot,
                        timeFmt: timeFmt,
                        onTap: _isProcessing ? null : () => _toggleSlot(slot),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.timeFmt,
    required this.onTap,
  });
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
        trailing: Text(label,
            style: TextStyle(
                fontSize: 12, color: textColor, fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }
}
