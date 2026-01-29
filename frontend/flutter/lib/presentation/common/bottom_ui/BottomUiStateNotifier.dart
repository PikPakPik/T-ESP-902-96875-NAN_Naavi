import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import '../../common/poi_placement/PoiPlacementState.dart';
import '../../guided/state/GuidedHikeTrackingState.dart';
import '../../improvise/state/ImproviseHikeState.dart';
import '../../organized/state/OrganizedHikeState.dart';
import './BottomUiState.dart';
import '../../map/state/HomeMapState.dart';
import '../../guided/state/HikeNavigationState.dart';
import '../../improvise/state/StorageHikingState.dart';

/// Notifier qui orchestre l'état de la zone UI bottom
/// Écoute tous les providers existants et calcule l'état à afficher
class BottomUiStateNotifier extends StateNotifier<BottomUiState> {
  BottomUiStateNotifier() : super(const BottomUiIdle());

  /// Ordre de priorité (du plus au moins prioritaire) :
  /// 1. RecapHike (modal fullscreen)
  /// 2. GuidedHikeTracking (suivi actif)
  /// 3. OrganizedHike (organisation en cours) ← NOUVEAU
  /// 4. PoiPlacement (placement actif)
  /// 5. HikeDetail (randonnée sélectionnée)
  /// 6. ImproviseControls (mode improvise)
  /// 7. HikeModeButtons (mode explore par défaut)
  void updateState({
    required HomeMapState homeMapState,
    Map<String, dynamic>? selectedHikeInfo,
    double? distanceToHikeStart,
    required GuidedHikeTrackingState guidedHikeState,
    ImproviseHikeState? improviseHikeState,
    required HikeNavigationState hikeNavigationState,
    required PoiPlacementState poiPlacementState,
    required OrganizedHikeState organizedHikeState,
    required bool showRecapModal,
    required bool isPlacingPoi,
    gl.Position? currentPosition,
    List<List<gl.Position>>? improviseSegments,
    StorageHikingState? storageHikingState,
  }) {
    // PRIORITÉ 1 : Récapitulatif (bloque tout)
    if (showRecapModal || guidedHikeState is GuidedHikeTrackingCompleted) {
      // Déterminer les segments à afficher
      final segments = guidedHikeState is GuidedHikeTrackingCompleted
          ? guidedHikeState.segments
          : (improviseHikeState is ImproviseHikeFinished
                ? improviseHikeState.segments
                : improviseSegments ?? []);

      // Récupérer la durée si randonnée improvisée terminée
      final duration = improviseHikeState is ImproviseHikeFinished
          ? improviseHikeState.duration
          : null;

      state = BottomUiShowingRecap(
        segments: segments,
        fromGuidedHike: guidedHikeState is GuidedHikeTrackingCompleted,
        duration: duration,
      );
      return;
    }

    // PRIORITÉ 2 : Suivi randonnée guidée
    if (guidedHikeState is GuidedHikeTrackingActive && !isPlacingPoi) {
      // Calculer la vitesse moyenne (km/h) - seulement en mouvement (hors pauses)
      double averageSpeedKmh = 0.0;
      if (guidedHikeState.elapsedSeconds > 0) {
        averageSpeedKmh =
            (guidedHikeState.distanceKm / guidedHikeState.elapsedSeconds) *
            3600;
      }

      // Obtenir la vitesse actuelle depuis la position GPS
      double currentSpeedKmh = 0.0;
      if (currentPosition != null) {
        // Utiliser la vitesse GPS si disponible (certains GPS retournent -1 quand invalide)
        if (currentPosition.speed > 0) {
          currentSpeedKmh = currentPosition.speed * 3.6; // m/s to km/h
        }
      }

      // Obtenir l'altitude actuelle
      double currentAltitudeM = 0.0;
      if (currentPosition != null) {
        currentAltitudeM = currentPosition.altitude;
      }

      state = BottomUiShowingGuidedTracking(
        elapsedSeconds: guidedHikeState.elapsedSeconds,
        distanceKm: guidedHikeState.distanceKm,
        isPaused: guidedHikeState.isPaused,
        currentDirection: guidedHikeState.currentDirection,
        distanceToNextWaypointMeters:
            guidedHikeState.distanceToNextWaypointMeters,
        currentSpeedKmh: currentSpeedKmh,
        elevationM: 0.0, // TODO: Calculer le dénivelé pour le mode guidé
        averageSpeedKmh: averageSpeedKmh,
        currentAltitudeM: currentAltitudeM,
      );
      return;
    }

    // PRIORITÉ 3 : Organisation de randonnée ← NOUVEAU
    if (organizedHikeState is! OrganizedHikeIdle && !isPlacingPoi) {
      state = BottomUiShowingOrganizedHike(organizedState: organizedHikeState);
      return;
    }

    // PRIORITÉ 4 : Placement POI
    if (poiPlacementState is PoiPlacementActive) {
      state = BottomUiPlacingPoi(
        selectedType: poiPlacementState.selectedType,
        initialLatitude: currentPosition?.latitude ?? 0.0,
        initialLongitude: currentPosition?.longitude ?? 0.0,
      );
      return;
    }

    // PRIORITÉ 5 : Détail randonnée
    if (selectedHikeInfo != null) {
      final isNearby =
          distanceToHikeStart != null && distanceToHikeStart <= 5.0;
      state = BottomUiShowingHikeDetail(
        hikeInfo: selectedHikeInfo,
        distanceToStart: distanceToHikeStart,
        isNearby: isNearby,
      );
      return;
    }

    // PRIORITÉ 5 : Contrôles improvisation - utilise le même popup que les randonnées guidées
    if (homeMapState == HomeMapState.improvise &&
        improviseHikeState is ImproviseHikeActive &&
        !isPlacingPoi) {
      // Calculer la distance parcourue depuis les segments
      double distanceKm = 0.0;
      double totalElevationGain = 0.0;
      if (improviseSegments != null) {
        for (final segment in improviseSegments) {
          for (int i = 0; i < segment.length - 1; i++) {
            distanceKm +=
                gl.Geolocator.distanceBetween(
                  segment[i].latitude,
                  segment[i].longitude,
                  segment[i + 1].latitude,
                  segment[i + 1].longitude,
                ) /
                1000; // Convert to km

            // Calculer le dénivelé positif
            final elevationDiff = segment[i + 1].altitude - segment[i].altitude;
            if (elevationDiff > 0) {
              totalElevationGain += elevationDiff;
            }
          }
        }
      }

      // Calculer le temps écoulé
      final elapsedSeconds = improviseHikeState.elapsedTime.inSeconds;

      // Calculer la vitesse moyenne (km/h)
      double averageSpeedKmh = 0.0;
      if (elapsedSeconds > 0) {
        averageSpeedKmh = (distanceKm / elapsedSeconds) * 3600;
      }

      // Obtenir la dernière position du tracking (plus précise que currentPosition)
      gl.Position? trackingPosition;
      if (improviseSegments != null && improviseSegments.isNotEmpty) {
        final lastSegment = improviseSegments.last;
        if (lastSegment.isNotEmpty) {
          trackingPosition = lastSegment.last;
        }
      }

      // DEBUG LOGS - only in debug mode
      if (kDebugMode) {
        debugPrint('=== DEBUG IMPROVISE STATS ===');
        debugPrint(
          'improviseSegments: ${improviseSegments?.length ?? 0} segments',
        );
        if (improviseSegments != null) {
          for (int i = 0; i < improviseSegments.length; i++) {
            final seg = improviseSegments[i];
            debugPrint('  Segment $i: ${seg.length} points');
            if (seg.isNotEmpty) {
              debugPrint('    First point altitude: ${seg.first.altitude}');
              debugPrint('    Last point altitude: ${seg.last.altitude}');
              debugPrint('    Last point speed: ${seg.last.speed}');
            }
          }
        }
        debugPrint('trackingPosition: $trackingPosition');
        debugPrint('trackingPosition?.altitude: ${trackingPosition?.altitude}');
        debugPrint('trackingPosition?.speed: ${trackingPosition?.speed}');
        debugPrint('currentPosition?.altitude: ${currentPosition?.altitude}');
        debugPrint('currentPosition?.speed: ${currentPosition?.speed}');
        debugPrint('totalElevationGain: $totalElevationGain');
        debugPrint('=============================');
      }

      // Utiliser la position du tracking si disponible, sinon currentPosition
      final positionToUse = trackingPosition ?? currentPosition;

      // Obtenir la vitesse actuelle depuis la position GPS
      double currentSpeedKmh = 0.0;
      if (positionToUse != null) {
        // Utiliser la vitesse GPS si disponible (certains GPS retournent -1 quand invalide)
        if (positionToUse.speed > 0) {
          currentSpeedKmh = positionToUse.speed * 3.6; // m/s to km/h
        }
      }

      // Obtenir l'altitude actuelle depuis la position GPS
      double currentAltitudeM = 0.0;
      if (positionToUse != null) {
        currentAltitudeM = positionToUse.altitude;
      }

      // Vérifier si la randonnée est en pause
      final isPaused = storageHikingState is StorageHikingStatePaused;

      state = BottomUiShowingGuidedTracking(
        elapsedSeconds: elapsedSeconds,
        distanceKm: distanceKm,
        isPaused: isPaused,
        currentDirection: '', // Pas de direction pour l'improvisation
        distanceToNextWaypointMeters: 0, // Pas de waypoint pour l'improvisation
        currentSpeedKmh: currentSpeedKmh,
        elevationM: totalElevationGain,
        averageSpeedKmh: averageSpeedKmh,
        currentAltitudeM: currentAltitudeM,
      );
      return;
    }

    // PRIORITÉ 6 : Boutons mode (par défaut en explore)
    // Ne pas afficher si on est en navigation vers le point de départ
    final isNavigating =
        hikeNavigationState is HikeNavigationActive ||
        hikeNavigationState is HikeNavigationNearStart ||
        hikeNavigationState is HikeNavigationCalculating;

    if (homeMapState == HomeMapState.explore &&
        poiPlacementState is! PoiPlacementSelectingType &&
        !isPlacingPoi &&
        selectedHikeInfo == null &&
        !isNavigating) {
      state = const BottomUiShowingHikeModeButtons();
      return;
    }

    // Défaut : Idle
    state = const BottomUiIdle();
  }

  /// Méthode utilitaire pour afficher le récapitulatif
  void showRecap({
    required List<List<gl.Position>> segments,
    required bool fromGuidedHike,
  }) {
    state = BottomUiShowingRecap(
      segments: segments,
      fromGuidedHike: fromGuidedHike,
    );
  }

  /// Méthode utilitaire pour masquer le récapitulatif
  void hideRecap() {
    state = const BottomUiIdle();
  }
}
