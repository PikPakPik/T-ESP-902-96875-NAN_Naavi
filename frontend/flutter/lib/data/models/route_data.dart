import 'package:flutter/material.dart';
import 'package:geobase/geobase.dart' as geobase;
import 'package:naavi/core/classes/HikeLine.dart';

/// Simple position class for map coordinates
class MapPosition {
  final double longitude;
  final double latitude;

  const MapPosition({required this.longitude, required this.latitude});

  double get x => longitude;
  double get y => latitude;
}

/// Data structure for static routes functionality
class StaticRoutesData {
  final List<String> wkbStrings;
  final List<String>? routeNames;
  final List<Map<String, dynamic>>? routesData;
  final void Function(Map<String, dynamic> info)? onHikeSelected;

  const StaticRoutesData({
    required this.wkbStrings,
    this.routeNames,
    this.routesData,
    this.onHikeSelected,
  });

  bool get hasRoutes => wkbStrings.isNotEmpty;
}

/// Individual route information
class RouteInfo {
  final String id;
  final String name;
  final geobase.LineString lineString;
  final HikeLine hikeLine;
  final Color color;
  final bool isHighlighted;

  const RouteInfo({
    required this.id,
    required this.name,
    required this.lineString,
    required this.hikeLine,
    required this.color,
    this.isHighlighted = false,
  });

  RouteInfo copyWith({
    String? id,
    String? name,
    geobase.LineString? lineString,
    HikeLine? hikeLine,
    Color? color,
    bool? isHighlighted,
  }) {
    return RouteInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      lineString: lineString ?? this.lineString,
      hikeLine: hikeLine ?? this.hikeLine,
      color: color ?? this.color,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }
}

/// Bounds for fitting camera to routes
class RouteBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const RouteBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  double get latSpan => maxLat - minLat;
  double get lonSpan => maxLon - minLon;
  double get maxSpan => latSpan > lonSpan ? latSpan : lonSpan;

  MapPosition get center => MapPosition(
    longitude: (minLon + maxLon) / 2,
    latitude: (minLat + maxLat) / 2,
  );

  double calculateZoom({double padding = 0.2}) {
    // Calculer les spans avec padding (marge de 20% par défaut)
    final paddedLatSpan = latSpan * (1.0 + padding);
    final paddedLonSpan = lonSpan * (1.0 + padding);
    final paddedMaxSpan = paddedLatSpan > paddedLonSpan
        ? paddedLatSpan
        : paddedLonSpan;

    // Logique de zoom plus fine et adaptative
    if (paddedMaxSpan < 0.001) return 17.0; // Très petit tracé
    if (paddedMaxSpan < 0.005) return 15.5; // Petit tracé
    if (paddedMaxSpan < 0.01) return 14.5; // Tracé court
    if (paddedMaxSpan < 0.025) return 13.5; // Tracé moyen-court
    if (paddedMaxSpan < 0.05) return 12.5; // Tracé moyen
    if (paddedMaxSpan < 0.1) return 11.5; // Tracé moyen-long
    if (paddedMaxSpan < 0.2) return 10.5; // Tracé long
    if (paddedMaxSpan < 0.5) return 9.5; // Tracé très long
    if (paddedMaxSpan < 1.0) return 8.5; // Tracé énorme
    return 7.5; // Tracé gigantesque
  }

  /// Calcule un zoom adapté pour une vue détaillée d'une seule route
  double calculateSingleRouteZoom() {
    // Protection contre la division par zéro
    if (latSpan == 0 || lonSpan == 0) {
      return calculateZoom(padding: 0.15);
    }

    // Calculer le ratio largeur/hauteur pour adapter le zoom
    final aspectRatio = lonSpan / latSpan;

    // Ajuster le padding selon la forme du tracé
    double adaptivePadding;
    if (aspectRatio > 3.0 || aspectRatio < 0.33) {
      // Tracé très allongé (horizontal ou vertical) - plus de padding
      adaptivePadding = 0.25;
    } else if (aspectRatio > 2.0 || aspectRatio < 0.5) {
      // Tracé modérément allongé - padding moyen
      adaptivePadding = 0.20;
    } else {
      // Tracé plutôt carré - moins de padding pour être plus proche
      adaptivePadding = 0.15;
    }

    return calculateZoom(padding: adaptivePadding);
  }
}
