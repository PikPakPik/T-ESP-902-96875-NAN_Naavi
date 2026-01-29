import 'package:geolocator/geolocator.dart' as gl;

/// Type de direction pour la navigation
enum DirectionType {
  straight,
  slightLeft,
  left,
  sharpLeft,
  slightRight,
  right,
  sharpRight,
  uTurn,
  arrived,
}

/// État du suivi d'une randonnée guidée (turn-by-turn)
/// Extrait de HomeMapExplorerPage pour isoler la logique de guided hike tracking
sealed class GuidedHikeTrackingState {
  const GuidedHikeTrackingState();
}

/// Aucune randonnée guidée en cours
class GuidedHikeTrackingIdle extends GuidedHikeTrackingState {
  const GuidedHikeTrackingIdle();
}

/// Randonnée guidée en cours avec suivi turn-by-turn
class GuidedHikeTrackingActive extends GuidedHikeTrackingState {
  final List<List<double>> routeCoordinates; // Coordonnées du tracé
  final Map<String, dynamic>? hikeInfo; // Métadonnées de la randonnée
  final int currentWaypointIndex; // Index du waypoint actuel
  final String currentDirection; // Direction textuelle (ex: "Tournez à gauche")
  final DirectionType currentDirectionType; // Type de direction (enum)
  final double distanceToNextWaypointMeters; // Distance en mètres vers prochain waypoint
  final int elapsedSeconds; // Temps écoulé en secondes
  final double distanceKm; // Distance parcourue en km
  final bool isPaused; // Randonnée en pause
  final bool hasInitialCameraOriented; // Caméra orientée au démarrage

  const GuidedHikeTrackingActive({
    required this.routeCoordinates,
    this.hikeInfo,
    required this.currentWaypointIndex,
    required this.currentDirection,
    required this.currentDirectionType,
    required this.distanceToNextWaypointMeters,
    required this.elapsedSeconds,
    required this.distanceKm,
    this.isPaused = false,
    this.hasInitialCameraOriented = false,
  });

  /// Temps écoulé formaté en minutes:secondes
  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Distance formatée
  String get formattedDistance => '${distanceKm.toStringAsFixed(2)} km';

  /// Progression en pourcentage (basée sur le waypoint index)
  double get progressPercentage {
    if (routeCoordinates.isEmpty) return 0.0;
    return (currentWaypointIndex / (routeCoordinates.length - 1)) * 100;
  }

  GuidedHikeTrackingActive copyWith({
    List<List<double>>? routeCoordinates,
    Map<String, dynamic>? hikeInfo,
    int? currentWaypointIndex,
    String? currentDirection,
    DirectionType? currentDirectionType,
    double? distanceToNextWaypointMeters,
    int? elapsedSeconds,
    double? distanceKm,
    bool? isPaused,
    bool? hasInitialCameraOriented,
  }) {
    return GuidedHikeTrackingActive(
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      hikeInfo: hikeInfo ?? this.hikeInfo,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      currentDirection: currentDirection ?? this.currentDirection,
      currentDirectionType: currentDirectionType ?? this.currentDirectionType,
      distanceToNextWaypointMeters: distanceToNextWaypointMeters ?? this.distanceToNextWaypointMeters,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      isPaused: isPaused ?? this.isPaused,
      hasInitialCameraOriented: hasInitialCameraOriented ?? this.hasInitialCameraOriented,
    );
  }
}

/// Randonnée guidée terminée (prête pour le récapitulatif)
class GuidedHikeTrackingCompleted extends GuidedHikeTrackingState {
  final List<List<gl.Position>> segments; // Segments parcourus pour le recap
  final int elapsedSeconds; // Temps total
  final double distanceKm; // Distance totale
  final bool wasManuallyFinished; // Terminée manuellement ou automatiquement

  const GuidedHikeTrackingCompleted({
    required this.segments,
    required this.elapsedSeconds,
    required this.distanceKm,
    this.wasManuallyFinished = false,
  });

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '$minutes min $seconds s';
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(2)} km';
}
