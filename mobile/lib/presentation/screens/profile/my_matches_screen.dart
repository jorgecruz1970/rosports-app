import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/match_entity.dart';
import '../../providers/auth_provider.dart';

/// Provider para obtener partidos donde el usuario está inscrito
final myMatchesProvider = FutureProvider<List<MatchEntity>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  // Obtener match_ids donde estoy inscrito
  final signups = await client
      .from(AppConstants.tableMatchSignups)
      .select('match_id')
      .eq('user_id', userId)
      .eq('status', 'signed');

  if (signups.isEmpty) return [];

  final matchIds = signups.map((s) => s['match_id'] as String).toList();

  final data = await client
      .from(AppConstants.tableMatches)
      .select('''
        id, creator_user_id, court_id, sport_id, start_time, end_time,
        spots_total, spots_taken, price_per_player, level_min, level_max,
        is_public, signup_policy, status,
        courts(name, venues(name)),
        sports(name)
      ''')
      .inFilter('id', matchIds)
      .order('start_time', ascending: false);

  // Reuse MatchModel import
  return data.map((j) {
    final court = j['courts'] as Map<String, dynamic>? ?? {};
    final venue = court['venues'] as Map<String, dynamic>? ?? {};
    final sport = j['sports'] as Map<String, dynamic>? ?? {};

    return MatchEntity(
      id: j['id'] as String,
      creatorUserId: j['creator_user_id'] as String,
      courtId: j['court_id'] as String,
      courtName: court['name'] as String? ?? 'Cancha',
      sportName: sport['name'] as String? ?? '',
      startTime: DateTime.parse(j['start_time'] as String).toLocal(),
      endTime: DateTime.parse(j['end_time'] as String).toLocal(),
      spotsTotal: j['spots_total'] as int,
      spotsTaken: (j['spots_taken'] as int?) ?? 0,
      pricePerPlayer: (j['price_per_player'] as num).toDouble(),
      status: _parseStatus(j['status'] as String? ?? 'open'),
      levelMin: j['level_min'] as String?,
      levelMax: j['level_max'] as String?,
      isPublic: (j['is_public'] as bool?) ?? true,
      venueName: venue['name'] as String?,
    );
  }).toList();
});

MatchStatus _parseStatus(String s) {
  switch (s) {
    case 'full':
      return MatchStatus.full;
    case 'cancelled':
      return MatchStatus.cancelled;
    case 'completed':
      return MatchStatus.completed;
    default:
      return MatchStatus.open;
  }
}

class MyMatchesScreen extends ConsumerWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(myMatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis partidos')),
      body: matchesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No estás inscrito en ningún partido',
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Buscar partidos',
                        style: TextStyle(color: AppTheme.primary)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => ref.invalidate(myMatchesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (_, i) => _MyMatchCard(match: matches[i]),
            ),
          );
        },
      ),
    );
  }
}

class _MyMatchCard extends StatelessWidget {
  const _MyMatchCard({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE d MMM — HH:mm', 'es_CO');
    final moneyFmt = NumberFormat('#,###', 'es_CO');

    Color statusColor;
    String statusLabel;
    switch (match.status) {
      case MatchStatus.open:
        statusColor = Colors.green;
        statusLabel = 'Abierto';
        break;
      case MatchStatus.full:
        statusColor = Colors.orange;
        statusLabel = 'Completo';
        break;
      case MatchStatus.cancelled:
        statusColor = Colors.red;
        statusLabel = 'Cancelado';
        break;
      case MatchStatus.completed:
        statusColor = Colors.blue;
        statusLabel = 'Finalizado';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/matches/${match.id}'),
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                  const Spacer(),
                  Text('\$${moneyFmt.format(match.pricePerPlayer)} / jugador',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${match.sportName} — ${match.courtName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dateFmt.format(match.startTime),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: match.spotsTaken / match.spotsTotal,
                backgroundColor: Colors.grey.shade200,
                color: match.isFull ? Colors.orange : AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text('${match.spotsTaken}/${match.spotsTotal} jugadores',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
