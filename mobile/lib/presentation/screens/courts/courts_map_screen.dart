import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/court_entity.dart';
import '../../providers/court_provider.dart';

/// Vista de mapa con las canchas como marcadores.
/// Usa una implementación simple con lista por proximidad
/// (Google Maps widget requiere API key configurada).
class CourtsMapScreen extends ConsumerWidget {
  const CourtsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(courtFiltersProvider);
    final courtsAsync = ref.watch(courtsProvider(filters));

    return Scaffold(
      appBar: AppBar(title: const Text('Canchas cerca de ti')),
      body: courtsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (courts) {
          final courtsWithLocation =
              courts.where((c) => c.lat != null && c.lng != null).toList();

          if (courtsWithLocation.isEmpty) {
            return const Center(
              child: Text('No hay canchas con ubicación disponible'),
            );
          }

          return Column(
            children: [
              // Mapa placeholder con info de ubicaciones
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            '${courtsWithLocation.length} canchas disponibles',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Toca una cancha para ver en Google Maps',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Pins simulados
                    ...courtsWithLocation.asMap().entries.map((entry) {
                      final i = entry.key;
                      final court = entry.value;
                      final left = 30.0 + (i * 60) % 300;
                      final top = 30.0 + (i * 40) % 140;
                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () => _openInMaps(court),
                          child: const Icon(Icons.location_on,
                              color: AppTheme.primary, size: 32),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Lista de canchas con distancia
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courtsWithLocation.length,
                  itemBuilder: (_, i) => _CourtLocationCard(
                    court: courtsWithLocation[i],
                    onTap: () =>
                        context.push('/courts/${courtsWithLocation[i].id}'),
                    onMap: () => _openInMaps(courtsWithLocation[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openInMaps(CourtEntity court) async {
    if (court.lat == null || court.lng == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${court.lat},${court.lng}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _CourtLocationCard extends StatelessWidget {
  const _CourtLocationCard({
    required this.court,
    required this.onTap,
    required this.onMap,
  });
  final CourtEntity court;
  final VoidCallback onTap;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'es_CO');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_soccer,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(court.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(court.venueName,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (court.address != null)
                      Text(court.address!,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('\$${moneyFmt.format(court.pricePerHour)}/h',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onMap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions,
                          color: Colors.blue, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
