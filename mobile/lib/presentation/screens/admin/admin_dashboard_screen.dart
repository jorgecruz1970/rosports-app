import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Datos del dashboard
class AdminStats {
  final int reservationsToday;
  final double incomeToday;
  final double occupancyRate;
  final int noShows;
  final List<Map<String, dynamic>> todayBookings;

  const AdminStats({
    required this.reservationsToday,
    required this.incomeToday,
    required this.occupancyRate,
    required this.noShows,
    required this.todayBookings,
  });
}

/// Provider de estadísticas admin
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  // Reservas de hoy
  final reservations = await client
      .from(AppConstants.tableReservations)
      .select('''
        id, court_id, user_id, start_time, end_time, total_amount, status,
        courts(name),
        profiles:user_id(name)
      ''')
      .gte('start_time', todayStart.toUtc().toIso8601String())
      .lt('start_time', todayEnd.toUtc().toIso8601String())
      .order('start_time');

  // Calcular métricas
  final totalReservations = reservations.length;
  final income = reservations.fold<double>(
      0, (sum, r) => sum + ((r['total_amount'] as num?)?.toDouble() ?? 0));
  final noShows =
      reservations.where((r) => r['status'] == 'no_show').length;

  // Total de slots hoy para calcular ocupación
  final totalSlots = await client
      .from(AppConstants.tableSlots)
      .select('id')
      .gte('start_time', todayStart.toUtc().toIso8601String())
      .lt('start_time', todayEnd.toUtc().toIso8601String());

  final totalSlotsCount = totalSlots.length;
  final bookedSlots = reservations
      .where((r) => r['status'] != 'cancelled')
      .length;
  final occupancy =
      totalSlotsCount > 0 ? (bookedSlots / totalSlotsCount) * 100 : 0.0;

  return AdminStats(
    reservationsToday: totalReservations,
    incomeToday: income,
    occupancyRate: occupancy,
    noShows: noShows,
    todayBookings: reservations,
  );
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final moneyFmt = NumberFormat('#,###', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Error: $e', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminStatsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async => ref.invalidate(adminStatsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen — ${DateFormat('EEEE d MMM', 'es_CO').format(DateTime.now())}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Reservas hoy',
                        value: '${stats.reservationsToday}',
                        icon: Icons.calendar_today,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Ingresos hoy',
                        value: '\$${moneyFmt.format(stats.incomeToday)}',
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Ocupación',
                        value: '${stats.occupancyRate.toStringAsFixed(0)}%',
                        icon: Icons.sports_soccer,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'No-shows',
                        value: '${stats.noShows}',
                        icon: Icons.warning_amber_outlined,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('Reservas de hoy',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (stats.todayBookings.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No hay reservas para hoy',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ),
                  )
                else
                  ...stats.todayBookings.map((booking) {
                    final court =
                        booking['courts'] as Map<String, dynamic>? ?? {};
                    final profile =
                        booking['profiles'] as Map<String, dynamic>? ?? {};
                    final startTime =
                        DateTime.parse(booking['start_time'] as String)
                            .toLocal();
                    final endTime =
                        DateTime.parse(booking['end_time'] as String)
                            .toLocal();
                    final timeFmt = DateFormat('HH:mm');
                    final status = booking['status'] as String? ?? 'pending';

                    return _BookingRow(
                      time:
                          '${timeFmt.format(startTime)} – ${timeFmt.format(endTime)}',
                      player: profile['name'] as String? ?? 'Jugador',
                      court: court['name'] as String? ?? 'Cancha',
                      status: status,
                    );
                  }),
                const SizedBox(height: 28),
                const Text('Gestión de canchas',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.adminVenues),
                  icon: const Icon(Icons.business),
                  label: const Text('Mis sedes y canchas'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.adminSlots, extra: {
                    'courtId': '44444444-0000-0000-0000-000000000001',
                    'courtName': 'Cancha 1 - Fútbol 5',
                  }),
                  icon: const Icon(Icons.calendar_view_day),
                  label: const Text('Gestionar slots — Cancha 1'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.adminSlots, extra: {
                    'courtId': '44444444-0000-0000-0000-000000000002',
                    'courtName': 'Cancha 2 - Fútbol 7',
                  }),
                  icon: const Icon(Icons.calendar_view_day),
                  label: const Text('Gestionar slots — Cancha 2'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({
    required this.time,
    required this.player,
    required this.court,
    required this.status,
  });
  final String time, player, court, status;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusLabel = 'Confirmada';
        break;
      case 'no_show':
        statusColor = Colors.red;
        statusLabel = 'No-show';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusLabel = 'Cancelada';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusLabel = 'Completada';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Pendiente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.access_time, color: statusColor),
        title: Text('$player — $court'),
        subtitle: Text(time),
        trailing: Container(
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
      ),
    );
  }
}
