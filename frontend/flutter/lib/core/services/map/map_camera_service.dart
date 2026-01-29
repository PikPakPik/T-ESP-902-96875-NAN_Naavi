import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../geometry/geometry_calculation_service.dart';

/// Service centralisé pour la gestion de la caméra Mapbox
/// Remplace les méthodes dupliquées : _moveCamera, _navigateToPoiLocation, _fitCameraToHikePath
class MapCameraService {
  /// Déplace la caméra vers une position spécifique
  ///
  /// [mapboxMap] : Contrôleur Mapbox
  /// [latitude] : Latitude de destination
  /// [longitude] : Longitude de destination
  /// [zoom] : Niveau de zoom (défaut: 15.0)
  /// [padding] : Padding autour de la position (optionnel)
  /// [duration] : Durée de l'animation en ms (défaut: 600ms pour fluidité)
  /// [pitch] : Inclinaison de la caméra (optionnel)
  /// [bearing] : Orientation de la caméra (optionnel)
  static Future<void> moveToPosition(
    MapboxMap mapboxMap, {
    required double latitude,
    required double longitude,
    double zoom = 15.0,
    MbxEdgeInsets? padding,
    int duration = 600,
    double? pitch,
    double? bearing,
  }) async {
    try {
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: zoom,
          padding: padding,
          pitch: pitch,
          bearing: bearing,
        ),
        MapAnimationOptions(duration: duration, startDelay: 0),
      );

      if (kDebugMode) {}
    } catch (e) {
      // Camera movement errors are silently ignored
    }
  }

  /// Déplace la caméra vers une position Geolocator
  static Future<void> moveToGeoPosition(
    MapboxMap mapboxMap, {
    required gl.Position position,
    double zoom = 15.0,
    MbxEdgeInsets? padding,
    int duration = 600,
  }) async {
    await moveToPosition(
      mapboxMap,
      latitude: position.latitude,
      longitude: position.longitude,
      zoom: zoom,
      padding: padding,
      duration: duration,
    );
  }

  /// Cadre la caméra sur un ensemble de coordonnées (bounds)
  ///
  /// [mapboxMap] : Contrôleur Mapbox
  /// [coordinates] : Liste de coordonnées [[lng, lat], ...]
  /// [padding] : Padding autour des bounds (défaut: EdgeInsets standard)
  /// [duration] : Durée de l'animation en ms (défaut: 800ms pour fluidité)
  /// [pitch] : Inclinaison de la caméra (défaut: 0.0 = vue de dessus)
  /// [bearing] : Orientation de la caméra (défaut: 0.0 = nord en haut)
  static Future<void> fitToBounds(
    MapboxMap mapboxMap, {
    required List<List<double>> coordinates,
    MbxEdgeInsets? padding,
    int duration = 800,
    double pitch = 0.0,
    double bearing = 0.0,
  }) async {
    if (coordinates.isEmpty) {
      return;
    }

    try {
      final bounds = GeometryCalculationService.calculateBounds(coordinates);
      final zoom = _calculateZoomLevel(bounds);

      final defaultPadding = MbxEdgeInsets(
        top: 100,
        left: 50,
        bottom: 400,
        right: 50,
      );

      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(bounds.centerLng, bounds.centerLat),
          ),
          zoom: zoom,
          pitch: pitch,
          bearing: bearing,
          padding: padding ?? defaultPadding,
        ),
        MapAnimationOptions(duration: duration, startDelay: 0),
      );

      if (kDebugMode) {}
    } catch (e) {
      // Camera movement errors are silently ignored
    }
  }

  /// Cadre la caméra sur un parcours de randonnée (segments de positions)
  ///
  /// [mapboxMap] : Contrôleur Mapbox
  /// [segments] : Liste de segments (chaque segment = liste de positions)
  /// [padding] : Padding pour la bottom sheet RecapHike (~400px en bas)
  /// [duration] : Durée de l'animation en ms (défaut: 800ms pour fluidité)
  static Future<void> fitToRoute(
    MapboxMap mapboxMap, {
    required List<List<gl.Position>> segments,
    MbxEdgeInsets? padding,
    int duration = 800,
  }) async {
    if (segments.isEmpty) {
      return;
    }

    // Récupérer tous les points du parcours
    final allPoints = <gl.Position>[];
    for (var segment in segments) {
      allPoints.addAll(segment);
    }

    if (allPoints.isEmpty) {
      return;
    }

    // Convertir en coordonnées [lng, lat]
    final coordinates = allPoints
        .map((p) => [p.longitude, p.latitude])
        .toList();

    // Padding spécifique pour la bottom sheet RecapHike
    final routePadding =
        padding ??
        MbxEdgeInsets(
          top: 100,
          left: 50,
          bottom: 400, // Espace pour la bottom sheet
          right: 50,
        );

    await fitToBounds(
      mapboxMap,
      coordinates: coordinates,
      padding: routePadding,
      duration: duration,
      pitch: 0.0, // Vue de dessus
      bearing: 0.0, // Nord en haut
    );
  }

  /// Calcule le niveau de zoom approprié en fonction de la taille des bounds
  ///
  /// Plus la différence lat/lng est grande, moins on zoom
  static double _calculateZoomLevel(GeoBounds bounds) {
    final maxDiff = max(bounds.latDiff, bounds.lngDiff);

    if (maxDiff > 0.05) return 11.0;
    if (maxDiff > 0.02) return 12.0;
    if (maxDiff > 0.01) return 13.0;
    if (maxDiff > 0.005) return 14.0;
    return 15.0;
  }

  /// Déplace la caméra vers un POI avec padding pour modal
  ///
  /// Utilisé pour centrer le POI dans la partie visible au-dessus du modal
  /// [bottomPadding] : Hauteur du modal (défaut: 450px)
  static Future<void> moveToPoi(
    MapboxMap mapboxMap, {
    required double latitude,
    required double longitude,
    double bottomPadding = 450.0,
    double zoom = 15.0,
    int duration = 600,
  }) async {
    await moveToPosition(
      mapboxMap,
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
      padding: MbxEdgeInsets(
        top: 100.0,
        left: 20.0,
        bottom: bottomPadding,
        right: 20.0,
      ),
      duration: duration,
    );
  }
}
