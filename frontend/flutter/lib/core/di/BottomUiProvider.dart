import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/common/bottom_ui/BottomUiState.dart';
import '../../presentation/common/bottom_ui/BottomUiStateNotifier.dart';
import '../../presentation/common/poi_placement/PoiPlacementState.dart';

import './MapProviders.dart';
import '../../presentation/guided/state/GuidedHikeTrackingState.dart';
import '../../presentation/guided/state/HikeNavigationState.dart';
import '../../presentation/map/state/HomeMapState.dart';
import '../../presentation/map/state/HomeMapStateNotifier.dart';

/// Provider principal pour l'état de la zone UI bottom
final bottomUiStateProvider =
    StateNotifierProvider<BottomUiStateNotifier, BottomUiState>((ref) {
      return BottomUiStateNotifier();
    });

/// Provider pour tracker la fermeture du récapitulatif (pour afficher un loader)
final isClosingRecapProvider = StateProvider<bool>((ref) => false);

/// Provider pour tracker la fin de randonnée en cours (pour afficher un loader)
final isFinishingHikeProvider = StateProvider<bool>((ref) => false);

/// Provider pour gérer l'état d'expansion de la bottomsheet de tracking guidé
final guidedTrackingSheetExpandedProvider = StateProvider<bool>((ref) => true);

/// Provider pour les états overlay (NavigationInfo, Instructions, FloatingPOI)
final bottomUiOverlayProvider = Provider<BottomUiOverlayState>((ref) {
  final hikeNavState = ref.watch(hikeNavigationProvider);
  final guidedHikeState = ref.watch(guidedHikeTrackingProvider);
  final homeMapState = ref.watch(homeMapStateProvider);
  final poiPlacementState = ref.watch(poiPlacementProvider);
  final isPlacingPoi = ref.watch(isPlacingPoiProvider);

  // Calculer la visibilité de chaque overlay
  final showNavigationInfo =
      hikeNavState is HikeNavigationActive ||
      hikeNavState is HikeNavigationNearStart;
  final isNearStartPoint = hikeNavState is HikeNavigationNearStart;
  final showStartHikeButton = isNearStartPoint;
  final showNavigationInstructions =
      guidedHikeState is GuidedHikeTrackingActive && !guidedHikeState.isPaused;
  final showPoiButton =
      homeMapState == HomeMapState.explore &&
      !isPlacingPoi &&
      poiPlacementState is! PoiPlacementSelectingType;

  // Calculer la distance et le temps pour l'affichage
  double? navigationDistanceKm;
  double? navigationTimeMinutes;

  if (hikeNavState is HikeNavigationActive) {
    navigationDistanceKm = hikeNavState.distanceToStartKm;
    navigationTimeMinutes = hikeNavState.estimatedTimeMinutes;
  } else if (hikeNavState is HikeNavigationNearStart) {
    navigationDistanceKm = hikeNavState.distanceToStartKm;
    navigationTimeMinutes =
        null; // Pas de temps estimé quand on est à proximité
  }

  return BottomUiOverlayState(
    showNavigationInfo: showNavigationInfo,
    navigationDistanceKm: navigationDistanceKm,
    navigationTimeMinutes: navigationTimeMinutes,
    showNavigationInstructions: showNavigationInstructions,
    currentInstruction: guidedHikeState is GuidedHikeTrackingActive
        ? guidedHikeState.currentDirection
        : null,
    distanceToNextPoint: guidedHikeState is GuidedHikeTrackingActive
        ? guidedHikeState.distanceToNextWaypointMeters
        : null,
    showPoiButton: showPoiButton,
    showStartHikeButton: showStartHikeButton,
    isNearStartPoint: isNearStartPoint,
  );
});
