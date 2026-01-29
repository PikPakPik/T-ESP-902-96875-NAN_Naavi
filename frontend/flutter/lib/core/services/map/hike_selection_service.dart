import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../geometry/geometry_calculation_service.dart';

/// Service statique pour la gestion de la sélection de randonnées
/// et le positionnement de la caméra
class HikeSelectionService {
  HikeSelectionService._();

  // ═══════════════════════════════════════════════════════════
  // CAMERA POSITIONING
  // ═══════════════════════════════════════════════════════════

  /// Cadre la caméra sur toute la randonnée avec vue de dessus
  /// Utilisé lors de la sélection d'une randonnée ou retour depuis navigation
  static Future<void> fitCameraToHike(
    MapboxMap mapboxMap,
    List<dynamic> coordinates, {
    double bottomPadding = 450,
    double topPadding = 100,
    double horizontalPadding = 50,
    int animationDuration = 1000,
  }) async {
    if (coordinates.isEmpty) {
      return;
    }

    try {
      // Réinitialiser le padding à 0 AVANT le calcul pour éviter les interférences
      await mapboxMap.setCamera(
        CameraOptions(
          padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        ),
      );

      // Calculer les bounds de la randonnée
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLon = double.infinity;
      double maxLon = -double.infinity;

      for (final coord in coordinates) {
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();

        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lon < minLon) minLon = lon;
        if (lon > maxLon) maxLon = lon;
      }

      // Créer les bounds
      final bounds = CoordinateBounds(
        southwest: Point(coordinates: Position(minLon, minLat)),
        northeast: Point(coordinates: Position(maxLon, maxLat)),
        infiniteBounds: false,
      );

      // Calculer la position de caméra optimale
      final cameraForBounds = await mapboxMap.cameraForCoordinateBounds(
        bounds,
        MbxEdgeInsets(
          top: topPadding,
          left: horizontalPadding,
          bottom: bottomPadding,
          right: horizontalPadding,
        ),
        0.0, // bearing - forcer à 0 pour orientation nord
        0.0, // pitch - forcer à 0 pour vue de dessus (pas de 3D)
        null, // maxZoom
        null, // offset
      );

      // Appliquer la caméra avec easeTo
      await mapboxMap.easeTo(
        cameraForBounds,
        MapAnimationOptions(duration: animationDuration),
      );
    } catch (e) {
      // Camera animation errors are silently ignored
    }
  }

  /// Cadre la caméra sur un point spécifique (point de départ)
  static Future<void> centerOnPoint(
    MapboxMap mapboxMap, {
    required double latitude,
    required double longitude,
    double zoom = 15.0,
    int animationDuration = 1000,
  }) async {
    try {
      await mapboxMap.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: zoom,
          bearing: 0.0,
          pitch: 0.0,
        ),
        MapAnimationOptions(duration: animationDuration),
      );
    } catch (e) {
      // Camera animation errors are silently ignored
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DISTANCE CALCULATION
  // ═══════════════════════════════════════════════════════════

  /// Calcule la distance entre la position actuelle et le point de départ
  /// Retourne la distance en kilomètres ou null si impossible à calculer
  static double? calculateDistanceToHikeStart({
    required gl.Position? currentPosition,
    required Map<String, dynamic>? hikeInfo,
  }) {
    if (currentPosition == null || hikeInfo == null) {
      return null;
    }

    // Les coordonnées sont dans start_point: {latitude, longitude}
    final startPoint = hikeInfo['start_point'];
    final startLat = startPoint?['latitude'] as double?;
    final startLon = startPoint?['longitude'] as double?;

    if (startLat == null || startLon == null) {
      return null;
    }

    final distance = GeometryCalculationService.calculateDistanceToPoint(
      currentPosition: currentPosition,
      targetLat: startLat,
      targetLon: startLon,
    );

    return distance;
  }

  /// Extrait les coordonnées du point de départ d'une randonnée
  static ({double lat, double lon})? extractStartPoint(
    Map<String, dynamic> hikeInfo,
  ) {
    final startPoint = hikeInfo['start_point'] as Map<String, dynamic>?;
    final startLat = startPoint?['latitude'] as double?;
    final startLon = startPoint?['longitude'] as double?;

    if (startLat == null || startLon == null) {
      return null;
    }

    return (lat: startLat, lon: startLon);
  }

  /// Extrait les coordonnées de la route depuis hikeInfo ou allRoutes
  static List<List<double>>? extractRouteCoordinates({
    required Map<String, dynamic> hikeInfo,
    List<Map<String, dynamic>>? allRoutes,
  }) {
    // Essayer d'abord depuis allRoutes via l'index
    final hikeIndex = hikeInfo['hikeIndex'] ?? hikeInfo['routeIndex'];

    if (hikeIndex != null &&
        allRoutes != null &&
        hikeIndex < allRoutes.length) {
      final coords = allRoutes[hikeIndex]['coordinates'] as List<dynamic>?;
      if (coords != null && coords.isNotEmpty) {
        return coords
            .map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
            .toList();
      }
    }

    // Fallback: essayer depuis hikeInfo directement
    final coords = hikeInfo['coordinates'] as List<dynamic>?;
    if (coords != null && coords.isNotEmpty) {
      return coords
          .map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
          .toList();
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // PROXIMITY CHECK
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si l'utilisateur est à proximité du point de départ (< 20m)
  static bool isNearStartPoint({
    required gl.Position currentPosition,
    required double startLat,
    required double startLon,
    double thresholdMeters = 20.0,
  }) {
    final distanceKm = GeometryCalculationService.calculateDistanceKm(
      currentPosition.latitude,
      currentPosition.longitude,
      startLat,
      startLon,
    );

    final distanceMeters = distanceKm * 1000;
    return distanceMeters < thresholdMeters;
  }
}
