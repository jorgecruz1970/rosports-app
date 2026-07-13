import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/match_entity.dart';
import '../../providers/match_provider.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  String? _selectedSport;

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(openMatchesProvider(_selectedSport));

    return Scaffold(
      appBar: AppBar(title: const Text('Partidos abiertos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createMatch),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Crear partido'),
      ),
      body: Column(
        children: [
          // Filtros de deporte
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _buildChip(null, 'Todos'),
                _buildChip('22222222-0000-0000-0000-000000000001', 'Fútbol 5'),
                _buildChip('22222222-0000-0000-0000-000000000002', 'Fútbol 7'),
              ],
            ),
          ),
          Expanded(
            child: matchesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Error al cargar partidos: $e',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                          openMatchesProvider(_selectedSport)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No hay partidos abiertos',
                            style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        Text('¡Sé el primero en crear uno!',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () async => ref.invalidate(
                      openMatchesProvider(_selectedSport)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: matches.length,
                    itemBuilder: (_, i) => _MatchCard(
                      match: matches[i],
                      onTap: () =>
                          context.push('/matches/${matches[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String? sportId, String label) {
    final isSelected = _selectedSport == sportId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedSport = sportId),
        selectedColor: AppTheme.primary.withOpacity(0.15),
        checkmarkColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});
  final MatchEntity match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE d MMM — HH:mm', 'es_CO');
    final moneyFmt = NumberFormat('#,###', 'es_CO');

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(match.sportName,
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const Spacer(),
                  Text(
                    '\$${moneyFmt.format(match.pricePerPlayer)} / jugador',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (match.venueName != null)
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${match.courtName} — ${match.venueName}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dateFmt.format(match.startTime),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              if (match.levelMin != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.trending_up, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Nivel: ${match.levelMin}${match.levelMax != null ? ' – ${match.levelMax}' : '+'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ]),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: match.spotsTaken / match.spotsTotal,
                backgroundColor: Colors.grey.shade200,
                color: match.isFull ? Colors.orange : AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                match.isFull
                    ? 'Partido completo'
                    : '${match.spotsAvailable} plazas disponibles de ${match.spotsTotal}',
                style: TextStyle(
                  fontSize: 12,
                  color: match.isFull ? Colors.orange : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
