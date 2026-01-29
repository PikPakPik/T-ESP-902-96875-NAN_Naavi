import 'package:geolocator/geolocator.dart' as gl;
import 'dart:math' as math;

/// État de la sélection d'itinéraire de randonnée
/// Extrait de HomeMapExplorerPage pour isoler la logique de chargement/sélection de routes
sealed class RouteSelectionState {
  const RouteSelectionState();
}

/// Chargement des itinéraires en cours
class RouteSelectionLoading extends RouteSelectionState {
  const RouteSelectionLoading();
}

/// Itinéraires chargés, aucune sélection
class RouteSelectionLoaded extends RouteSelectionState {
  final List<Map<String, dynamic>> routes;
  final List<String> wkbStrings;
  final List<String> routeNames;

  const RouteSelectionLoaded({
    required this.routes,
    required this.wkbStrings,
    required this.routeNames,
  });

  int get routeCount => routes.length;
}

/// Un itinéraire est sélectionné
class RouteSelectionSelected extends RouteSelectionState {
  final Map<String, dynamic> selectedHikeInfo;
  final List<Map<String, dynamic>> allRoutes;
  final List<String> wkbStrings;
  final List<String> routeNames;

  const RouteSelectionSelected({
    required this.selectedHikeInfo,
    required this.allRoutes,
    required this.wkbStrings,
    required this.routeNames,
  });

  /// Calcule la distance entre la position actuelle et le départ de la randonnée
  double? calculateDistanceToStart(gl.Position? currentPosition) {
    if (currentPosition == null) return null;

    final startLat = selectedHikeInfo['start_point']?['latitude'] as double?;
    final startLon = selectedHikeInfo['start_point']?['longitude'] as double?;

    if (startLat == null || startLon == null) return null;

    return _calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      startLat,
      startLon,
    );
  }

  /// Calcule la distance entre deux points géographiques (formule de Haversine)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

/// Erreur lors du chargement des itinéraires
class RouteSelectionError extends RouteSelectionState {
  final String message;

  const RouteSelectionError(this.message);
}
