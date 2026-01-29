import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Représente un point de passage dans une randonnée organisée
/// Peut être : point de départ, waypoint intermédiaire, ou destination finale
class OrganizedWaypoint {
  final String id;
  final Position position; // Mapbox Position (longitude, latitude)
  final WaypointType type;
  final String? name;
  final String? address;
  final bool isCurrentLocation; // True si c'est la position GPS actuelle
  final List<String> imageUrls; // URLs des images associées au waypoint

  OrganizedWaypoint({
    required this.id,
    required this.position,
    required this.type,
    this.name,
    this.address,
    this.isCurrentLocation = false,
    this.imageUrls = const [],
  });

  /// Crée un waypoint depuis la position GPS actuelle
  factory OrganizedWaypoint.fromCurrentLocation(
    double latitude,
    double longitude,
  ) {
    return OrganizedWaypoint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: Position(longitude, latitude),
      type: WaypointType.start,
      name: 'Ma position actuelle',
      isCurrentLocation: true,
    );
  }

  /// Copie avec modifications
  OrganizedWaypoint copyWith({
    String? id,
    Position? position,
    WaypointType? type,
    String? name,
    String? address,
    bool? isCurrentLocation,
    List<String>? imageUrls,
  }) {
    return OrganizedWaypoint(
      id: id ?? this.id,
      position: position ?? this.position,
      type: type ?? this.type,
      name: name ?? this.name,
      address: address ?? this.address,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}

/// Type de waypoint dans l'itinéraire
enum WaypointType {
  start, // Point de départ
  waypoint, // Point de passage intermédiaire
  destination, // Destination finale
}
