import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/services/tracking/location_state_notifier.dart';
import '../../../core/services/tracking/tracking_location_service.dart';
import '../../../core/services/statistics/statistics_service.dart';
import '../../../core/services/tracking/camera_mode_service.dart';
import '../../../core/services/poi/poi_services.dart';
import '../../../core/services/map_service.dart';
import 'ImproviseHikeState.dart';

/// Gère le mode randonnée improvisation (randonnée libre)
/// Extrait de HomeMapExplorerPage (~150 lignes)
class ImproviseHikeStateNotifier extends StateNotifier<ImproviseHikeState> {
  final LocationStateNotifier locationStateNotifier;
  final TrackingLocationService trackingLocation;
  final StatisticsService? statisticsService;
  final CameraModeManager? cameraModeManager;
  final PoiService poiService;

  ImproviseHikeStateNotifier({
    required this.locationStateNotifier,
    required this.trackingLocation,
    this.statisticsService,
    this.cameraModeManager,
    required this.poiService,
  }) : super(const ImproviseHikeIdle());

  /// Démarre une randonnée en mode improvisation
  Future<void> startHike({
    required MapboxMap mapboxMap,
    required bool isMapReady,
  }) async {
    if (state is ImproviseHikeStarting || state is ImproviseHikeActive) {
      return;
    }

    state = const ImproviseHikeStarting();
    final startTime = DateTime.now();

    try {
      // Nettoyer et arrêter le tracking précédent (non-bloquant)
      trackingLocation.stopTracking();
      trackingLocation.clearTracking().ignore(); // Fire and forget

      // Démarrer le timer des statistiques et vider les POI (synchrone)
      statisticsService?.startTimer();
      poiService.clearHikePois();

      // Obtenir la position actuelle
      // D'abord essayer d'utiliser la position déjà disponible dans le state
      gl.Position? currentPosition =
          locationStateNotifier.state.currentPosition;

      // Si pas de position disponible, essayer de la récupérer rapidement
      if (currentPosition == null) {
        try {
          // Tentative avec timeout court pour ne pas bloquer
          currentPosition = await locationStateNotifier
              .getCurrentPosition()
              .timeout(
                const Duration(milliseconds: 500),
                onTimeout: () => null,
              );
        } catch (e) {
          // Intentionally empty catch block
        }
      }

      // Si toujours null, une seule tentative avec précision medium et timeout court
      if (currentPosition == null) {
        try {
          currentPosition =
              await gl.Geolocator.getCurrentPosition(
                locationSettings: const gl.LocationSettings(
                  accuracy: gl.LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 3),
                ),
              ).timeout(
                const Duration(seconds: 3),
                onTimeout: () => throw Exception('GPS timeout'),
              );
        } catch (e) {
          // Intentionally empty catch block
        }
      }

      if (currentPosition == null) {
        _handleStartError('GPS non disponible', [
          'Position GPS non disponible après retry',
        ]);
        return;
      }

      if (!isMapReady) {
        _handleStartError('Carte pas prête', [
          'La carte n\'est pas encore initialisée',
        ]);
        return;
      }

      if (cameraModeManager == null) {
        _handleStartError('Caméra non initialisée', [
          'Le gestionnaire de caméra n\'est pas disponible',
        ]);
        return;
      }

      // Lancer toutes les opérations en parallèle pour gagner du temps
      await Future.wait([
        cameraModeManager!.enableFirstPersonMode(currentPosition),
        trackingLocation.setStartPoint(currentPosition, mapboxMap),
        trackingLocation.startTracking(mapboxMap),
        MapService.setupNavigationArrow(
          mapboxMap,
        ), // Activer la flèche de navigation style AllTrails
      ]);

      // Garder isUserExploring = false pour que la rotation du compas fonctionne
      // et que le bouton "Recentrer" n'apparaisse pas (l'utilisateur n'a pas encore bougé la carte)
      trackingLocation.setUserExploring(false);

      // Transition vers Active
      state = ImproviseHikeActive(
        startPoint: currentPosition,
        startTime: startTime,
      );
    } catch (e) {
      // Intentionally empty catch block
      _handleStartError('Erreur lors du démarrage', ['Exception: $e']);
    }
  }

  /// Termine la randonnée improvisation
  Future<void> finishHike({
    required List<List<gl.Position>> segments,
    required double distanceKm,
    MapboxMap? mapboxMap,
  }) async {
    final currentState = state;

    if (currentState is! ImproviseHikeActive) {
      return;
    }

    // Calculer la durée AVANT de changer l'état (prend en compte accumulatedTime)
    final finalDuration = currentState.elapsedTime;

    // Arrêter le tracking
    trackingLocation.stopTracking();

    // NE PAS nettoyer le tracé - on veut le garder visible !
    // await trackingLocation.clearTracking(); // Commenté pour garder le tracé

    // Désactiver le mode première personne
    await cameraModeManager?.disableFirstPersonMode();

    // Masquer complètement le puck de localisation (pas de position utilisateur)
    if (mapboxMap != null) {
      await mapboxMap.location.updateSettings(
        LocationComponentSettings(enabled: false),
      );
    }

    // Obtenir la position actuelle comme point de fin
    final endPosition = await locationStateNotifier.getCurrentPosition();

    state = ImproviseHikeFinished(
      startPoint: currentState.startPoint,
      endPoint: endPosition,
      startTime: currentState.startTime,
      endTime: DateTime.now(),
      segments: segments,
      distanceKm: distanceKm,
      duration: finalDuration,
    );
  }

  /// Met en pause la randonnée (arrête le compteur de temps)
  void pause() {
    final currentState = state;
    if (currentState is ImproviseHikeActive && !currentState.isPaused) {
      state = currentState.pause();
    }
  }

  /// Reprend la randonnée après une pause
  void resume() {
    final currentState = state;
    if (currentState is ImproviseHikeActive && currentState.isPaused) {
      state = currentState.resume();
    }
  }

  /// Sort du mode première personne sans terminer la randonnée
  Future<void> exitFirstPersonMode() async {
    trackingLocation.stopTracking();
    await cameraModeManager?.disableFirstPersonMode();
  }

  /// Réinitialise l'état (après avoir vu le récapitulatif)
  Future<void> reset() async {
    // S'assurer que tout est bien nettoyé sur la carte
    await trackingLocation.clearTracking();
    state = const ImproviseHikeIdle();
  }

  /// Gère les erreurs de démarrage
  void _handleStartError(String message, List<String> reasons) {
    state = ImproviseHikeError(message: message, reasons: reasons);
  }

  /// Vérifie si une randonnée est active
  bool get isActive => state is ImproviseHikeActive;

  /// Vérifie si une randonnée est en cours de démarrage
  bool get isStarting => state is ImproviseHikeStarting;

  /// Vérifie si une randonnée est terminée
  bool get isFinished => state is ImproviseHikeFinished;
}
