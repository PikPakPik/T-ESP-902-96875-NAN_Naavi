import 'package:flutter/material.dart';
import 'package:naavi/core/utils/poi_type.dart';

/// Configuration pour les POI (deprecated - use PoiType extension instead)
@Deprecated('Use PoiType.assetPath extension instead')
class POIConfiguration {
  /// Obtenir le chemin de l'asset pour un type de POI
  /// Utilise l'icône unique depuis Figma pour tous les types
  @Deprecated('Use PoiType.assetPath extension instead')
  static String getAssetPathForPOIType(PoiType type) {
    return type.assetPath;
  }

  /// Obtenir la couleur pour un type de POI
  @Deprecated('Use PoiType.color extension instead')
  static Color getColorForPOIType(PoiType type) {
    return type.color;
  }
}
