import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class CourtsScreen extends StatelessWidget {
  const CourtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canchas disponibles'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar cancha...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          // Chips de deporte
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Todos', 'Fútbol 5', 'Fútbol 7', 'Pádel', 'Baloncesto']
                  .map((sport) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(sport),
                          selected: sport == 'Todos',
                          onSelected: (_) {},
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                          checkmarkColor: AppTheme.primary,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Lista de canchas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5, // TODO: reemplazar con datos reales de Supabase
              itemBuilder: (context, index) => _CourtCard(
                id: 'court-$index',
                name: 'Cancha ${index + 1} - Fútbol 5',
                venue: 'Complejo Deportivo Norte',
                price: 120000,
                sport: 'Fútbol 5',
                onTap: () => context.push('/courts/court-$index'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.id,
    required this.name,
    required this.venue,
    required this.price,
    required this.sport,
    required this.onTap,
  });

  final String id;
  final String name;
  final String venue;
  final double price;
  final String sport;
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
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_soccer,
                    color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(venue,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(sport,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(
                          '\$${price.toStringAsFixed(0)} COP/h',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
