import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen del día',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _MetricCard(
                        label: 'Reservas hoy',
                        value: '8',
                        icon: Icons.calendar_today,
                        color: AppTheme.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _MetricCard(
                        label: 'Ingresos hoy',
                        value: '\$960K',
                        icon: Icons.attach_money,
                        color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _MetricCard(
                        label: 'Ocupación',
                        value: '80%',
                        icon: Icons.sports_soccer,
                        color: Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _MetricCard(
                        label: 'No-shows',
                        value: '1',
                        icon: Icons.warning_amber_outlined,
                        color: Colors.red)),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Reservas de hoy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(
                4,
                (i) => _BookingRow(
                      time: '${18 + i}:00 – ${19 + i}:00',
                      player: 'Jugador ${i + 1}',
                      court: 'Cancha ${(i % 2) + 1}',
                      status: i == 1 ? 'no_show' : 'confirmed',
                    )),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ]),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow(
      {required this.time,
      required this.player,
      required this.court,
      required this.status});
  final String time, player, court, status;

  @override
  Widget build(BuildContext context) {
    final isNoShow = status == 'no_show';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.access_time,
            color: isNoShow ? Colors.red : AppTheme.primary),
        title: Text('$player — $court'),
        subtitle: Text(time),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isNoShow ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isNoShow ? 'No-show' : 'Confirmada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isNoShow ? Colors.red : Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
