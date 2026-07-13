import '../../domain/entities/court_entity.dart';
import '../../domain/repositories/court_repository.dart';

class CourtModel {
  const CourtModel({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.sportId,
    required this.sportName,
    required this.pricePerHour,
    this.name,
    this.surfaceType,
    this.hasLights = false,
    this.address,
    this.lat,
    this.lng,
    this.cityName,
  });

  final String id;
  final String venueId;
  final String venueName;
  final String sportId;
  final String sportName;
  final double pricePerHour;
  final String? name;
  final String? surfaceType;
  final bool hasLights;
  final String? address;
  final double? lat;
  final double? lng;
  final String? cityName;

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    final venue = json['venues'] as Map<String, dynamic>? ?? {};
    final sport = json['sports'] as Map<String, dynamic>? ?? {};
    final city = venue['cities'] as Map<String, dynamic>? ?? {};

    return CourtModel(
      id: json['id'] as String,
      venueId: json['venue_id'] as String,
      venueName: venue['name'] as String? ?? '',
      sportId: json['sport_id'] as String? ?? '',
      sportName: sport['name'] as String? ?? '',
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      name: json['name'] as String?,
      surfaceType: json['surface_type'] as String?,
      hasLights: (json['lights'] as bool?) ?? false,
      address: venue['address'] as String?,
      lat: (venue['lat'] as num?)?.toDouble(),
      lng: (venue['lng'] as num?)?.toDouble(),
      cityName: city['name'] as String?,
    );
  }

  CourtEntity toEntity() => CourtEntity(
        id: id,
        venueId: venueId,
        venueName: venueName,
        sportId: sportId,
        sportName: sportName,
        pricePerHour: pricePerHour,
        name: name,
        surfaceType: surfaceType,
        hasLights: hasLights,
        address: address,
        lat: lat,
        lng: lng,
      );
}

class SlotModel {
  const SlotModel({
    required this.id,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.priceOverride,
  });

  final String id;
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final double? priceOverride;

  factory SlotModel.fromJson(Map<String, dynamic> json) => SlotModel(
        id: json['id'] as String,
        courtId: json['court_id'] as String,
        startTime: DateTime.parse(json['start_time'] as String).toLocal(),
        endTime: DateTime.parse(json['end_time'] as String).toLocal(),
        status: json['status'] as String? ?? 'available',
        priceOverride: (json['price_override'] as num?)?.toDouble(),
      );

  AvailabilitySlot toEntity() => AvailabilitySlot(
        id: id,
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
        status: _parseStatus(status),
        priceOverride: priceOverride,
      );

  static SlotStatus _parseStatus(String s) {
    switch (s) {
      case 'booked':
        return SlotStatus.booked;
      case 'blocked':
        return SlotStatus.blocked;
      default:
        return SlotStatus.available;
    }
  }
}
