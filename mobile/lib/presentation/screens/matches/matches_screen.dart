import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partidos abiertos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // TODO: crear partido
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Crear partido'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (ctx, i) => _MatchCard(
          sport: 'Fútbol 5',
          venue: 'Complejo Deportivo Norte',
          date: 'Viernes 27 Jun — 19:00',
          spotsAvailable: i + 1,
          spotsTotal: 10,
          pricePerPlayer: 13200,
          onTap: () => context.push('/matches/match-$i'),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.sport, required this.venue, required this.date,
    required this.spotsAvailable, required this.spotsTotal,
    required this.pricePerPlayer, required this.onTap,
  });

  final String sport, venue, date;
  final int spotsAvailable, spotsTotal;
  final double pricePerPlayer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(sport, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Spacer(),
                  Text('\$${pricePerPlayer.toStringAsFixed(0)} / jugador',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(venue, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (spotsTotal - spotsAvailable) / spotsTotal,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text('$spotsAvailable plazas disponibles de $spotsTotal',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
