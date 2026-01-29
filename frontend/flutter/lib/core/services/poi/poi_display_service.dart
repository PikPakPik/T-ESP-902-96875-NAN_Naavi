import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../data/models/user_poi.dart';
import '../../services/user_poi_service.dart';
import '../../services/poi_manager.dart';
import '../../utils/poi_type.dart';
import '../map/map_camera_service.dart';

/// Service centralisé pour l'affichage et la gestion des POI sur la carte
/// Remplace _loadSavedPOIs() et _navigateToPoiLocation() dans HomeMapExplorerPage
class PoiDisplayService {
  /// Charge tous les POI sauvegardés et les affiche sur la carte
  ///
  /// [mapboxMap] : Contrôleur Mapbox
  /// Nettoie d'abord tous les POI existants, puis charge les POI sauvegardés
  static Future<void> loadAndDisplayPois(MapboxMap mapboxMap) async {
    try {
      // Supprimer tous les POI custom affichés sur la carte
      await POIManager.clearAllCustomPOIs(mapboxMap);

      // Charger les POI sauvegardés
      final savedPois = await UserPoiService.getAllPOIs();

      if (kDebugMode) {}

      // Charger tous les POIs en parallèle pour optimiser les performances
      final poiFutures = savedPois.map((poi) {
        return POIManager.addCustomPOI(
          mapboxMap,
          poi.latitude,
          poi.longitude,
          poiType: poi.type,
          title: poi.name,
          iconSize: 0.5,
        );
      });

      await Future.wait(poiFutures);

      if (kDebugMode) {}
    } catch (e) {
      // POI display errors are silently ignored
    }
  }

  /// Navigue vers un POI avec surbrillance (agrandissement visuel)
  ///
  /// [mapboxMap] : Contrôleur Mapbox
  /// [poi] : POI vers lequel naviguer
  /// [bottomPadding] : Padding en bas pour le modal (défaut: 450px)
  /// [iconSize] : Taille de l'icône surligné (défaut: 0.6 = 2x la taille normale)
  ///
  /// Le POI sera centré dans la partie visible de la carte (au-dessus du modal)
  static Future<void> navigateToPoiWithHighlight({
    required MapboxMap mapboxMap,
    required UserPOI poi,
    double bottomPadding = 450.0,
    double iconSize = 0.6,
  }) async {
    try {
      // Déplacer la caméra vers le POI avec padding pour le modal
      await MapCameraService.moveToPoi(
        mapboxMap,
        latitude: poi.latitude,
        longitude: poi.longitude,
        bottomPadding: bottomPadding,
        zoom: 15.0,
        duration: 1500,
      );

      // Ajouter un POI surligné (agrandi) pour le mettre en évidence
      await POIManager.highlightPOI(
        mapboxMap,
        poi.latitude,
        poi.longitude,
        poiType: poi.type,
        iconSize: iconSize, // 2x la taille normale (0.3)
      );

      if (kDebugMode) {}
    } catch (e) {
      // POI navigation errors are silently ignored
    }
  }

  /// Ajoute un POI personnalisé à la carte
  ///
  /// Wrapper simplifié pour POIManager.addCustomPOI
  static Future<void> addPoi({
    required MapboxMap mapboxMap,
    required double latitude,
    required double longitude,
    required PoiType poiType,
    String? title,
    double iconSize = 0.5,
  }) async {
    try {
      await POIManager.addCustomPOI(
        mapboxMap,
        latitude,
        longitude,
        poiType: poiType,
        title: title,
        iconSize: iconSize,
      );

      if (kDebugMode) {}
    } catch (e) {
      // Custom POI creation errors are silently ignored
    }
  }

  /// Supprime le POI surligné de la carte
  static Future<void> clearHighlightedPoi() async {
    try {
      await POIManager.clearHighlightedPOI();
      if (kDebugMode) {}
    } catch (e) {
      // Clear highlighted POI errors are silently ignored
    }
  }

  /// Supprime tous les POI custom de la carte
  static Future<void> clearAllCustomPois(MapboxMap mapboxMap) async {
    try {
      await POIManager.clearAllCustomPOIs(mapboxMap);
      if (kDebugMode) {}
    } catch (e) {
      // Clear custom POIs errors are silently ignored
    }
  }
}
