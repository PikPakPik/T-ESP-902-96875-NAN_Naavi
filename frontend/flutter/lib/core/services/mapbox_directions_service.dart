import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service pour gérer les directions et le routing avec l'API Mapbox
class MapboxDirectionsService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5';

  /// Récupère un itinéraire piéton entre deux points
  /// Retourne une liste de coordonnées [lon, lat] formant le tracé
  static Future<List<List<double>>?> getWalkingRoute({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) async {
    return getWalkingRouteWithWaypoints(
      waypoints: [
        [fromLon, fromLat],
        [toLon, toLat],
      ],
    );
  }

  /// Récupère un itinéraire piéton passant par plusieurs waypoints
  /// waypoints: Liste de coordonnées [lon, lat] dans l'ordre du parcours
  /// Retourne une liste de coordonnées [lon, lat] formant le tracé complet
  static Future<List<List<double>>?> getWalkingRouteWithWaypoints({
    required List<List<double>> waypoints,
  }) async {
    try {
      if (waypoints.length < 2) {
        return null;
      }

      final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (accessToken == null) {
        return null;
      }

      // Construire les coordonnées pour l'URL
      // Format: /mapbox/walking/{lon1},{lat1};{lon2},{lat2};{lon3},{lat3}...
      final coordinatesString = waypoints
          .map((point) => '${point[0]},${point[1]}')
          .join(';');

      final url =
          Uri.parse(
            '$_baseUrl/mapbox/walking/$coordinatesString',
          ).replace(
            queryParameters: {
              'access_token': accessToken,
              'geometries': 'geojson',
              'overview': 'full',
              'steps': 'true',
            },
          );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];

          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;

            // Convertir en List<List<double>>
            final routeCoordinates = coordinates
                .map(
                  (coord) => [
                    (coord[0] as num).toDouble(),
                    (coord[1] as num).toDouble(),
                  ],
                )
                .toList();

            return routeCoordinates;
          }
        }

        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Extrait des points espacés régulièrement le long d'un tracé
  /// pour afficher des marqueurs de navigation
  static List<List<double>> extractWaypoints(
    List<List<double>> route, {
    int maxPoints = 20,
  }) {
    if (route.length <= maxPoints) {
      return route;
    }

    final waypoints = <List<double>>[];
    final step = route.length ~/ maxPoints;

    for (int i = 0; i < route.length; i += step) {
      waypoints.add(route[i]);
    }

    // Ajouter le dernier point si pas déjà inclus
    if (waypoints.last != route.last) {
      waypoints.add(route.last);
    }

    return waypoints;
  }
}
