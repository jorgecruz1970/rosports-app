import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

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
              icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(error.toString(),
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
      case PlayerLevel.beginner:     return 'Principiante';
      case PlayerLevel.intermediate: return 'Intermedio';
      case PlayerLevel.advanced:     return 'Avanzado';
      case null:                     return 'Sin nivel';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: AppTheme.secondary,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name.isEmpty ? 'Usuario' : user.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_levelLabel(user.level),
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(user.points.toString(),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('pts',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Email
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(user.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Stats
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(value: '—', label: 'Partidos'),
                _StatItem(value: '—', label: 'Reservas'),
                _StatItem(value: '0', label: 'Tarjetas'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ProfileOption(
            icon: Icons.calendar_today_outlined,
            label: 'Mis reservas',
            onTap: () {},
          ),
          _ProfileOption(
            icon: Icons.sports_soccer_outlined,
            label: 'Mis partidos',
            onTap: () {},
          ),
          _ProfileOption(
            icon: Icons.edit_outlined,
            label: 'Editar perfil',
            onTap: () {},
          ),
          _ProfileOption(
            icon: Icons.notifications_outlined,
            label: 'Notificaciones',
            onTap: () {},
          ),
          _ProfileOption(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de privacidad',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente: rosports.app/privacidad')),
            ),
          ),
          _ProfileOption(
            icon: Icons.help_outline,
            label: 'Ayuda y soporte',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente: soporte@rosports.app')),
            ),
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
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
