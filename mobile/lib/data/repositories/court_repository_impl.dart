import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/repositories/court_repository.dart';
import '../models/court_model.dart';

class CourtRepositoryImpl implements CourtRepository {
  CourtRepositoryImpl(this._supabase);
  final SupabaseClient _supabase;

  @override
  Future<List<CourtEntity>> getCourts({
    String? cityId,
    String? sportId,
    DateTime? date,
    String? timeSlot,
  }) async {
    var query = _supabase
        .from(AppConstants.tableCourts)
        .select('''
          id, venue_id, sport_id, name, surface_type, lights, price_per_hour,
          venues!inner(id, name, address, lat, lng,
            cities(id, name)
          ),
          sports(id, name)
        ''')
        .eq('is_active', true);

    if (sportId != null) {
      query = query.eq('sport_id', sportId);
    }
    if (cityId != null) {
      query = query.eq('venues.city_id', cityId);
    }

    final data = await query.order('price_per_hour');
    return data.map((j) => CourtModel.fromJson(j).toEntity()).toList();
  }

  @override
  Future<CourtEntity> getCourtById(String courtId) async {
    final data = await _supabase
        .from(AppConstants.tableCourts)
        .select('''
          id, venue_id, sport_id, name, surface_type, lights, price_per_hour,
          venues!inner(id, name, address, lat, lng,
            cities(id, name)
          ),
          sports(id, name)
        ''')
        .eq('id', courtId)
        .single();

    return CourtModel.fromJson(data).toEntity();
  }

  @override
  Future<List<AvailabilitySlot>> getAvailability({
    required String courtId,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _supabase
        .from(AppConstants.tableSlots)
        .select()
        .eq('court_id', courtId)
        .gte('start_time', start.toUtc().toIso8601String())
        .lte('start_time', end.toUtc().toIso8601String())
        .order('start_time');

    return data.map((j) => SlotModel.fromJson(j).toEntity()).toList();
  }

  /// Suscripción Realtime — notifica cambios en slots de una cancha
  Stream<List<AvailabilitySlot>> watchAvailability({
    required String courtId,
    required DateTime start,
    required DateTime end,
  }) {
    return _supabase
        .from(AppConstants.tableSlots)
        .stream(primaryKey: ['id'])
        .eq('court_id', courtId)
        .map((rows) => rows
            .where((r) {
              final t = DateTime.parse(r['start_time'] as String).toLocal();
              return t.isAfter(start) && t.isBefore(end);
            })
            .map((r) => SlotModel.fromJson(r).toEntity())
            .toList());
  }
}
