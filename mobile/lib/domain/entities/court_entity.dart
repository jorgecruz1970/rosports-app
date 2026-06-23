import 'package:equatable/equatable.dart';

/// Entidad de dominio — Cancha
class CourtEntity extends Equatable {
  const CourtEntity({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.sportId,
    required this.sportName,
    required this.pricePerHour,
    this.surfaceType,
    this.hasLights = false,
    this.photoUrls = const [],
    this.address,
    this.lat,
    this.lng,
  });

  final String id;
  final String venueId;
  final String venueName;
  final String sportId;
  final String sportName;
  final double pricePerHour;
  final String? surfaceType;
  final bool hasLights;
  final List<String> photoUrls;
  final String? address;
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [id, venueId, sportId, pricePerHour];
}
