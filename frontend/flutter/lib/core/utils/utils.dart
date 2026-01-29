import 'package:flutter/foundation.dart';
import 'package:naavi/core/classes/HikeLine.dart';
import 'package:geobase/geobase.dart';

LineString decodeWKBFromString(String wkbHex) {
  try {
    // Convertir la chaîne hexadécimale en bytes
    final bytesList = <int>[];
    for (int i = 0; i < wkbHex.length; i += 2) {
      final hex = wkbHex.substring(i, i + 2);
      bytesList.add(int.parse(hex, radix: 16));
    }
    final bytes = Uint8List.fromList(bytesList);
    final geometry = LineString.decode(bytes, format: WKB.geometry);
    return geometry;
  } catch (e) {
    // Return an empty LineString on error
    return LineString.build(const []);
  }
}

List<LineString> decodeMultipleWKBFromStrings(List<String> wkbHexList) {
  final List<LineString> linestrings = [];

  for (int i = 0; i < wkbHexList.length; i++) {
    try {
      final linestring = decodeWKBFromString(wkbHexList[i]);
      linestrings.add(linestring);
    } catch (e) {
      // Invalid WKB data is silently skipped
    }
  }

  return linestrings;
}

/// Formate une durée en secondes en format lisible (ex: "2h 30min" ou "45min")
String formatDurationFromSeconds(int? seconds) {
  if (seconds == null || seconds <= 0) {
    return '?';
  }

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;

  if (hours > 0) {
    if (minutes > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${hours}h';
    }
  } else {
    return '${minutes}min';
  }
}

List<HikeLine> decodeMultipleWKBWithInfo(
  List<Map<String, dynamic>> wkbWithInfoList,
) {
  final List<HikeLine> hikes = [];

  for (int i = 0; i < wkbWithInfoList.length; i++) {
    try {
      final routeData = wkbWithInfoList[i];
      final wkbHex = routeData['wkb'] as String;
      final line = decodeWKBFromString(wkbHex);

      // Extract all route info from the data
      final info = Map<String, dynamic>.from(routeData);

      // Extract or create coordinates array from decoded WKB
      List<List<double>> coordinatesList;
      final existingCoordinates = routeData['coordinates'] as List<dynamic>?;

      if (existingCoordinates != null && existingCoordinates.isNotEmpty) {
        // Use existing coordinates if available
        coordinatesList = existingCoordinates
            .map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
            .toList();
      } else {
        // Extract coordinates from decoded WKB
        coordinatesList = [];
        for (int j = 0; j < line.chain.positionCount; j++) {
          final pos = line.chain[j];
          coordinatesList.add([pos.x, pos.y]);
        }
      }

      // Store coordinates in info for later use (guided tracking, etc.)
      info['coordinates'] = coordinatesList;

      // Extract start_point from first coordinate
      if (coordinatesList.isNotEmpty) {
        final firstPoint = coordinatesList[0];
        info['start_point'] = {
          'longitude': firstPoint[0],
          'latitude': firstPoint[1],
        };
      }

      // Keep WKB for detail page map display
      // Note: We now keep coordinates as they're needed for guided tracking

      // Ensure hikeIndex is set
      info['hikeIndex'] = i;

      hikes.add(HikeLine(line: line, info: info));
    } catch (e) {
      // Invalid hike data is silently skipped
    }
  }
  return hikes;
}
