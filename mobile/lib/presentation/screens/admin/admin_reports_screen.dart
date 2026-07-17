import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

final adminWeeklyReportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

  final reservations = await client
      .from(AppConstants.tableReservations)
      .select('id, total_amount, commission, status, created_at')
      .gte('created_at', weekStartDate.toUtc().toIso8601String())
      .order('created_at', ascending: false);

  final total = reservations.length;
  final confirmed = reservations.where((r) => r['status'] == 'confirmed').length;
  final cancelled = reservations.where((r) => r['status'] == 'cancelled').length;
  final pending = reservations.where((r) => r['status'] == 'pending').length;
  final income = reservations.fold<double>(
      0, (sum, r) => sum + ((r['total_amount'] as num?)?.toDouble() ?? 0));
  final commission = reservations.fold<double>(
      0, (sum, r) => sum + ((r['commission'] as num?)?.toDouble() ?? 0));

  return {
    'total': total,
    'confirmed': confirmed,
    'cancelled': cancelled,
    'pending': pending,
    'income': income,
    'commission': commission,
    'netIncome': income - commission,
    'weekStart': weekStartDate,
  };
});

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(adminWeeklyReportProvider);
    final moneyFmt = NumberFormat('#,###', 'es_CO');
    final dateFmt = DateFormat('d MMM', 'es_CO');

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: reportAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (report) {
          final weekStart = report['weekStart'] as DateTime;
          final weekEnd = weekStart.add(const Duration(days: 6));

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => ref.invalidate(adminWeeklyReportProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semana: ${dateFmt.format(weekStart)} — ${dateFmt.format(weekEnd)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Ingresos
                  _ReportCard(
                    title: 'Ingresos brutos',
                    value: '\$${moneyFmt.format(report['income'])}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                  _ReportCard(
                    title: 'Comisión ROSports (10%)',
                    value: '\$${moneyFmt.format(report['commission'])}',
                    icon: Icons.percent,
                    color: AppTheme.primary,
                  ),
                  _ReportCard(
                    title: 'Ingreso neto canchas',
                    value: '\$${moneyFmt.format(report['netIncome'])}',
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),

                  // Reservas
                  const Text('Reservas esta semana',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatBox(label: 'Total', value: '${report['total']}', color: Colors.grey),
                      _StatBox(label: 'Confirmadas', value: '${report['confirmed']}', color: Colors.green),
                      _StatBox(label: 'Pendientes', value: '${report['pending']}', color: Colors.orange),
                      _StatBox(label: 'Canceladas', value: '${report['cancelled']}', color: Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        trailing: Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
