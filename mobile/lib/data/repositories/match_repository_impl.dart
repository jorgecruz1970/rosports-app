import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/repositories/match_repository.dart';
import '../models/match_model.dart';

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl(this._supabase);
  final SupabaseClient _supabase;

  @override
  Future<List<MatchEntity>> getOpenMatches({
    String? sportId,
    String? cityId,
  }) async {
    var query = _supabase
        .from(AppConstants.tableMatches)
        .select('''
          id, creator_user_id, court_id, sport_id, start_time, end_time,
          spots_total, spots_taken, price_per_player, level_min, level_max,
          is_public, signup_policy, status,
          courts(name, venues(name)),
          sports(name)
        ''')
        .eq('status', 'open')
        .eq('is_public', true)
        .gte('start_time', DateTime.now().toUtc().toIso8601String());

    if (sportId != null) {
      query = query.eq('sport_id', sportId);
    }

    final data = await query.order('start_time');
    return data.map((j) => MatchModel.fromJson(j).toEntity()).toList();
  }

  @override
  Future<MatchEntity> getMatchById(String matchId) async {
    final data = await _supabase
        .from(AppConstants.tableMatches)
        .select('''
          id, creator_user_id, court_id, sport_id, start_time, end_time,
          spots_total, spots_taken, price_per_player, level_min, level_max,
          is_public, signup_policy, status,
          courts(name, venues(name)),
          sports(name)
        ''')
        .eq('id', matchId)
        .single();

    // Calcular spots_taken real desde signups
    final signups = await _supabase
        .from(AppConstants.tableMatchSignups)
        .select('id')
        .eq('match_id', matchId)
        .eq('status', 'signed');
    
    final realSpotsTaken = (signups as List).length;
    data['spots_taken'] = realSpotsTaken;

    return MatchModel.fromJson(data).toEntity();
  }

  @override
  Future<MatchEntity> createMatch({
    required String courtId,
    required String sportId,
    required String reservationId,
    required DateTime startTime,
    required DateTime endTime,
    required int spotsTotal,
    required double pricePerPlayer,
    String? levelMin,
    String? levelMax,
    bool isPublic = true,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    final data = await _supabase
        .from(AppConstants.tableMatches)
        .insert({
          'creator_user_id': userId,
          'court_id': courtId,
          'sport_id': sportId,
          'reservation_id': reservationId,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'spots_total': spotsTotal,
          'spots_taken': 1, // El creador ocupa un puesto
          'price_per_player': pricePerPlayer,
          'level_min': levelMin,
          'level_max': levelMax,
          'is_public': isPublic,
          'status': 'open',
        })
        .select('''
          id, creator_user_id, court_id, sport_id, start_time, end_time,
          spots_total, spots_taken, price_per_player, level_min, level_max,
          is_public, signup_policy, status,
          courts(name, venues(name)),
          sports(name)
        ''')
        .single();

    // Auto-inscribir al creador
    await _supabase.from(AppConstants.tableMatchSignups).insert({
      'match_id': data['id'],
      'user_id': userId,
      'status': 'signed',
    });

    return MatchModel.fromJson(data).toEntity();
  }

  @override
  Future<void> joinMatch(String matchId) async {
    final userId = _supabase.auth.currentUser!.id;

    // Verificar si ya está inscrito — filtro manual por si RLS devuelve signups ajenos
    final allSignups = await _supabase
        .from(AppConstants.tableMatchSignups)
        .select('id, user_id, status')
        .eq('match_id', matchId);

    final mySignup = (allSignups as List)
        .where((row) => row['user_id'] == userId)
        .toList();

    if (mySignup.isNotEmpty) {
      final existing = mySignup.first;
      if (existing['status'] == 'signed') {
        throw Exception('Ya estás inscrito en este partido');
      }
      // Si estaba cancelado, re-inscribir
      await _supabase
          .from(AppConstants.tableMatchSignups)
          .update({'status': 'signed'})
          .eq('id', existing['id']);
    } else {
      // Inscribir nuevo
      await _supabase.from(AppConstants.tableMatchSignups).insert({
        'match_id': matchId,
        'user_id': userId,
        'status': 'signed',
      });
    }

    // Incrementar spots_taken directamente
    final countResult = await _supabase
        .from(AppConstants.tableMatchSignups)
        .select('id')
        .eq('match_id', matchId)
        .eq('status', 'signed');
    
    final newCount = (countResult as List).length;
    
    final matchData = await _supabase
        .from(AppConstants.tableMatches)
        .select('spots_total')
        .eq('id', matchId)
        .single();
    final spotsTotal = matchData['spots_total'] as int;

    await _supabase
        .from(AppConstants.tableMatches)
        .update({
          'spots_taken': newCount,
          'status': newCount >= spotsTotal ? 'full' : 'open',
        })
        .eq('id', matchId);
  }

  @override
  Future<void> leaveMatch(String matchId) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase
        .from(AppConstants.tableMatchSignups)
        .update({'status': 'cancelled'})
        .eq('match_id', matchId)
        .eq('user_id', userId);

    // Recalcular spots_taken
    final countResult = await _supabase
        .from(AppConstants.tableMatchSignups)
        .select('id')
        .eq('match_id', matchId)
        .eq('status', 'signed');

    final newCount = (countResult as List).length;
    await _supabase
        .from(AppConstants.tableMatches)
        .update({
          'spots_taken': newCount,
          'status': 'open',
        })
        .eq('id', matchId);
  }

  @override
  Future<void> cancelMatch(String matchId) async {
    await _supabase.from(AppConstants.tableMatches).update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }
}
