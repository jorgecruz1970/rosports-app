import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/match_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';

/// Provider que verifica si el usuario actual está inscrito en un partido.
/// Usa un approach defensivo: consulta directa con user_id explícito.
final isSignedUpProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, matchId) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return false;

  try {
    final data = await client
        .from(AppConstants.tableMatchSignups)
        .select('id, user_id')
        .eq('match_id', matchId)
        .eq('status', 'signed');

    final mySignups = (data as List)
        .where((row) => row['user_id'] == userId)
        .toList();

    return mySignups.isNotEmpty;
  } catch (_) {
    return false;
  }
});

/// Provider para obtener la lista de jugadores inscritos
final matchPlayersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, matchId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final data = await client
        .from(AppConstants.tableMatchSignups)
        .select('''
          id, user_id, status, created_at,
          profiles:user_id(name, level, avatar_url)
        ''')
        .eq('match_id', matchId)
        .eq('status', 'signed')
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  } catch (_) {
    return [];
  }
});

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final matchAction = ref.watch(matchNotifierProvider);

    return matchAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (match) => _MatchDetailContent(
        match: match,
        isActioning: matchAction.isLoading,
      ),
    );
  }
}

class _MatchDetailContent extends ConsumerWidget {
  const _MatchDetailContent({
    required this.match,
    required this.isActioning,
  });
  final MatchEntity match;
  final bool isActioning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('EEEE d MMM yyyy', 'es_CO');
    final timeFmt = DateFormat('HH:mm');
    final moneyFmt = NumberFormat('#,###', 'es_CO');
    final currentUserId =
        ref.read(supabaseClientProvider).auth.currentUser?.id;
    final isCreator = currentUserId == match.creatorUserId;
    final isSignedUpAsync = ref.watch(isSignedUpProvider(match.id));

    ref.listen(matchNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (m) {
          if (m != null) {
            ref.invalidate(matchDetailProvider(match.id));
            ref.invalidate(openMatchesProvider(null));
            ref.invalidate(isSignedUpProvider(match.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Listo!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('${match.sportName} — ${match.courtName}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (match.venueName != null) ...[
              const SizedBox(height: 4),
              Text(match.venueName!,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
            const SizedBox(height: 16),

            _InfoRow(
              icon: Icons.calendar_today,
              text: dateFmt.format(match.startTime),
            ),
            _InfoRow(
              icon: Icons.access_time,
              text:
                  '${timeFmt.format(match.startTime)} – ${timeFmt.format(match.endTime)}',
            ),
            _InfoRow(
              icon: Icons.attach_money,
              text:
                  '\$${moneyFmt.format(match.pricePerPlayer)} COP por jugador',
            ),
            _InfoRow(
              icon: Icons.people_outline,
              text:
                  '${match.spotsTaken} de ${match.spotsTotal} plazas ocupadas',
            ),
            if (match.levelMin != null)
              _InfoRow(
                icon: Icons.trending_up,
                text:
                    'Nivel: ${_levelLabel(match.levelMin)} – ${_levelLabel(match.levelMax)}',
              ),
            const SizedBox(height: 20),

            // Barra de progreso
            LinearProgressIndicator(
              value: match.spotsTaken / match.spotsTotal,
              backgroundColor: Colors.grey.shade200,
              color: match.isFull ? Colors.orange : AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              match.isFull
                  ? '¡Partido completo!'
                  : '${match.spotsAvailable} plazas disponibles',
              style: TextStyle(
                color: match.isFull ? Colors.orange : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(match.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(match.status),
                style: TextStyle(
                  color: _statusColor(match.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Jugadores inscritos
            const Text('Jugadores inscritos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _PlayersSection(matchId: match.id),
            const SizedBox(height: 24),

            // Acciones según estado de inscripción
            isSignedUpAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (isSignedUp) {
                if (!match.isOpen && !match.isFull) {
                  return const SizedBox.shrink();
                }

                // Ya inscrito (no creador) → mostrar "Salir"
                if (isSignedUp && !isCreator) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Estás inscrito en este partido',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isActioning
                            ? null
                            : () => _confirmLeave(context, ref),
                        icon: const Icon(Icons.exit_to_app,
                            color: Colors.orange),
                        label: const Text('Salir del partido',
                            style: TextStyle(color: Colors.orange)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ],
                  );
                }

                // No inscrito + hay espacio → mostrar "Unirse"
                if (!isSignedUp && !isCreator && match.isOpen && !match.isFull) {
                  return ElevatedButton.icon(
                    onPressed: isActioning
                        ? null
                        : () => ref
                            .read(matchNotifierProvider.notifier)
                            .joinMatch(match.id),
                    icon: isActioning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sports_soccer),
                    label: Text(isActioning
                        ? 'Uniendo...'
                        : 'Unirse al partido — \$${moneyFmt.format(match.pricePerPlayer)} COP'),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            // Creador → puede cancelar
            if (isCreator && match.isOpen) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Tú creaste este partido',
                        style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isActioning
                    ? null
                    : () => _confirmCancel(context, ref),
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                label: const Text('Cancelar partido',
                    style: TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir del partido?'),
        content: const Text('Tu plaza será liberada para otro jugador.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, salir',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(matchNotifierProvider.notifier).leaveMatch(match.id);
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar partido?'),
        content: const Text(
            'Se notificará a todos los jugadores inscritos.'),
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
      await ref.read(matchRepositoryProvider).cancelMatch(match.id);
      ref.invalidate(matchDetailProvider(match.id));
      ref.invalidate(openMatchesProvider(null));
    }
  }

  String _levelLabel(String? level) {
    switch (level) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return 'Todos';
    }
  }

  Color _statusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.open:
        return Colors.green;
      case MatchStatus.full:
        return Colors.orange;
      case MatchStatus.cancelled:
        return Colors.red;
      case MatchStatus.completed:
        return Colors.blue;
    }
  }

  String _statusLabel(MatchStatus status) {
    switch (status) {
      case MatchStatus.open:
        return 'Abierto';
      case MatchStatus.full:
        return 'Completo';
      case MatchStatus.cancelled:
        return 'Cancelado';
      case MatchStatus.completed:
        return 'Finalizado';
    }
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


class _PlayersSection extends ConsumerWidget {
  const _PlayersSection({required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(matchPlayersProvider(matchId));

    return playersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const Text('Error cargando jugadores'),
      data: (players) {
        if (players.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Aún no hay jugadores inscritos',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return Column(
          children: players.map((p) {
            final profile = p['profiles'] as Map<String, dynamic>? ?? {};
            final name = profile['name'] as String? ?? 'Jugador';
            final level = profile['level'] as String?;
            final avatarUrl = profile['avatar_url'] as String?;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(name, style: const TextStyle(fontSize: 14)),
              trailing: level != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _levelLabel(level),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return level;
    }
  }
}
