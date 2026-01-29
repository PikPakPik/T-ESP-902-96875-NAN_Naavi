import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../utils/poi_type.dart';

/// Utility class for adding POI annotations to the map
class POIManager {
  // Utilisation d'un singleton pour le PointAnnotationManager des custom POIs
  static PointAnnotationManager? _customPoiManager;
  // Manager pour le POI surligné (agrandi temporairement)
  static PointAnnotationManager? _highlightedPoiManager;
  // Liste de tous les managers créés pour pouvoir les supprimer
  static final List<PointAnnotationManager> _allManagers = [];

  /// Add a POI annotation using direct image loading (recommended approach)
  static Future<void> addPOIAnnotationDirect(
    MapboxMap mapboxMap,
    double latitude,
    double longitude, {
    PoiType type = PoiType.hazard,
    String? title,
    double iconSize = 0.5,
  }) async {
    try {
      // Create point annotation manager
      final pointAnnotationManager = await mapboxMap.annotations
          .createPointAnnotationManager();
      // Stocker le manager pour pouvoir le supprimer plus tard
      _allManagers.add(pointAnnotationManager);

      // Load the image from assets
      Uint8List? imageData;
      try {
        final ByteData bytes = await rootBundle.load(type.assetPath);
        imageData = bytes.buffer.asUint8List();
      } catch (e) {
        // Image loading errors are silently ignored
      }

      // Create a PointAnnotationOptions
      PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(longitude, latitude)),
        iconSize: iconSize,
        iconAnchor: IconAnchor.BOTTOM,
      );

      if (imageData != null && imageData.isNotEmpty) {
        pointAnnotationOptions.image = imageData;
      } else {
        pointAnnotationOptions.iconColor = type.color.toARGB32();
      }

      // Add text field if title is provided
      if (title != null) {
        pointAnnotationOptions.textField = title;
        pointAnnotationOptions.textOffset = [0.0, -2.0];
        pointAnnotationOptions.textColor = Colors.black.toARGB32();
        pointAnnotationOptions.textHaloColor = Colors.white.toARGB32();
        pointAnnotationOptions.textHaloWidth = 2.0;
      }

      // Add the annotation to the map
      await pointAnnotationManager.create(pointAnnotationOptions);
    } catch (e) {
      // POI creation errors are silently ignored
    }
  }

  /// Add an Alert POI marker on the map
  static Future<void> addAlertPOI(
    MapboxMap mapboxMap,
    double latitude,
    double longitude, {
    String? title,
    double iconSize = 0.4,
  }) async {
    await addPOIAnnotationDirect(
      mapboxMap,
      latitude,
      longitude,
      type: PoiType.hazard,
      title: title ?? "Alerte",
      iconSize: iconSize,
    );
  }

  /// Add a custom POI with icon and color
  static Future<void> addCustomPOI(
    MapboxMap mapboxMap,
    double latitude,
    double longitude, {
    required PoiType poiType, // 'parking', 'danger', 'viewpoint', 'rest'
    String? title,
    double iconSize = 0.3,
  }) async {
    try {
      // Crée le manager une seule fois et le réutilise
      _customPoiManager ??= await mapboxMap.annotations
          .createPointAnnotationManager();
      // Ajouter le manager à la liste pour pouvoir le supprimer
      if (!_allManagers.contains(_customPoiManager!)) {
        _allManagers.add(_customPoiManager!);
      }

      // Charger l'icône spécifique au type de POI
      final iconPath = poiType.assetPath;
      final ByteData bytes = await rootBundle.load(iconPath);
      final imageData = bytes.buffer.asUint8List();

      // Créer l'annotation avec l'icône depuis Figma (sans texte)
      PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(longitude, latitude)),
        iconSize:
            iconSize, // Taille réduite pour correspondre au point de position
        iconAnchor: IconAnchor.BOTTOM,
        image: imageData, // Utiliser l'icône depuis Figma
      );

      await _customPoiManager!.create(pointAnnotationOptions);
    } catch (e) {
      // Custom POI creation errors are silently ignored
    }
  }

  /// Supprime tous les custom POI (annotations personnalisées) affichés sur la carte
  static Future<void> clearAllCustomPOIs(MapboxMap mapboxMap) async {
    if (_customPoiManager != null) {
      try {
        await _customPoiManager!.deleteAll();
      } catch (_) {}
      _customPoiManager = null;
    }
  }

  /// Affiche un POI surligné (agrandi) temporairement
  /// Utilisé pour mettre en évidence un POI sélectionné
  static Future<void> highlightPOI(
    MapboxMap mapboxMap,
    double latitude,
    double longitude, {
    required PoiType poiType,
    double iconSize = 0.6, // Plus grand que la taille normale (0.3)
  }) async {
    try {
      // Supprimer le POI surligné précédent s'il existe
      await clearHighlightedPOI();

      // Créer un nouveau manager pour le POI surligné
      _highlightedPoiManager = await mapboxMap.annotations
          .createPointAnnotationManager();

      // Charger l'icône
      final iconPath = poiType.assetPath;
      final ByteData bytes = await rootBundle.load(iconPath);
      final imageData = bytes.buffer.asUint8List();

      // Créer l'annotation avec une taille plus grande
      PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(longitude, latitude)),
        iconSize: iconSize, // Taille agrandie
        iconAnchor: IconAnchor.BOTTOM,
        image: imageData,
      );

      await _highlightedPoiManager!.create(pointAnnotationOptions);
    } catch (e) {
      // Highlighted POI creation errors are silently ignored
    }
  }

  /// Supprime le POI surligné
  static Future<void> clearHighlightedPOI() async {
    if (_highlightedPoiManager != null) {
      try {
        await _highlightedPoiManager!.deleteAll();
      } catch (e) {
        // Delete errors are silently ignored
      }
      _highlightedPoiManager = null;
    }
  }

  /// Supprime tous les POI de la carte (custom et alert)
  static Future<void> clearAllPOIs(MapboxMap mapboxMap) async {
    // Supprimer tous les managers stockés
    final managersToDelete = List<PointAnnotationManager>.from(_allManagers);
    for (final manager in managersToDelete) {
      try {
        await manager.deleteAll();
      } catch (e) {
        // Delete errors are silently ignored
      }
    }
    _allManagers.clear();

    // Supprimer aussi le manager custom
    if (_customPoiManager != null) {
      try {
        await _customPoiManager!.deleteAll();
      } catch (e) {
        // Delete errors are silently ignored
      }
      _customPoiManager = null;
    }
  }
}
