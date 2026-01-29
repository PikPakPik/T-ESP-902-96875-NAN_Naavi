import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HikingRoutesService {
  static const List<String> routeFiles = [
    'assets/maps/path_1.json',
    'assets/maps/path_2.json',
    'assets/maps/path_3.json',
  ];

  /// Charge toutes les randonnées depuis les fichiers JSON et les convertit en WKB
  static Future<List<Map<String, dynamic>>> loadAllRoutes() async {
    List<Map<String, dynamic>> allRoutes = [];

    for (int fileIndex = 0; fileIndex < routeFiles.length; fileIndex++) {
      String filePath = routeFiles[fileIndex];
      try {
        String jsonString = await rootBundle.loadString(filePath);
        Map<String, dynamic> geoJsonData = json.decode(jsonString);

        // Extraire les informations de la randonnée
        Map<String, dynamic> properties = geoJsonData['properties'] ?? {};
        List<dynamic> coordinates =
            geoJsonData['geometry']['coordinates'] ?? [];

        // Convertir en WKB simple
        String wkbHex = _createSimpleWKBFromCoordinates(coordinates);

        // Extraire les coordonnées de départ (premier point)
        double? startLat;
        double? startLon;
        if (coordinates.isNotEmpty &&
            coordinates[0] is List &&
            coordinates[0].length >= 2) {
          startLon = (coordinates[0][0] as num).toDouble();
          startLat = (coordinates[0][1] as num).toDouble();
        }

        if (wkbHex.isNotEmpty) {
          allRoutes.add({
            'wkb': wkbHex,
            'name':
                properties['alias'] ??
                properties['nomoffre'] ??
                'Randonnée ${fileIndex + 1}',
            'commune': properties['commune_nom'] ?? properties['commune'] ?? '',
            'difficulte': properties['difficulte'] ?? '',
            'duree': properties['duree']?.toString() ?? '',
            'distance': properties['lineaire']?.toString() ?? '',
            'type': properties['type_ffrp'] ?? '',
            'description':
                properties['descriptifsynthetique'] ??
                properties['descriptif'] ??
                '',
            'routeIndex': fileIndex,
            'startLat': startLat,
            'startLon': startLon,
            'coordinates': coordinates,
          });
        }
      } catch (e) {
        // Invalid route data is silently skipped
      }
    }

    return allRoutes;
  }

  /// Crée un WKB simple à partir des coordonnées (approche basique)
  static String _createSimpleWKBFromCoordinates(List<dynamic> coordinates) {
    try {
      if (coordinates.isEmpty) return '';

      // Créer un LineString basique en format WKB
      // Structure WKB pour LineString :
      // - Byte order (1 byte): 01 pour little endian
      // - Geometry type (4 bytes): 02000000 pour LineString
      // - Number of points (4 bytes)
      // - Points (16 bytes chacun : 8 pour X, 8 pour Y)

      List<int> wkbBytes = [];

      // Byte order (little endian)
      wkbBytes.add(0x01);

      // Geometry type (LineString = 2)
      wkbBytes.addAll([0x02, 0x00, 0x00, 0x00]);

      // Number of points
      int numPoints = coordinates.length;
      wkbBytes.addAll(_intToLittleEndianBytes(numPoints));

      // Points data
      for (var coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          double x = (coord[0] as num).toDouble();
          double y = (coord[1] as num).toDouble();
          wkbBytes.addAll(_doubleToLittleEndianBytes(x));
          wkbBytes.addAll(_doubleToLittleEndianBytes(y));
        }
      }

      // Convertir en hexadécimal
      return wkbBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    } catch (e) {
      return '';
    }
  }

  /// Convertit un int en bytes little endian (4 bytes)
  static List<int> _intToLittleEndianBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  /// Convertit un double en bytes little endian (8 bytes)
  static List<int> _doubleToLittleEndianBytes(double value) {
    final bytes = Float64List(1);
    bytes[0] = value;
    return bytes.buffer.asUint8List();
  }

  /// Récupère les strings WKB pour toutes les randonnées
  static Future<List<String>> getWKBStrings() async {
    final routes = await loadAllRoutes();
    return routes
        .map((route) => route['wkb'] as String)
        .where((wkb) => wkb.isNotEmpty)
        .toList();
  }

  /// Récupère les noms des randonnées
  static Future<List<String>> getRouteNames() async {
    final routes = await loadAllRoutes();
    return routes.map((route) => route['name'] as String).toList();
  }
}
