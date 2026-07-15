import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/reservation_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reservation_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (user) => _ProfileContent(user: user),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});
  final UserEntity user;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  String _levelLabel(PlayerLevel? level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 'Principiante';
      case PlayerLevel.intermediate:
        return 'Intermedio';
      case PlayerLevel.advanced:
        return 'Avanzado';
      case null:
        return 'Sin nivel';
    }
  }

  void _showAllReservations(
      BuildContext context, List<ReservationEntity> reservations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Mis reservas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${reservations.length} total',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: reservations.length,
                itemBuilder: (_, i) =>
                    _ReservationTile(reservation: reservations[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(myReservationsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: AppTheme.secondary,
            padding: const EdgeInsets.symmetric(
                vertical: 32, horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person,
                          color: Colors.white, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? 'Usuario' : user.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _levelLabel(user.level),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      user.points.toString(),
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'pts',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Email
          Container(
            color: Colors.grey.shade100,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.email_outlined,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(user.email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Stats
          reservationsAsync.when(
            loading: () => Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(value: '...', label: 'Reservas'),
                  _StatItem(value: '0', label: 'Tarjetas'),
                  _StatItem(value: '0', label: 'Partidos'),
                ],
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (reservations) {
              final confirmed = reservations
                  .where((r) =>
                      r.status == ReservationStatus.confirmed ||
                      r.status == ReservationStatus.completed)
                  .length;
              return Container(
                color: Colors.grey.shade50,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                        value: reservations.length.toString(),
                        label: 'Reservas'),
                    _StatItem(
                        value: confirmed.toString(),
                        label: 'Confirmadas'),
                    const _StatItem(value: '0', label: 'Tarjetas'),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Mis reservas expandidas
          reservationsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (reservations) {
              if (reservations.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text('Mis reservas',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...reservations
                      .take(3)
                      .map((r) => _ReservationTile(reservation: r)),
                  if (reservations.length > 3)
                    TextButton(
                      onPressed: () => _showAllReservations(context, reservations),
                      child: Text(
                          'Ver todas (${reservations.length})',
                          style: const TextStyle(
                              color: AppTheme.primary)),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),

          // Opciones
          _ProfileOption(
            icon: Icons.edit_outlined,
            label: 'Editar perfil',
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          _ProfileOption(
            icon: Icons.sports_soccer_outlined,
            label: 'Mis partidos',
            onTap: () => context.push(AppRoutes.myMatches),
          ),
          _ProfileOption(
            icon: Icons.notifications_outlined,
            label: 'Notificaciones',
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _ProfileOption(
            icon: Icons.payment_outlined,
            label: 'Historial de pagos',
            onTap: () => context.push(AppRoutes.paymentHistory),
          ),
          _ProfileOption(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de privacidad',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Próximamente: rosports.app/privacidad')),
            ),
          ),
          // Admin — solo visible para court_admin y super_admin
          if (user.role == UserRole.courtAdmin ||
              user.role == UserRole.superAdmin)
            _ProfileOption(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Panel administrador',
              onTap: () => context.push(AppRoutes.admin),
            ),
          const Divider(),
          _ProfileOption(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            color: Colors.red,
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}

class _ReservationTile extends ConsumerWidget {
  const _ReservationTile({required this.reservation});
  final ReservationEntity reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt =
        DateFormat('EEE d MMM — HH:mm', 'es_CO');
    final moneyFmt = NumberFormat('#,###', 'es_CO');

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

    final canCancel = reservation.status == ReservationStatus.pending ||
        reservation.status == ReservationStatus.confirmed;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.sports_soccer,
            color: AppTheme.primary, size: 20),
      ),
      title: Text(reservation.courtName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle:
          Text(dateFmt.format(reservation.startTime)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${moneyFmt.format(reservation.totalAmount)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      onLongPress: canCancel
          ? () => _showCancelDialog(context, ref)
          : null,
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final hoursUntil =
        reservation.startTime.difference(DateTime.now()).inHours;
    final isFree = hoursUntil >= 24;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar reserva?'),
        content: Text(
          isFree
              ? 'Cancelación gratuita (faltan más de 24h).\n'
                'El slot será liberado para otros jugadores.'
              : '⚠️ Faltan menos de 24h — puede aplicar penalización '
                'según la política de la cancha.\n'
                '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(reservationNotifierProvider.notifier)
          .cancelReservation(reservation.id);
      ref.invalidate(myReservationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada. Slot liberado.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primary),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
