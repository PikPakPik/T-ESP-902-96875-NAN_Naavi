import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Service pour la gestion des markers circulaires sur la carte Mapbox.
///
/// Fournit des méthodes statiques pour afficher et nettoyer des markers
/// avec une couleur configurable.
class MapMarkerService {
  /// Affiche un marker circulaire sur la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [markerId] - Identifiant unique pour le marker (utilisé pour source et layer)
  /// [latitude] - Latitude du marker
  /// [longitude] - Longitude du marker
  /// [color] - Couleur du marker
  /// [radius] - Rayon du cercle (défaut: 12)
  /// [strokeColor] - Couleur du contour (défaut: blanc)
  /// [strokeWidth] - Épaisseur du contour (défaut: 3)
  static Future<void> displayMarker({
    required MapboxMap mapboxMap,
    required String markerId,
    required double latitude,
    required double longitude,
    required Color color,
    double radius = 12,
    Color strokeColor = Colors.white,
    double strokeWidth = 3,
  }) async {
    try {
      // Nettoyer l'ancien marker s'il existe
      await removeMarker(mapboxMap: mapboxMap, markerId: markerId);

      // Créer le GeoJSON pour le marker
      final geoJson = '''
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
        GeoJsonSource(id: '$markerId-source', data: geoJson),
      );

      // Ajouter le layer CircleLayer
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: '$markerId-layer',
          sourceId: '$markerId-source',
          circleColor: color.toARGB32(),
          circleRadius: radius,
          circleStrokeColor: strokeColor.toARGB32(),
          circleStrokeWidth: strokeWidth,
        ),
      );
    } catch (e) {
      developer.log(
        'Error displaying marker $markerId: $e',
        name: 'MapMarkerService',
      );
    }
  }

  /// Supprime un marker de la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [markerId] - Identifiant du marker à supprimer
  static Future<void> removeMarker({
    required MapboxMap mapboxMap,
    required String markerId,
  }) async {
    try {
      try {
        await mapboxMap.style.removeStyleLayer('$markerId-layer');
      } catch (e) {
        // Layer n'existe pas, ignorer
      }
      try {
        await mapboxMap.style.removeStyleSource('$markerId-source');
      } catch (e) {
        // Source n'existe pas, ignorer
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  /// Supprime plusieurs markers de la carte.
  ///
  /// [mapboxMap] - Le contrôleur de la carte Mapbox
  /// [markerIds] - Liste des identifiants de markers à supprimer
  static Future<void> removeMarkers({
    required MapboxMap mapboxMap,
    required List<String> markerIds,
  }) async {
    for (final markerId in markerIds) {
      await removeMarker(mapboxMap: mapboxMap, markerId: markerId);
    }
  }
}
