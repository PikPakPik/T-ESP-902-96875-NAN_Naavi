import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'organized_waypoint.dart';
import 'route_statistics.dart';

/// Représente une option de randonnée organisée complète
/// Contient : waypoints, tracé, statistiques
class OrganizedHikeOption {
  final String id;
  final String name; // "Option 1", "Option 2", etc.
  final List<OrganizedWaypoint> waypoints;
  final List<List<double>>? routeCoordinates; // Tracé Mapbox [lon, lat]
  final RouteStatistics? statistics;

  OrganizedHikeOption({
    required this.id,
    required this.name,
    required this.waypoints,
    this.routeCoordinates,
    this.statistics,
  });

  /// Vérifie si l'option est complète (au moins 2 waypoints + route calculée)
  bool get isComplete =>
      waypoints.length >= 2 &&
          routeCoordinates != null &&
          routeCoordinates!.isNotEmpty;

  /// Vérifie si l'option a un point de départ
  bool get hasStartPoint => waypoints.isNotEmpty;

  /// Récupère le point de départ
  OrganizedWaypoint? get startPoint =>
      waypoints.isEmpty ? null : waypoints.first;

  /// Récupère la destination
  OrganizedWaypoint? get destination =>
      waypoints.length < 2 ? null : waypoints.last;

  /// Copie avec modifications
  OrganizedHikeOption copyWith({
    String? id,
    String? name,
    List<OrganizedWaypoint>? waypoints,
    List<List<double>>? routeCoordinates,
    RouteStatistics? statistics,
  }) {
    return OrganizedHikeOption(
      id: id ?? this.id,
      name: name ?? this.name,
      waypoints: waypoints ?? this.waypoints,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      statistics: statistics ?? this.statistics,
    );
  }

  /// Conversion vers Map pour sauvegarde locale
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'waypoints': waypoints
          .map((w) => {
        'id': w.id,
        'longitude': w.position.lng,
        'latitude': w.position.lat,
        'type': w.type.name,
        'name': w.name,
        'address': w.address,
        'isCurrentLocation': w.isCurrentLocation,
        'imageUrls': w.imageUrls,
      })
          .toList(),
      'routeCoordinates': routeCoordinates,
      'statistics': statistics != null
          ? {
        'distanceKm': statistics!.distanceKm,
        'elevationGainM': statistics!.elevationGainM,
        'estimatedDurationSeconds':
        statistics!.estimatedDuration.inSeconds,
        'dangerCount': statistics!.dangerCount,
        'waterPointCount': statistics!.waterPointCount,
        'signageCount': statistics!.signageCount,
        'poiCount': statistics!.poiCount,
      }
          : null,
    };
  }

  /// Création depuis Map (sauvegarde locale)
  factory OrganizedHikeOption.fromMap(Map<String, dynamic> map) {
    return OrganizedHikeOption(
      id: map['id'] as String,
      name: map['name'] as String,
      waypoints: (map['waypoints'] as List)
          .map((w) => OrganizedWaypoint(
        id: w['id'] as String,
        position: Position(
          w['longitude'] as double,
          w['latitude'] as double,
        ),
        type: WaypointType.values.firstWhere(
              (e) => e.name == w['type'],
        ),
        name: w['name'] as String?,
        address: w['address'] as String?,
        isCurrentLocation: w['isCurrentLocation'] as bool? ?? false,
        imageUrls: (w['imageUrls'] as List?)?.cast<String>() ?? [],
      ))
          .toList(),
      routeCoordinates: map['routeCoordinates'] != null
          ? (map['routeCoordinates'] as List)
          .map((coord) => (coord as List).cast<double>())
          .toList()
          : null,
      statistics: map['statistics'] != null
          ? RouteStatistics(
        distanceKm: map['statistics']['distanceKm'] as double,
        elevationGainM: map['statistics']['elevationGainM'] as int,
        estimatedDuration: Duration(
          seconds: map['statistics']['estimatedDurationSeconds'] as int,
        ),
        dangerCount: map['statistics']['dangerCount'] as int? ?? 0,
        waterPointCount:
        map['statistics']['waterPointCount'] as int? ?? 0,
        signageCount: map['statistics']['signageCount'] as int? ?? 0,
        poiCount: map['statistics']['poiCount'] as int? ?? 0,
      )
          : null,
    );
  }
}