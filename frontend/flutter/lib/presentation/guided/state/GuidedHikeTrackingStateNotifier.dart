import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'GuidedHikeTrackingState.dart';
import '../../../core/services/geometry/geometry_calculation_service.dart';
import '../../../core/di/MapProviders.dart';
import '../../../core/di/HomeMapProvider.dart';

/// Gère le suivi turn-by-turn d'une randonnée guidée
/// Extrait de HomeMapExplorerPage (~300 lignes)
class GuidedHikeTrackingStateNotifier
    extends StateNotifier<GuidedHikeTrackingState> {
  Timer? _hikeTimer;
  final Ref _ref;

  GuidedHikeTrackingStateNotifier(this._ref)
    : super(const GuidedHikeTrackingIdle());

  /// Démarre le suivi d'une randonnée guidée
  void startTracking({
    required List<List<double>> routeCoordinates,
    Map<String, dynamic>? hikeInfo,
  }) {
    if (routeCoordinates.isEmpty) {
      return;
    }

    // Calculer la direction initiale
    final initialDirection = _calculateDirectionWithType(routeCoordinates, 0);

    state = GuidedHikeTrackingActive(
      routeCoordinates: routeCoordinates,
      hikeInfo: hikeInfo,
      currentWaypointIndex: 0,
      currentDirection: initialDirection['text'] as String,
      currentDirectionType: initialDirection['type'] as DirectionType,
      distanceToNextWaypointMeters: initialDirection['distance'] as double,
      elapsedSeconds: 0,
      distanceKm: 0.0,
      hasInitialCameraOriented: false,
    );

    // Activer le mode première personne de la caméra
    _activateFirstPersonMode();

    // Démarrer le timer
    _startTimer();

  }

  /// Active le mode première personne de la caméra
  Future<void> _activateFirstPersonMode() async {
    try {
      // Récupérer la position actuelle
      final locationState = _ref.read(locationStateProvider);
      final currentPosition = locationState.currentPosition;

      if (currentPosition == null) {
        return;
      }

      // Récupérer le CameraModeManager
      final cameraModeManager = _ref.read(cameraModeManagerProvider);
      if (cameraModeManager == null) {
        return;
      }

      // Activer le mode première personne
      await cameraModeManager.enableFirstPersonMode(currentPosition);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Démarre le timer périodique
  void _startTimer() {
    _hikeTimer?.cancel();
    _hikeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = state;

      if (currentState is! GuidedHikeTrackingActive) {
        timer.cancel();
        return;
      }

      if (!currentState.isPaused) {
        // Incrémenter le temps écoulé
        state = currentState.copyWith(
          elapsedSeconds: currentState.elapsedSeconds + 1,
        );
      }
    });
  }

  /// Met à jour la direction en fonction de la position actuelle
  void updatePosition(gl.Position currentPosition) {
    final currentState = state;

    if (currentState is! GuidedHikeTrackingActive) return;

    // Mettre à jour la caméra si le mode première personne est actif
    _updateCameraPosition(currentPosition);

    // Trouver le waypoint le plus proche
    double minDistance = double.infinity;
    int closestIndex = currentState.currentWaypointIndex;

    for (
      int i = currentState.currentWaypointIndex;
      i < currentState.routeCoordinates.length;
      i++
    ) {
      final waypoint = currentState.routeCoordinates[i];
      final distance = gl.Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        waypoint[1], // latitude
        waypoint[0], // longitude
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }

      // Si on s'éloigne, arrêter la recherche
      if (distance > minDistance + 50) break;
    }

    // Si on a atteint un nouveau waypoint, mettre à jour la distance parcourue
    if (closestIndex > currentState.currentWaypointIndex) {
      double additionalDistance = 0.0;

      // Calculer la distance entre l'ancien et le nouveau waypoint
      for (int i = currentState.currentWaypointIndex; i < closestIndex; i++) {
        final from = currentState.routeCoordinates[i];
        final to = currentState.routeCoordinates[i + 1];
        final segmentDistance = gl.Geolocator.distanceBetween(
          from[1],
          from[0],
          to[1],
          to[0],
        );
        additionalDistance += segmentDistance / 1000; // Convertir en km
      }

      // Calculer la nouvelle direction
      final directionInfo = _calculateDirectionWithType(
        currentState.routeCoordinates,
        closestIndex,
      );

      state = currentState.copyWith(
        currentWaypointIndex: closestIndex,
        distanceKm: currentState.distanceKm + additionalDistance,
        currentDirection: directionInfo['text'] as String,
        currentDirectionType: directionInfo['type'] as DirectionType,
        distanceToNextWaypointMeters: directionInfo['distance'] as double,
      );

    } else {
      // Mettre à jour seulement la distance vers le prochain waypoint
      if (closestIndex < currentState.routeCoordinates.length - 1) {
        final nextWaypoint = currentState.routeCoordinates[closestIndex + 1];
        final distanceToNext = gl.Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          nextWaypoint[1],
          nextWaypoint[0],
        );

        state = currentState.copyWith(
          distanceToNextWaypointMeters: distanceToNext,
        );
      }
    }

    // Vérifier si on a terminé (à moins de 30m du dernier point)
    if (closestIndex >= currentState.routeCoordinates.length - 1 &&
        minDistance < 30) {
      stopTracking(completed: true);
    }
  }

  /// Calcule la direction à prendre vers le prochain waypoint avec type et distance
  Map<String, dynamic> _calculateDirectionWithType(
    List<List<double>> routeCoordinates,
    int waypointIndex,
  ) {
    if (waypointIndex >= routeCoordinates.length - 1) {
      return {
        'text': 'Vous êtes arrivé !',
        'type': DirectionType.arrived,
        'distance': 0.0,
      };
    }

    final currentLon = routeCoordinates[waypointIndex][0];
    final currentLat = routeCoordinates[waypointIndex][1];
    final nextLon = routeCoordinates[waypointIndex + 1][0];
    final nextLat = routeCoordinates[waypointIndex + 1][1];

    // Calculer la distance vers le prochain point
    final distanceMeters = gl.Geolocator.distanceBetween(
      currentLat,
      currentLon,
      nextLat,
      nextLon,
    );

    // Calculer l'angle et convertir en direction via le service
    final angle = GeometryCalculationService.calculateBearing(
      currentLat,
      currentLon,
      nextLat,
      nextLon,
    );

    final type = GeometryCalculationService.angleToDirectionType(angle);
    final text = GeometryCalculationService.directionTypeToText(type);

    return {'text': text, 'type': type, 'distance': distanceMeters};
  }

  /// Met la pause sur la randonnée
  void pause() {
    final currentState = state;

    if (currentState is GuidedHikeTrackingActive && !currentState.isPaused) {
      state = currentState.copyWith(isPaused: true);
    }
  }

  /// Reprend la randonnée
  void resume() {
    final currentState = state;

    if (currentState is GuidedHikeTrackingActive && currentState.isPaused) {
      state = currentState.copyWith(isPaused: false);
    }
  }

  /// Arrête le suivi de la randonnée
  void stopTracking({bool completed = false}) {
    final currentState = state;

    if (currentState is! GuidedHikeTrackingActive) {
      return;
    }

    // Arrêter le timer
    _hikeTimer?.cancel();
    _hikeTimer = null;

    // Désactiver le mode première personne de la caméra
    _disableFirstPersonMode();

    // Créer les segments pour le récapitulatif
    final segments = _createSegmentsFromGuidedHike(
      currentState.routeCoordinates,
      currentState.currentWaypointIndex,
    );

    state = GuidedHikeTrackingCompleted(
      segments: segments,
      elapsedSeconds: currentState.elapsedSeconds,
      distanceKm: currentState.distanceKm,
      wasManuallyFinished: !completed,
    );

    if (completed) {
    } else {
    }
  }

  /// Crée des segments pour RecapHike à partir d'une randonnée guidée
  List<List<gl.Position>> _createSegmentsFromGuidedHike(
    List<List<double>> routeCoordinates,
    int currentWaypointIndex,
  ) {
    if (routeCoordinates.isEmpty || currentWaypointIndex == 0) {
      return [];
    }

    // Créer un seul segment avec la portion parcourue
    final segment = <gl.Position>[];

    for (
      int i = 0;
      i <= currentWaypointIndex && i < routeCoordinates.length;
      i++
    ) {
      final coord = routeCoordinates[i];
      segment.add(
        gl.Position(
          latitude: coord[1],
          longitude: coord[0],
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
    }

    return [segment];
  }

  /// Marque la caméra comme ayant été orientée au démarrage
  void markCameraOriented() {
    final currentState = state;

    if (currentState is GuidedHikeTrackingActive &&
        !currentState.hasInitialCameraOriented) {
      state = currentState.copyWith(hasInitialCameraOriented: true);
    }
  }

  /// Met à jour la position de la caméra
  Future<void> _updateCameraPosition(gl.Position position) async {
    try {
      final cameraModeManager = _ref.read(cameraModeManagerProvider);
      if (cameraModeManager != null && cameraModeManager.isFirstPersonMode) {
        await cameraModeManager.updateCamera(position);
      }
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Désactive le mode première personne de la caméra
  Future<void> _disableFirstPersonMode() async {
    try {
      final cameraModeManager = _ref.read(cameraModeManagerProvider);
      if (cameraModeManager != null && cameraModeManager.isFirstPersonMode) {
        await cameraModeManager.disableFirstPersonMode();
      }
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Réinitialise l'état (après avoir vu le récapitulatif)
  void reset() {
    state = const GuidedHikeTrackingIdle();
  }

  /// Vérifie si une randonnée est active
  bool get isActive => state is GuidedHikeTrackingActive;

  /// Vérifie si une randonnée est terminée
  bool get isCompleted => state is GuidedHikeTrackingCompleted;

  @override
  void dispose() {
    _hikeTimer?.cancel();
    super.dispose();
  }
}
