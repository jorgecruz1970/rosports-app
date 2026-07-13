import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/match_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';

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

    ref.listen(matchNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (m) {
          if (m != null) {
            ref.invalidate(matchDetailProvider(match.id));
            ref.invalidate(openMatchesProvider(null));
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
              text: '\$${moneyFmt.format(match.pricePerPlayer)} COP por jugador',
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
            const SizedBox(height: 32),

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
            const SizedBox(height: 32),

            // Acciones
            if (match.isOpen && !match.isFull && !isCreator)
              ElevatedButton.icon(
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
                label: Text(isActioning ? 'Uniendo...' : 'Unirse al partido'),
              ),

            if (isCreator && match.isOpen) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isActioning
                    ? null
                    : () async {
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
                          await ref
                              .read(matchRepositoryProvider)
                              .cancelMatch(match.id);
                          ref.invalidate(matchDetailProvider(match.id));
                          ref.invalidate(openMatchesProvider(null));
                        }
                      },
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                label: const Text('Cancelar partido',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ],
        ),
      ),
    );
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
