import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class CourtDetailScreen extends StatelessWidget {
  const CourtDetailScreen({super.key, required this.courtId});
  final String courtId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Cancha 1 - Fútbol 5'),
              background: Container(
                color: AppTheme.primary.withOpacity(0.3),
                child: const Center(child: Icon(Icons.sports_soccer, size: 80, color: Colors.white)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Complejo Deportivo Norte — Calle 127 #15-40, Bogotá')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.sports_soccer, label: 'Fútbol 5'),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.wb_incandescent_outlined, label: 'Con luz'),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.grass, label: 'Grama sint.'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Horarios disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Grid de slots — TODO: conectar con Supabase Realtime
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.5),
                    itemCount: 6,
                    itemBuilder: (ctx, i) {
                      final times = ['18:00', '19:00', '20:00', '21:00', '22:00', '23:00'];
                      final available = i != 1 && i != 4;
                      return GestureDetector(
                        onTap: available ? () => context.push(AppRoutes.bookingSummary) : null,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: available ? AppTheme.primary.withOpacity(0.1) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: available ? AppTheme.primary : Colors.grey.shade300),
                          ),
                          child: Text(
                            times[i],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: available ? AppTheme.primary : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Precio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('\$120.000 COP / hora',
                      style: TextStyle(fontSize: 20, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14, color: Colors.grey.shade600), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))],
      ),
    );
  }
}
