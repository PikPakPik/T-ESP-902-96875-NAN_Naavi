import 'dart:math';
import 'package:geolocator/geolocator.dart' as gl;
import '../../../presentation/guided/state/GuidedHikeTrackingState.dart';

/// Service utilitaire pour les calculs géométriques et géographiques
/// Centralise tous les calculs de bearing, distance, angles, etc.
class GeometryCalculationService {
  /// Calcule le bearing (angle) entre deux points géographiques
  /// Retourne l'angle en degrés (0-360°) où 0° = Nord
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = (lon2 - lon1) * pi / 180;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final x = sin(dLon) * cos(lat2Rad);
    final y = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(x, y) * 180 / pi;
    return (bearing + 360) % 360;
  }

  /// Calcule la distance entre deux points géographiques en kilomètres
  /// Utilise la méthode Geolocator.distanceBetween qui implémente la formule de Haversine
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final distanceMeters = gl.Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distanceMeters / 1000;
  }

  /// Calcule la distance entre deux points géographiques en mètres
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return gl.Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Convertit un angle en type de direction (straight, left, right, etc.)
  /// Utilisé pour les instructions turn-by-turn
  static DirectionType angleToDirectionType(double angle) {
    // Normaliser l'angle entre 0 et 360
    angle = angle % 360;
    if (angle < 0) angle += 360;

    if (angle >= 337.5 || angle < 22.5) {
      return DirectionType.straight;
    } else if (angle >= 22.5 && angle < 67.5) {
      return DirectionType.slightRight;
    } else if (angle >= 67.5 && angle < 112.5) {
      return DirectionType.right;
    } else if (angle >= 112.5 && angle < 157.5) {
      return DirectionType.sharpRight;
    } else if (angle >= 157.5 && angle < 202.5) {
      return DirectionType.uTurn;
    } else if (angle >= 202.5 && angle < 247.5) {
      return DirectionType.sharpLeft;
    } else if (angle >= 247.5 && angle < 292.5) {
      return DirectionType.left;
    } else {
      return DirectionType.slightLeft;
    }
  }

  /// Convertit un angle en instruction textuelle de direction
  static String angleToDirectionText(double angle) {
    final directionType = angleToDirectionType(angle);
    return directionTypeToText(directionType);
  }

  /// Convertit un DirectionType en texte d'instruction
  static String directionTypeToText(DirectionType type) {
    switch (type) {
      case DirectionType.straight:
        return 'Continuez tout droit';
      case DirectionType.slightRight:
        return 'Tournez légèrement à droite';
      case DirectionType.right:
        return 'Tournez à droite';
      case DirectionType.sharpRight:
        return 'Tournez fortement à droite';
      case DirectionType.uTurn:
        return 'Faites demi-tour';
      case DirectionType.sharpLeft:
        return 'Tournez fortement à gauche';
      case DirectionType.left:
        return 'Tournez à gauche';
      case DirectionType.slightLeft:
        return 'Tournez légèrement à gauche';
      case DirectionType.arrived:
        return 'Vous êtes arrivé !';
    }
  }

  /// Calcule la distance entre la position actuelle et un point cible
  /// Retourne null si currentPosition est null
  static double? calculateDistanceToPoint({
    required gl.Position? currentPosition,
    required double targetLat,
    required double targetLon,
  }) {
    if (currentPosition == null) return null;

    final distanceMeters = gl.Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLat,
      targetLon,
    );

    return distanceMeters / 1000; // Convertir en km
  }

  /// Convertit des degrés en radians
  static double degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Convertit des radians en degrés
  static double radiansToDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  /// Calcule les bounds (min/max lat/lng) d'un ensemble de coordonnées
  /// [coordinates] : Liste de coordonnées [[lng, lat], ...]
  /// Retourne un [GeoBounds] contenant les limites géographiques
  static GeoBounds calculateBounds(List<List<double>> coordinates) {
    if (coordinates.isEmpty) {
      throw ArgumentError('coordinates cannot be empty');
    }

    double minLat = coordinates.first[1];
    double maxLat = coordinates.first[1];
    double minLng = coordinates.first[0];
    double maxLng = coordinates.first[0];

    for (var coord in coordinates) {
      final lng = coord[0];
      final lat = coord[1];

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return GeoBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

  /// Variante pour Position de geolocator
  /// Calcule les bounds d'une liste de positions Geolocator
  static GeoBounds calculateBoundsFromPositions(List<gl.Position> positions) {
    final coordinates = positions
        .map((p) => [p.longitude, p.latitude])
        .toList();
    return calculateBounds(coordinates);
  }
}

/// Classe représentant les limites géographiques (bounds) d'un ensemble de coordonnées
class GeoBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  /// Latitude du centre des bounds
  double get centerLat => (minLat + maxLat) / 2;

  /// Longitude du centre des bounds
  double get centerLng => (minLng + maxLng) / 2;

  /// Différence de latitude (hauteur des bounds)
  double get latDiff => maxLat - minLat;

  /// Différence de longitude (largeur des bounds)
  double get lngDiff => maxLng - minLng;

  GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  @override
  String toString() {
    return 'GeoBounds(lat: $minLat to $maxLat, lng: $minLng to $maxLng, center: $centerLat, $centerLng)';
  }
}
