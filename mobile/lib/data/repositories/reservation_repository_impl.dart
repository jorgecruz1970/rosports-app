import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../models/reservation_model.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  ReservationRepositoryImpl(this._supabase);
  final SupabaseClient _supabase;

    @override
  Future<ReservationEntity> createReservation({
    required String courtId,
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
    required double pricePerHour,
  }) async {
    final user = _supabase.auth.currentUser;
    print('[DEBUG] createReservation - user: ${user?.id}');
    print('[DEBUG] courtId: $courtId, slotId: $slotId');
    
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    final userId = user.id;
    final commission = pricePerHour * AppConstants.commissionRate;
    final netAmount = pricePerHour - commission;

    print('[DEBUG] Updating slot $slotId to booked...');
    
    // 1. Bloquear el slot
    final slotResult = await _supabase
        .from(AppConstants.tableSlots)
        .update({'status': 'booked'})
        .eq('id', slotId)
        .select();
    
    print('[DEBUG] Slot update result: $slotResult');

    // 2. Crear la reserva
    print('[DEBUG] Inserting reservation...');
    try {
      final data = await _supabase
          .from(AppConstants.tableReservations)
          .insert({
            'court_id': courtId,
            'user_id': userId,
            'slot_id': slotId,
            'start_time': startTime.toUtc().toIso8601String(),
            'end_time': endTime.toUtc().toIso8601String(),
            'total_amount': pricePerHour,
            'commission': commission,
            'net_amount': netAmount,
            'currency': 'COP',
            'status': 'pending',
          })
          .select()
          .single();

      print('[DEBUG] Reservation created: $data');
      return ReservationModel.fromJson(data).toEntity();
    } catch (e) {
      print('[ERROR] Failed to create reservation: $e');
      rethrow;
    }
  }

  @override
  Future<List<ReservationEntity>> getMyReservations() async {
    final userId = _supabase.auth.currentUser!.id;

    final data = await _supabase
        .from(AppConstants.tableReservations)
        .select('''
          id, court_id, user_id, start_time, end_time,
          total_amount, commission, net_amount, currency, status, payment_id,
          courts(name, venues(name))
        ''')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('start_time', ascending: false);

    return data
        .map((j) => ReservationModel.fromJson(j).toEntity())
        .toList();
  }

  @override
  Future<ReservationEntity> cancelReservation(String reservationId) async {
    // Obtener el slot_id antes de cancelar para liberarlo
    final existing = await _supabase
        .from(AppConstants.tableReservations)
        .select('slot_id')
        .eq('id', reservationId)
        .single();

    final slotId = existing['slot_id'] as String?;

    // Cancelar la reserva
    final data = await _supabase
        .from(AppConstants.tableReservations)
        .update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', reservationId)
        .select('''
          id, court_id, user_id, start_time, end_time,
          total_amount, commission, net_amount, currency, status,
          courts(name, venues(name))
        ''')
        .single();

    // Liberar el slot
    if (slotId != null) {
      await _supabase
          .from(AppConstants.tableSlots)
          .update({'status': 'available'}).eq('id', slotId);
    }

    return ReservationModel.fromJson(data).toEntity();
  }

  @override
  Future<ReservationEntity> markNoShow(String reservationId) async {
    final data = await _supabase
        .from(AppConstants.tableReservations)
        .update({'status': 'no_show'})
        .eq('id', reservationId)
        .select('''
          id, court_id, user_id, start_time, end_time,
          total_amount, commission, net_amount, currency, status,
          courts(name, venues(name))
        ''')
        .single();

    return ReservationModel.fromJson(data).toEntity();
  }
}
