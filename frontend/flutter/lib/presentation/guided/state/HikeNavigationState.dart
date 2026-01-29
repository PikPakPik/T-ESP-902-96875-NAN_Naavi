/// État de la navigation vers le point de départ d'une randonnée
/// Extrait de HomeMapExplorerPage pour isoler la logique de navigation pré-randonnée
sealed class HikeNavigationState {
  const HikeNavigationState();
}

/// Aucune navigation en cours
class HikeNavigationIdle extends HikeNavigationState {
  const HikeNavigationIdle();
}

/// Calcul de l'itinéraire en cours
class HikeNavigationCalculating extends HikeNavigationState {
  final double startLat;
  final double startLon;

  const HikeNavigationCalculating({
    required this.startLat,
    required this.startLon,
  });
}

/// Navigation active vers le point de départ
class HikeNavigationActive extends HikeNavigationState {
  final List<List<double>> route;
  final double distanceToStartKm;
  final double estimatedTimeMinutes;
  final double startLat;
  final double startLon;
  final Map<String, dynamic>? activeHikeInfo;
  final List<List<double>>? hikeRouteCoordinates;

  const HikeNavigationActive({
    required this.route,
    required this.distanceToStartKm,
    required this.estimatedTimeMinutes,
    required this.startLat,
    required this.startLon,
    this.activeHikeInfo,
    this.hikeRouteCoordinates,
  });

  HikeNavigationActive copyWith({
    List<List<double>>? route,
    double? distanceToStartKm,
    double? estimatedTimeMinutes,
    double? startLat,
    double? startLon,
    Map<String, dynamic>? activeHikeInfo,
    List<List<double>>? hikeRouteCoordinates,
  }) {
    return HikeNavigationActive(
      route: route ?? this.route,
      distanceToStartKm: distanceToStartKm ?? this.distanceToStartKm,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      startLat: startLat ?? this.startLat,
      startLon: startLon ?? this.startLon,
      activeHikeInfo: activeHikeInfo ?? this.activeHikeInfo,
      hikeRouteCoordinates: hikeRouteCoordinates ?? this.hikeRouteCoordinates,
    );
  }
}

/// Arrivé à proximité du point de départ (à moins de 20m)
/// Le bouton "Démarrer la randonnée" doit être affiché
class HikeNavigationNearStart extends HikeNavigationState {
  final List<List<double>> route;
  final double distanceToStartKm;
  final double startLat;
  final double startLon;
  final Map<String, dynamic>? activeHikeInfo;
  final List<List<double>>? hikeRouteCoordinates;

  const HikeNavigationNearStart({
    required this.route,
    required this.distanceToStartKm,
    required this.startLat,
    required this.startLon,
    this.activeHikeInfo,
    this.hikeRouteCoordinates,
  });
}

/// Erreur lors du calcul de l'itinéraire
class HikeNavigationError extends HikeNavigationState {
  final String message;

  const HikeNavigationError(this.message);
}
