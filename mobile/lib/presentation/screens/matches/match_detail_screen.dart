import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Partido Fútbol 5',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _InfoRow(
                icon: Icons.location_on_outlined,
                text: 'Complejo Deportivo Norte — Bogotá'),
            _InfoRow(
                icon: Icons.access_time,
                text: 'Viernes 27 Jun 2026 — 19:00 – 20:00'),
            _InfoRow(
                icon: Icons.attach_money, text: '\$13.200 COP por jugador'),
            _InfoRow(
                icon: Icons.people_outline, text: '7 de 10 plazas ocupadas'),
            const SizedBox(height: 24),
            const Text('Jugadores inscritos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(
                7,
                (i) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text('J${i + 1}',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text('Jugador ${i + 1}'),
                      subtitle: Text([
                        'Portero',
                        'Defensa',
                        'Mediocampista',
                        'Delantero'
                      ][i % 4]),
                    )),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {}, // TODO: unirse al partido + pago
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Unirse al partido'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ]),
    );
  }
}
