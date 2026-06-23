import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header de perfil
            Container(
              color: AppTheme.secondary,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jorge Cruz', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Mediocampista • Intermedio', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text('120', style: TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('pts', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Stats rápidas
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(value: '24', label: 'Partidos'),
                  _StatItem(value: '12', label: 'Reservas'),
                  _StatItem(value: '0', label: 'Tarjetas'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Opciones
            _ProfileOption(icon: Icons.calendar_today_outlined, label: 'Mis reservas', onTap: () {}),
            _ProfileOption(icon: Icons.sports_soccer_outlined, label: 'Mis partidos', onTap: () {}),
            _ProfileOption(icon: Icons.edit_outlined, label: 'Editar perfil', onTap: () {}),
            _ProfileOption(icon: Icons.notifications_outlined, label: 'Notificaciones', onTap: () {}),
            _ProfileOption(icon: Icons.privacy_tip_outlined, label: 'Política de privacidad', onTap: () {}),
            _ProfileOption(icon: Icons.help_outline, label: 'Ayuda y soporte', onTap: () {}),
            const Divider(),
            _ProfileOption(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              color: Colors.red,
              onTap: () => context.go(AppRoutes.login),
            ),
          ],
        ),
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
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({required this.icon, required this.label, required this.onTap, this.color});
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
