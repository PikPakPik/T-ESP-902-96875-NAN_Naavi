import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Service pour la gestion des markers de départ et d'arrivée sur les routes.
///
/// Ce service fournit des méthodes statiques pour afficher et nettoyer
/// les markers de départ (vert) et d'arrivée (rouge) sur la carte Mapbox.
/// Il est utilisé par le mode improvise et le mode organisé.
class RouteMarkerService {
  // Identifiants pour les sources et layers
  static const String _startSourceId = 'route-start-source';
  static const String _startLayerId = 'route-start-layer';
  static const String _endSourceId = 'route-end-source';
  static const String _endLayerId = 'route-end-layer';
  static const String _waypointSourceId = 'route-waypoint-source';
  static const String _waypointLayerId = 'route-waypoint-layer';
  static const String _pauseSourcePrefix = 'route-pause-source';
  static const String _pauseLayerPrefix = 'route-pause-layer';

  // Couleurs standards
  static const Color startColor = Colors.green;
  static const Color endColor = Colors.red;
  static const Color waypointColor = Colors.orange;
  static const Color pauseColor = Color(0xFF42A5F5); // Bleu ciel
  static const Color strokeColor = Colors.white;

  // Tailles standards
  static const double markerRadius = 8.0;
  static const double strokeWidth = 2.0;

  // Compteur pour les markers de pause (chaque pause a un ID unique)
  static int _pauseMarkerCount = 0;

  /// Affiche le marker de départ (vert) sur la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [latitude] - Latitude du point de départ
  /// [longitude] - Longitude du point de départ
  /// [prefix] - Préfixe optionnel pour les IDs (pour éviter les conflits)
  static Future<void> displayStartMarker({
    required MapboxMap mapboxMap,
    required double latitude,
    required double longitude,
    String prefix = '',
  }) async {
    final sourceId = prefix.isEmpty
        ? _startSourceId
        : '$prefix-$_startSourceId';
    final layerId = prefix.isEmpty ? _startLayerId : '$prefix-$_startLayerId';

    await _displayCircleMarker(
      mapboxMap: mapboxMap,
      sourceId: sourceId,
      layerId: layerId,
      latitude: latitude,
      longitude: longitude,
      color: startColor,
    );
  }

  /// Affiche le marker d'arrivée (rouge) sur la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [latitude] - Latitude du point d'arrivée
  /// [longitude] - Longitude du point d'arrivée
  /// [prefix] - Préfixe optionnel pour les IDs (pour éviter les conflits)
  static Future<void> displayEndMarker({
    required MapboxMap mapboxMap,
    required double latitude,
    required double longitude,
    String prefix = '',
  }) async {
    final sourceId = prefix.isEmpty ? _endSourceId : '$prefix-$_endSourceId';
    final layerId = prefix.isEmpty ? _endLayerId : '$prefix-$_endLayerId';

    await _displayCircleMarker(
      mapboxMap: mapboxMap,
      sourceId: sourceId,
      layerId: layerId,
      latitude: latitude,
      longitude: longitude,
      color: endColor,
    );
  }

  /// Affiche un marker de waypoint intermédiaire (orange) sur la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [latitude] - Latitude du waypoint
  /// [longitude] - Longitude du waypoint
  /// [index] - Index du waypoint (pour générer un ID unique)
  /// [prefix] - Préfixe optionnel pour les IDs
  static Future<void> displayWaypointMarker({
    required MapboxMap mapboxMap,
    required double latitude,
    required double longitude,
    required int index,
    String prefix = '',
  }) async {
    final sourceId = prefix.isEmpty
        ? '$_waypointSourceId-$index'
        : '$prefix-$_waypointSourceId-$index';
    final layerId = prefix.isEmpty
        ? '$_waypointLayerId-$index'
        : '$prefix-$_waypointLayerId-$index';

    await _displayCircleMarker(
      mapboxMap: mapboxMap,
      sourceId: sourceId,
      layerId: layerId,
      latitude: latitude,
      longitude: longitude,
      color: waypointColor,
    );
  }

  /// Affiche plusieurs waypoints intermédiaires sur la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [waypoints] - Liste des coordonnées [latitude, longitude]
  /// [prefix] - Préfixe optionnel pour les IDs
  static Future<void> displayWaypointMarkers({
    required MapboxMap mapboxMap,
    required List<List<double>> waypoints,
    String prefix = '',
  }) async {
    for (int i = 0; i < waypoints.length; i++) {
      await displayWaypointMarker(
        mapboxMap: mapboxMap,
        latitude: waypoints[i][0],
        longitude: waypoints[i][1],
        index: i,
        prefix: prefix,
      );
    }
  }

  /// Supprime un marker de waypoint intermédiaire.
  static Future<void> removeWaypointMarker({
    required MapboxMap mapboxMap,
    required int index,
    String prefix = '',
  }) async {
    final sourceId = prefix.isEmpty
        ? '$_waypointSourceId-$index'
        : '$prefix-$_waypointSourceId-$index';
    final layerId = prefix.isEmpty
        ? '$_waypointLayerId-$index'
        : '$prefix-$_waypointLayerId-$index';

    await _removeMarker(
      mapboxMap: mapboxMap,
      sourceId: sourceId,
      layerId: layerId,
    );
  }

  /// Supprime tous les waypoints intermédiaires (jusqu'à maxCount).
  ///
  /// [maxCount] - Nombre maximum de waypoints à supprimer (défaut: 20)
  static Future<void> removeAllWaypointMarkers({
    required MapboxMap mapboxMap,
    String prefix = '',
    int maxCount = 20,
  }) async {
    for (int i = 0; i < maxCount; i++) {
      await removeWaypointMarker(
        mapboxMap: mapboxMap,
        index: i,
        prefix: prefix,
      );
    }
  }

  /// Affiche les deux markers (départ et arrivée) sur la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [startLatitude] - Latitude du point de départ
  /// [startLongitude] - Longitude du point de départ
  /// [endLatitude] - Latitude du point d'arrivée
  /// [endLongitude] - Longitude du point d'arrivée
  /// [prefix] - Préfixe optionnel pour les IDs
  static Future<void> displayBothMarkers({
    required MapboxMap mapboxMap,
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String prefix = '',
  }) async {
    await Future.wait([
      displayStartMarker(
        mapboxMap: mapboxMap,
        latitude: startLatitude,
        longitude: startLongitude,
        prefix: prefix,
      ),
      displayEndMarker(
        mapboxMap: mapboxMap,
        latitude: endLatitude,
        longitude: endLongitude,
        prefix: prefix,
      ),
    ]);
  }

  /// Affiche un marker de pause/reprise (bleu ciel) sur la carte.
  ///
  /// Chaque appel crée un nouveau marker avec un ID unique.
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [latitude] - Latitude du point de pause/reprise
  /// [longitude] - Longitude du point de pause/reprise
  /// [prefix] - Préfixe optionnel pour les IDs
  static Future<void> displayPauseMarker({
    required MapboxMap mapboxMap,
    required double latitude,
    required double longitude,
    String prefix = '',
  }) async {
    _pauseMarkerCount++;
    final sourceId = prefix.isEmpty
        ? '$_pauseSourcePrefix-$_pauseMarkerCount'
        : '$prefix-$_pauseSourcePrefix-$_pauseMarkerCount';
    final layerId = prefix.isEmpty
        ? '$_pauseLayerPrefix-$_pauseMarkerCount'
        : '$prefix-$_pauseLayerPrefix-$_pauseMarkerCount';

    await _displayCircleMarker(
      mapboxMap: mapboxMap,
      sourceId: sourceId,
      layerId: layerId,
      latitude: latitude,
      longitude: longitude,
      color: pauseColor,
    );
  }

  /// Réinitialise le compteur de markers de pause (à appeler lors d'un nouveau tracking)
  static void resetPauseMarkerCount() {
    _pauseMarkerCount = 0;
  }

  /// Supprime tous les markers de pause de la carte.
  static Future<void> removePauseMarkers({
    required MapboxMap mapboxMap,
    String prefix = '',
  }) async {
    // Supprimer tous les markers de pause créés (de 1 à _pauseMarkerCount)
    final futures = <Future<void>>[];
    for (int i = 1; i <= _pauseMarkerCount; i++) {
      final sourceId = prefix.isEmpty
          ? '$_pauseSourcePrefix-$i'
          : '$prefix-$_pauseSourcePrefix-$i';
      final layerId = prefix.isEmpty
          ? '$_pauseLayerPrefix-$i'
          : '$prefix-$_pauseLayerPrefix-$i';
      futures.add(
        _removeMarker(
          mapboxMap: mapboxMap,
          sourceId: sourceId,
          layerId: layerId,
        ),
      );
    }
    await Future.wait(futures);
  }

  /// Supprime le marker de départ de la carte.
  static Future<void> removeStartMarker({
    required MapboxMap mapboxMap,
    String prefix = '',
  }) async {
    final sourceId = prefix.isEmpty
        ? _startSourceId
        : '$prefix-$_startSourceId';
    final layerId = prefix.isEmpty ? _startLayerId : '$prefix-$_startLayerId';

    await _removeMarker(
      mapboxMap: mapboxMap,
      sourceId: sourceId,
      layerId: layerId,
    );
  }

  /// Supprime le marker d'arrivée de la carte.
  static Future<void> removeEndMarker({
    required MapboxMap mapboxMap,
    String prefix = '',
  }) async {
    final sourceId = prefix.isEmpty ? _endSourceId : '$prefix-$_endSourceId';
    final layerId = prefix.isEmpty ? _endLayerId : '$prefix-$_endLayerId';

    await _removeMarker(
      mapboxMap: mapboxMap,
      sourceId: sourceId,
      layerId: layerId,
    );
  }

  /// Supprime tous les markers de route (départ, arrivée, waypoints et pauses).
  ///
  /// [maxWaypoints] - Nombre maximum de waypoints à supprimer (défaut: 20)
  static Future<void> removeAllMarkers({
    required MapboxMap mapboxMap,
    String prefix = '',
    int maxWaypoints = 20,
  }) async {
    await Future.wait([
      removeStartMarker(mapboxMap: mapboxMap, prefix: prefix),
      removeEndMarker(mapboxMap: mapboxMap, prefix: prefix),
      removeAllWaypointMarkers(
        mapboxMap: mapboxMap,
        prefix: prefix,
        maxCount: maxWaypoints,
      ),
      removePauseMarkers(mapboxMap: mapboxMap, prefix: prefix),
    ]);
  }

  /// Méthode interne pour afficher un marker circulaire.
  static Future<void> _displayCircleMarker({
    required MapboxMap mapboxMap,
    required String sourceId,
    required String layerId,
    required double latitude,
    required double longitude,
    required Color color,
  }) async {
    try {
      // Nettoyer l'ancien marker s'il existe
      await _removeMarker(
        mapboxMap: mapboxMap,
        sourceId: sourceId,
        layerId: layerId,
      );

      // Créer le GeoJSON pour le marker
      final geoJson =
          '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [$longitude, $latitude]
      }
    }
  ]
}''';

      // Ajouter la source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: sourceId, data: geoJson),
      );

      // Ajouter le layer CircleLayer
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: layerId,
          sourceId: sourceId,
          circleColor: color.toARGB32(),
          circleRadius: markerRadius,
          circleStrokeColor: strokeColor.toARGB32(),
          circleStrokeWidth: strokeWidth,
        ),
      );
    } catch (e) {
      developer.log(
        'Error displaying marker ($sourceId): $e',
        name: 'RouteMarkerService',
      );
    }
  }

  /// Méthode interne pour supprimer un marker.
  static Future<void> _removeMarker({
    required MapboxMap mapboxMap,
    required String sourceId,
    required String layerId,
  }) async {
    try {
      try {
        await mapboxMap.style.removeStyleLayer(layerId);
      } catch (e) {
        // Layer n'existe pas, ignorer
      }
      try {
        await mapboxMap.style.removeStyleSource(sourceId);
      } catch (e) {
        // Source n'existe pas, ignorer
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }
}
