import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/di/BottomUiProvider.dart';
import '../../../core/di/StorageHikingProvider.dart';
import '../../../core/resources/colors.dart';
import '../../guided/widget/hike_detail_bottom_sheet.dart';
import '../../explorer/widget/hike_mode_buttons.dart';
import '../../improvise/widget/improvise_controls.dart';
import '../../improvise/widget/improvise_tracking_sheet.dart';
import '../../guided/widget/guided_tracking_sheet.dart';
import '../../organized/state/OrganizedHikeState.dart';
import '../../organized/widget/OrganizedDraggableStartSelectionSheet.dart';
import '../../organized/widget/OrganizedDraggableWaypointSheet.dart';
import '../recap/recap_hike_sheet.dart';
import '../poi_placement/poi_placement_sheet.dart';
import '../../../data/models/user_poi.dart';
import '../../../core/di/HomeMapProvider.dart';
import '../../../core/di/MapProviders.dart';
import '../../../core/di/RecapHikeProvider.dart';
import '../../../core/services/poi/poi_display_service.dart';
import '../../../core/services/map/map_camera_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/utils/route_popup_helper.dart';
import '../../map/state/HomeMapState.dart';
import '../../map/state/HomeMapStateNotifier.dart';
import '../../guided/state/GuidedHikeTrackingState.dart';
import '../../improvise/state/ImproviseHikeState.dart';
import '../../improvise/state/StorageHikingState.dart';
import '../../hike/HikeDetailPage.dart';
import 'BottomUiState.dart';

/// Widget orchestrateur pour la zone UI bottom
/// Affiche le bon widget selon l'état du bottomUiStateProvider
class BottomUiContainer extends ConsumerWidget {
  final MapboxMap? mapboxMapController;
  final gl.Position? currentPosition;
  final VoidCallback onOpenPoiTypeSelection;
  final VoidCallback? onStartNavigationToHike;

  const BottomUiContainer({
    super.key,
    required this.mapboxMapController,
    this.currentPosition,
    required this.onOpenPoiTypeSelection,
    this.onStartNavigationToHike,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomUiState = ref.watch(bottomUiStateProvider);

    // Return bottom-aligned widgets without Positioned
    // The parent Stack in HomeMapExplorerPage will handle positioning
    return Align(
      alignment: Alignment.bottomCenter,
      child: switch (bottomUiState) {
        BottomUiIdle() => const SizedBox.shrink(),

        BottomUiShowingHikeDetail(
          hikeInfo: final hikeInfo,
          distanceToStart: final distance,
          isNearby: final isNearby,
        ) =>
          HikeDetailBottomSheet(
            hikeInfo: hikeInfo,
            distance: distance,
            isNearby: isNearby,
            onClose: () => _handleCloseHikeDetail(ref),
            onLaunch: () => _handleLaunchHike(ref, hikeInfo),
            onAddPoi: onOpenPoiTypeSelection,
            onShowDetails: () => _handleShowHikeDetails(context, hikeInfo),
          ),

        BottomUiShowingGuidedTracking(
          elapsedSeconds: final elapsed,
          distanceKm: final distance,
          isPaused: final isPaused,
          currentDirection: _,
          distanceToNextWaypointMeters: _,
          currentSpeedKmh: final currentSpeed,
          elevationM: final elevation,
          averageSpeedKmh: final avgSpeed,
          currentAltitudeM: final currentAltitude,
        ) =>
          _buildGuidedTrackingSheet(
            ref,
            elapsed,
            distance,
            isPaused,
            currentSpeed,
            elevation,
            avgSpeed,
            currentAltitude,
          ),

        BottomUiShowingHikeModeButtons() => const HikeModeButtons(),

        BottomUiShowingOrganizedHike(organizedState: final orgState) =>
          _buildOrganizedHikeContent(context, ref, orgState),

        BottomUiShowingImproviseControls(currentPosition: final position) =>
          ImproviseControls(
            currentPosition: position,
            mapboxMapController: mapboxMapController,
            onOpenPoiTypeSelection: onOpenPoiTypeSelection,
          ),

        BottomUiShowingRecap(
          segments: final segments,
          fromGuidedHike: _,
          duration: final duration,
        ) =>
          RecapHikeSheet(
            segments: segments,
            duration: duration,
            onClose: () => _handleCloseRecap(ref),
            onNavigateToPoi: (poi) => _handleNavigateToPoi(poi),
          ),

        BottomUiPlacingPoi(
          selectedType: final poiType,
          initialLatitude: final lat,
          initialLongitude: final lng,
        ) =>
          PoiPlacementSheet(
            poiType: poiType,
            mapboxMap: mapboxMapController!,
            initialLatitude: lat,
            initialLongitude: lng,
            onPlacePoi: (latitude, longitude) =>
                _handlePlacePoi(ref, latitude, longitude),
            onCancel: () => _handleCancelPoiPlacement(ref),
          ),
      },
    );
  }

  /// Gère la fermeture du détail de randonnée
  void _handleCloseHikeDetail(WidgetRef ref) async {
    ref.read(routeSelectionProvider.notifier).deselectRoute();
    await RoutePopupHelper.onPopupClosed();
  }

  /// Gère le lancement d'une randonnée
  void _handleLaunchHike(WidgetRef ref, Map<String, dynamic> hikeInfo) {
    onStartNavigationToHike?.call();
  }

  /// Construit le popup de tracking (guided OU improvise)
  Widget _buildGuidedTrackingSheet(
    WidgetRef ref,
    int elapsed,
    double distance,
    bool isPaused,
    double currentSpeed,
    double elevation,
    double avgSpeed,
    double currentAltitude,
  ) {
    // Déterminer si on est en mode improvise ou guided
    final homeMapState = ref.watch(homeMapStateProvider);
    final isImproviseMode = homeMapState == HomeMapState.improvise;

    // Utiliser ImproviseTrackingSheet pour le mode improvise
    if (isImproviseMode) {
      return ImproviseTrackingSheet(
        elapsedSeconds: elapsed,
        distanceKm: distance,
        isPaused: isPaused,
        currentSpeedKmh: currentSpeed,
        elevationM: elevation,
        averageSpeedKmh: avgSpeed,
        currentAltitudeM: currentAltitude,
        onFinish: () => _handleFinishImproviseHike(ref),
        onPauseResume: () => _handlePauseResumeImproviseHike(ref),
        onCancel: () => _handleCancelImproviseHike(ref),
        isExpanded: ref.watch(guidedTrackingSheetExpandedProvider),
        onExpandedChanged: (expanded) {
          ref.read(guidedTrackingSheetExpandedProvider.notifier).state =
              expanded;
        },
      );
    }

    // Utiliser GuidedTrackingSheet pour le mode guidé
    return GuidedTrackingSheet(
      elapsedSeconds: elapsed,
      distanceKm: distance,
      isPaused: isPaused,
      currentSpeedKmh: currentSpeed,
      elevationM: elevation,
      averageSpeedKmh: avgSpeed,
      currentAltitudeM: currentAltitude,
      onFinish: () => _handleFinishGuidedHike(ref),
      onPauseResume: () => _handlePauseResumeGuidedHike(ref),
      onCancel: () => _handleCancelGuidedHike(ref),
      isExpanded: ref.watch(guidedTrackingSheetExpandedProvider),
      onExpandedChanged: (expanded) {
        ref.read(guidedTrackingSheetExpandedProvider.notifier).state = expanded;
      },
    );
  }

  /// Gère l'affichage des détails de randonnée
  void _handleShowHikeDetails(
    BuildContext context,
    Map<String, dynamic> hikeInfo,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HikeDetailPage(
          hikeInfo: hikeInfo,
          onStart: () async {
            onStartNavigationToHike?.call();
          },
        ),
      ),
    );
  }

  /// Gère la fin d'une randonnée guidée
  void _handleFinishGuidedHike(WidgetRef ref) {
    ref
        .read(guidedHikeTrackingProvider.notifier)
        .stopTracking(completed: false);
  }

  /// Gère pause/resume de la randonnée guidée
  void _handlePauseResumeGuidedHike(WidgetRef ref) async {
    final guidedHikeState = ref.read(guidedHikeTrackingProvider);
    if (guidedHikeState is GuidedHikeTrackingActive) {
      if (guidedHikeState.isPaused) {
        // Reprise : réactiver le mode première personne
        ref.read(guidedHikeTrackingProvider.notifier).resume();

        final cameraModeManager = ref.read(cameraModeManagerProvider);
        final currentPosition = ref.read(locationStateProvider).currentPosition;

        if (cameraModeManager != null && currentPosition != null) {
          await cameraModeManager.enableFirstPersonMode(currentPosition);
        }
      } else {
        // Pause : remettre la caméra en mode normal
        ref.read(guidedHikeTrackingProvider.notifier).pause();

        final cameraModeManager = ref.read(cameraModeManagerProvider);
        final currentPosition = ref.read(locationStateProvider).currentPosition;

        if (cameraModeManager != null && currentPosition != null) {
          await cameraModeManager.disableFirstPersonMode();
        }
      }
    }
  }

  /// Gère la terminaison d'une randonnée guidée (avec affichage du tracé)
  void _handleCancelGuidedHike(WidgetRef ref) async {
    final guidedNotifier = ref.read(guidedHikeTrackingProvider.notifier);
    final trackingLocation = ref.read(trackingLocationProvider);
    final cameraModeManager = ref.read(cameraModeManagerProvider);

    // Arrêter la boussole (provider)
    ref.read(compassProvider.notifier).stopListening();

    // Désactiver le mode première personne (arrête aussi le compass interne)
    await cameraModeManager?.disableFirstPersonMode();

    // Remettre le puck de localisation par défaut (enlever la flèche de navigation)
    if (mapboxMapController != null) {
      await MapService.setupLocationComponent(mapboxMapController!);
    }

    // Récupérer les segments avant de terminer
    final segments = trackingLocation.getAllSegments();

    // Arrêter le tracking et afficher le récap
    guidedNotifier.stopTracking(completed: true);

    // Cadrer la caméra sur l'entièreté du parcours
    if (mapboxMapController != null && segments.isNotEmpty) {
      await MapCameraService.fitToRoute(
        mapboxMapController!,
        segments: segments,
        padding: MbxEdgeInsets(top: 100, left: 50, bottom: 500, right: 50),
      );
    }
  }

  /// Gère la fin d'une randonnée improvisation
  void _handleFinishImproviseHike(WidgetRef ref) async {
    // Read all providers before async operations
    final trackingLocation = ref.read(trackingLocationProvider);
    final improviseHikeNotifier = ref.read(improviseHikeProvider.notifier);
    final locationStateNotifier = ref.read(locationStateProvider.notifier);
    final statisticsService = ref.read(statisticsServiceProvider);

    try {
      // Arrêter le chronomètre pour calculer la durée finale
      statisticsService.stopTimer();

      // Récupérer la position actuelle
      final currentPosition = await locationStateNotifier.getCurrentPosition();

      // Définir le point d'arrivée
      await trackingLocation.setEndPoint(currentPosition, mapboxMapController);

      // Récupérer les segments AVANT de terminer
      final segments = trackingLocation.getAllSegments();

      // Calculate approximate distance (sum of segment distances)
      double distanceKm = 0.0;
      for (final segment in segments) {
        for (int i = 0; i < segment.length - 1; i++) {
          distanceKm +=
              gl.Geolocator.distanceBetween(
                segment[i].latitude,
                segment[i].longitude,
                segment[i + 1].latitude,
                segment[i + 1].longitude,
              ) /
              1000; // Convert to km
        }
      }

      // Terminer la randonnée
      await improviseHikeNotifier.finishHike(
        segments: segments,
        distanceKm: distanceKm,
        mapboxMap: mapboxMapController,
      );

      // Arrêter la boussole (provider)
      ref.read(compassProvider.notifier).stopListening();

      // Désactiver le mode première personne (arrête aussi le compass interne)
      final cameraModeManager = ref.read(cameraModeManagerProvider);
      await cameraModeManager?.disableFirstPersonMode();

      // Cadrer la caméra sur l'entièreté du parcours
      if (mapboxMapController != null) {
        await MapCameraService.fitToRoute(
          mapboxMapController!,
          segments: segments,
          padding: MbxEdgeInsets(top: 100, left: 50, bottom: 500, right: 50),
        );
      }
    } catch (e) {
      // Handle errors silently - state will be updated by notifier
    }
  }

  /// Gère pause/resume de la randonnée improvisation
  void _handlePauseResumeImproviseHike(WidgetRef ref) async {
    final trackingLocation = ref.read(trackingLocationProvider);
    final storageHikingState = ref.read(storageHikingProvider);
    final improviseNotifier = ref.read(improviseHikeProvider.notifier);
    final statisticsService = ref.read(statisticsServiceProvider);

    if (storageHikingState is StorageHikingStatePaused) {
      // Reprendre
      trackingLocation.continueTracking();
      ref.read(storageHikingProvider.notifier).startHike();
      ref.read(cameraStateProvider.notifier).setUserExploring(false);

      // Reprendre le compteur de temps
      improviseNotifier.resume();
      statisticsService.resumeTimer();

      // Redémarrer la boussole
      ref.read(compassProvider.notifier).startListening();
    } else {
      // Mettre en pause le compteur de temps
      improviseNotifier.pause();
      statisticsService.pauseTimer();

      // Mettre en pause le tracking
      final currentPath = await trackingLocation.getCurrentPath();
      trackingLocation.pauseTracking();
      ref.read(cameraStateProvider.notifier).setUserExploring(true);

      final improviseHikeState = ref.read(improviseHikeProvider);
      if (improviseHikeState is ImproviseHikeActive) {
        final startPoint = improviseHikeState.startPoint;
        if (currentPath.isNotEmpty) {
          await ref
              .read(storageHikingProvider.notifier)
              .pausedHike(
                startPoint.latitude,
                startPoint.longitude,
                currentPath,
              );
        } else {
          ref.read(storageHikingProvider.notifier).pauseHike();
        }
      } else {
        ref.read(storageHikingProvider.notifier).pauseHike();
      }

      // Arrêter la boussole
      ref.read(compassProvider.notifier).stopListening();

      // Configurer les types de POI pour improvise hike
      ref.read(poiServiceProvider).setPoiTypesImproviseHike();
    }
  }

  /// Gère l'annulation d'une randonnée improvisation (retour à la carte sans récap)
  void _handleCancelImproviseHike(WidgetRef ref) async {
    final trackingLocation = ref.read(trackingLocationProvider);
    final improviseHikeNotifier = ref.read(improviseHikeProvider.notifier);
    final cameraModeManager = ref.read(cameraModeManagerProvider);
    final homeMapNotifier = ref.read(homeMapStateProvider.notifier);
    final statisticsService = ref.read(statisticsServiceProvider);

    try {
      // Arrêter le chronomètre
      statisticsService.stopTimer();

      // Arrêter la boussole (provider)
      ref.read(compassProvider.notifier).stopListening();

      // Désactiver le mode première personne (arrête aussi le compass interne)
      await cameraModeManager?.disableFirstPersonMode();

      // Remettre le puck de localisation par défaut (enlever la flèche de navigation)
      if (mapboxMapController != null) {
        await MapService.setupLocationComponent(mapboxMapController!);
      }

      // Nettoyer le tracé sur la carte
      await trackingLocation.clearTracking();

      // Réinitialiser l'état improvise (sans passer par finishHike)
      await improviseHikeNotifier.reset();

      // Retourner en mode exploration
      homeMapNotifier.updateState(HomeMapState.explore);

      // Réafficher le puck de localisation
      if (mapboxMapController != null) {
        await mapboxMapController!.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            puckBearingEnabled: true,
            puckBearing: PuckBearing.HEADING,
            pulsingEnabled: true,
            showAccuracyRing: true,
          ),
        );
      }
    } catch (e) {
      // Handle errors silently
    }
  }

  /// Gère la fermeture du récapitulatif
  void _handleCloseRecap(WidgetRef ref) async {
    // Read notifiers before async operations
    final trackingLocation = ref.read(trackingLocationProvider);
    final guidedHikeState = ref.read(guidedHikeTrackingProvider);
    final improviseHikeState = ref.read(improviseHikeProvider);
    final homeMapNotifier = ref.read(homeMapStateProvider.notifier);
    final guidedNotifier = ref.read(guidedHikeTrackingProvider.notifier);
    final improviseNotifier = ref.read(improviseHikeProvider.notifier);
    final bottomUiNotifier = ref.read(bottomUiStateProvider.notifier);
    final locationStateNotifier = ref.read(locationStateProvider.notifier);

    // Set loading state
    ref.read(isClosingRecapProvider.notifier).state = true;

    try {
      await PoiDisplayService.clearHighlightedPoi();
      await trackingLocation.clearTracking();
      homeMapNotifier.updateState(HomeMapState.explore);

      if (guidedHikeState is GuidedHikeTrackingCompleted) {
        guidedNotifier.reset();
      }

      if (improviseHikeState is ImproviseHikeFinished) {
        await improviseNotifier.reset();
      }

      bottomUiNotifier.hideRecap();

      // Réafficher le puck de localisation et recentrer la caméra sur l'utilisateur
      if (mapboxMapController != null) {
        // Restaurer le puck de localisation normal
        await mapboxMapController!.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            puckBearingEnabled: true,
            puckBearing: PuckBearing.HEADING,
            pulsingEnabled: true,
            showAccuracyRing: true,
            locationPuck: LocationPuck(
              locationPuck2D: DefaultLocationPuck2D(topImage: null),
            ),
          ),
        );

        // Récupérer la position actuelle
        final currentPosition = await locationStateNotifier
            .getCurrentPosition();

        // Recentrer la caméra sur la position actuelle avec zoom approprié
        if (currentPosition != null) {
          await mapboxMapController!.easeTo(
            CameraOptions(
              center: Point(
                coordinates: Position(
                  currentPosition.longitude,
                  currentPosition.latitude,
                ),
              ),
              zoom: 15.0,
              pitch: 0.0,
              bearing: 0.0,
            ),
            MapAnimationOptions(duration: 800, startDelay: 0),
          );
        }
      }
    } finally {
      // Always clear loading state
      ref.read(isClosingRecapProvider.notifier).state = false;
    }
  }

  /// Gère la navigation vers un POI
  void _handleNavigateToPoi(UserPOI poi) {
    if (mapboxMapController != null) {
      PoiDisplayService.navigateToPoiWithHighlight(
        mapboxMap: mapboxMapController!,
        poi: poi,
      );
    }
  }

  /// Gère le placement d'un POI
  void _handlePlacePoi(WidgetRef ref, double latitude, double longitude) async {
    await ref
        .read(poiPlacementProvider.notifier)
        .savePoi(latitude: latitude, longitude: longitude);
    if (mapboxMapController != null) {
      await PoiDisplayService.loadAndDisplayPois(mapboxMapController!);
    }
  }

  /// Gère l'annulation du placement de POI
  void _handleCancelPoiPlacement(WidgetRef ref) {
    ref.read(poiPlacementProvider.notifier).cancelPlacement();
  }

  /// Construit le contenu pour le mode organisé
  Widget _buildOrganizedHikeContent(
    BuildContext context,
    WidgetRef ref,
    OrganizedHikeState organizedState,
  ) {
    return switch (organizedState) {
      // Sélection du point de départ
      OrganizedHikeSelectingStart(existingOptions: final existingOpts) =>
        OrganizedDraggableStartSelectionSheet(
          onClose: () {
            ref.read(organizedHikeProvider.notifier).goBack();
            // Si on revient à Idle (pas d'options existantes), remettre en mode explore
            if (existingOpts.isEmpty) {
              ref
                  .read(homeMapStateProvider.notifier)
                  .updateState(HomeMapState.explore);
            }
          },
        ),

      // Sélection de destination
      OrganizedHikeSelectingDestination(
        currentOption: final option,
        optionIndex: final index,
        allOptions: final allOptions,
        isSheetMinimized: final isMinimized,
      ) =>
        OrganizedDraggableWaypointSheet(
          option: option,
          canAddOption: allOptions.length < 4,
          onAddDestination: () => _handleAddDestination(ref),
          onSaveOption: () => _handleSaveOption(ref),
          onAddNewOption: () =>
              ref.read(organizedHikeProvider.notifier).startNewOption(),
          onClose: () => ref.read(organizedHikeProvider.notifier).goBack(),
          onQuit: () => _showQuitConfirmationDialog(context, ref),
          onBack: () => _handleOrganizedBack(ref),
          onInsertWaypoint: (insertAtIndex) =>
              _handleAddDestination(ref, insertAtIndex: insertAtIndex),
          totalOptions: allOptions.length,
          currentOptionIndex: index,
          onTabChanged: (newIndex) {
            ref.read(organizedHikeProvider.notifier).switchToOption(newIndex);
          },
          isMinimizedForSelection: isMinimized,
          onSheetExpanded: () =>
              ref.read(organizedHikeProvider.notifier).expandSheet(),
        ),

      // Calcul en cours
      OrganizedHikeCalculatingRoute(option: final _) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Calcul de l\'itinéraire...',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lexend Deca',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),

      // Option complète
      OrganizedHikeOptionComplete(
        currentOptionIndex: final index,
        allOptions: final allOptions,
      ) =>
        OrganizedDraggableWaypointSheet(
          option: allOptions[index],
          canAddOption: allOptions.length < 4,
          onAddDestination: () => _handleAddDestination(ref),
          onSaveOption: () => _handleLaunchOrganizedHike(ref),
          onAddNewOption: () =>
              ref.read(organizedHikeProvider.notifier).startNewOption(),
          onClose: () => ref.read(organizedHikeProvider.notifier).reset(),
          onQuit: () => _showQuitConfirmationDialog(context, ref),
          onBack: () => _handleOrganizedBack(ref),
          onInsertWaypoint: (insertAtIndex) =>
              _handleAddDestination(ref, insertAtIndex: insertAtIndex),
          totalOptions: allOptions.length,
          currentOptionIndex: index,
          onTabChanged: (newIndex) {
            ref.read(organizedHikeProvider.notifier).switchToOption(newIndex);
          },
        ),

      // Erreur
      OrganizedHikeError(message: final msg, reasons: final reasons) =>
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lexend Deca',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...reasons.map(
                  (reason) => Text(
                    reason,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Lexend Deca',
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(organizedHikeProvider.notifier).reset(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),

      OrganizedHikeIdle() => const SizedBox.shrink(),
    };
  }

  /// Gère l'ajout d'une destination/étape
  /// Passe en mode sélection sur la carte avec bottom sheet minimisée
  void _handleAddDestination(WidgetRef ref, {int? insertAtIndex}) {
    final currentState = ref.read(organizedHikeProvider);

    // Si on est déjà en mode sélection de destination, juste minimiser la sheet
    if (currentState is OrganizedHikeSelectingDestination) {
      ref.read(organizedHikeProvider.notifier).minimizeSheet();
      return;
    }

    // Sinon, démarrer l'ajout de waypoint (depuis OptionComplete)
    ref
        .read(organizedHikeProvider.notifier)
        .startAddingWaypoint(insertAtIndex: insertAtIndex);
  }

  /// Gère la sauvegarde d'une option (affiche juste un message pour l'instant)
  void _handleSaveOption(WidgetRef ref) {
    // Pour l'instant : ne fait rien, l'option est déjà dans le state
    // Plus tard : sauvegarde locale avec SharedPreferences
  }

  /// Gère le lancement du tracking guidé avec l'option sélectionnée
  void _handleLaunchOrganizedHike(WidgetRef ref) {
    final selectedOption = ref
        .read(organizedHikeProvider.notifier)
        .getSelectedOption();

    if (selectedOption == null || !selectedOption.isComplete) {
      return;
    }

    // Lancer le tracking guidé avec les coordonnées de l'option
    ref
        .read(guidedHikeTrackingProvider.notifier)
        .startTracking(
          routeCoordinates: selectedOption.routeCoordinates!,
          hikeInfo: {
            'name': selectedOption.name,
            'distance': selectedOption.statistics?.formattedDistance ?? '?',
            'estimatedDuration':
                selectedOption.statistics?.formattedDuration ?? '?',
          },
        );

    // Reset l'état organisé
    ref.read(organizedHikeProvider.notifier).reset();
  }

  /// Affiche la popup de confirmation pour quitter le mode organisé
  void _showQuitConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Quitter la création ?',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Lexend Deca',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Toutes vos options seront supprimées.',
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'Lexend Deca',
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Lexend Deca',
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(organizedHikeProvider.notifier).confirmQuit();
                ref
                    .read(homeMapStateProvider.notifier)
                    .updateState(HomeMapState.explore);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirmer',
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontFamily: 'Lexend Deca',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Gère le retour en arrière (supprime le dernier waypoint)
  void _handleOrganizedBack(WidgetRef ref) {
    ref.read(organizedHikeProvider.notifier).removeLastWaypoint();
  }
}
