import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/presentation/common/widget/FeedbackOverlay.dart';
import '../../../core/di/HomeMapProvider.dart';
import '../../../core/di/StorageHikingProvider.dart';
import '../../../core/di/RecapHikeProvider.dart';
import '../../../core/di/MapProviders.dart';
import '../../../core/resources/colors.dart';
import '../state/StorageHikingState.dart';
import '../../map/state/MapServicesState.dart';
import '../../map/state/HomeMapState.dart';
import '../../map/state/HomeMapStateNotifier.dart';
import '../state/ImproviseHikeState.dart';
import '../../common/widget/action_buttons.dart';
import '../../../core/services/map/map_camera_service.dart';

/// Widget de contrôles pour le mode improvisation
/// Remplace les lignes 1012-1182 de HomeMapExplorerPage.dart
///
/// Affiche les boutons de contrôle pendant une randonnée improvisée :
/// - Bouton Finish : Termine la randonnée
/// - Bouton Pause/Reprendre : Gère l'état du tracking
/// - Bouton Recentrer : Retourne en mode première personne
/// - Bouton POI : Ouvre la sélection de POI
class ImproviseControls extends ConsumerStatefulWidget {
  final gl.Position? currentPosition;
  final MapboxMap? mapboxMapController;
  final VoidCallback onOpenPoiTypeSelection;

  const ImproviseControls({
    super.key,
    required this.currentPosition,
    required this.mapboxMapController,
    required this.onOpenPoiTypeSelection,
  });

  @override
  ConsumerState<ImproviseControls> createState() => _ImproviseControlsState();
}

class _ImproviseControlsState extends ConsumerState<ImproviseControls> {
  @override
  Widget build(BuildContext context) {
    final storageHikingState = ref.watch(storageHikingProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 28.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionButton(
            isLoading: false,
            onPressed: () => _handleFinish(),
            text: "Finish",
          ),
          _buildPauseResumeButton(storageHikingState),
          const SizedBox(width: 8),
          _buildRecenterButton(),
          const SizedBox(width: 8),
          _buildPoiButton(),
        ],
      ),
    );
  }

  /// Gère le bouton Finish : termine la randonnée et affiche le récapitulatif
  Future<void> _handleFinish() async {
    // Read all providers/notifiers before async operations
    final trackingLocation = ref.read(trackingLocationProvider);
    final mapServicesState = ref.read(mapServicesProvider);
    final improviseHikeNotifier = ref.read(improviseHikeProvider.notifier);
    final statisticsService = ref.read(statisticsServiceProvider);

    // No loading state - instant finish for better UX

    try {
      // Arrêter le chronomètre pour calculer la durée finale
      statisticsService.stopTimer();

      // Récupérer la position actuelle
      await _getCurrentPosition(mapServicesState);

      // Définir le point d'arrivée
      await trackingLocation.setEndPoint(
        widget.currentPosition,
        widget.mapboxMapController,
      );

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

      // IMPORTANT: Terminer la randonnée D'ABORD (arrête le tracking GPS et désactive le mode première personne)
      // Cela doit être fait AVANT fitToRoute car disableFirstPersonMode reset la caméra
      await improviseHikeNotifier.finishHike(
        segments: segments,
        distanceKm: distanceKm,
        mapboxMap: widget.mapboxMapController,
      );

      // Cadrer la caméra sur l'entièreté du parcours APRÈS avoir terminé la randonnée
      // Padding ajusté pour laisser de l'espace pour la bottomsheet de récap
      if (widget.mapboxMapController != null) {
        await MapCameraService.fitToRoute(
          widget.mapboxMapController!,
          segments: segments,
          padding: MbxEdgeInsets(
            top: 100,
            left: 50,
            bottom: 500, // Augmenté pour la bottomsheet de récap
            right: 50,
          ),
        );
      }

      // Le récapitulatif sera automatiquement affiché via le listener
      // sur improviseHikeProvider dans HomeMapExplorerPage
    } catch (e) {
      // Handle errors silently - state will be updated by notifier
    }
  }

  /// Construit le bouton Pause/Reprendre selon l'état du tracking
  Widget _buildPauseResumeButton(StorageHikingState storageHikingState) {
    return switch (storageHikingState) {
      StorageHikingStateIdle() => const ActionButton(
        isLoading: false,
        onPressed: null,
      ),
      StorageHikingStateTracking() => ActionButton(
        isLoading: false,
        onPressed: () => _handlePause(),
        text: "Pause",
      ),
      StorageHikingStateLoading() => const ActionButton(isLoading: true),
      StorageHikingStatePaused() => ActionButton(
        isLoading: false,
        onPressed: () => _handleResume(),
        text: "Reprendre",
      ),
      StorageHikingStateError() => ActionButton(
        isLoading: false,
        onPressed: () => _handleError(),
        text: "Réessayer",
      ),
      StorageHikingStateSyncronized() => ActionButton(
        isLoading: false,
        onPressed: () => _handleSynchronized(),
        text: "OK",
      ),
    };
  }

  /// Gère le bouton Pause
  Future<void> _handlePause() async {
    final trackingLocation = ref.read(trackingLocationProvider);
    final improviseNotifier = ref.read(improviseHikeProvider.notifier);
    final statisticsService = ref.read(statisticsServiceProvider);

    // Mettre en pause le chronomètre du service de statistiques
    statisticsService.pauseTimer();

    // Mettre en pause le compteur de temps
    improviseNotifier.pause();

    // Récupérer le chemin actuel
    final currentPath = await trackingLocation.getCurrentPath();

    // Mettre en pause le tracking
    trackingLocation.pauseTracking();

    // Désactiver le suivi automatique de la caméra
    ref.read(cameraStateProvider.notifier).setUserExploring(true);

    // Sauvegarder l'état de pause
    final improviseHikeState = ref.read(improviseHikeProvider);
    if (improviseHikeState is ImproviseHikeActive) {
      final startPoint = improviseHikeState.startPoint;
      if (currentPath.isNotEmpty) {
        await ref
            .read(storageHikingProvider.notifier)
            .pausedHike(startPoint.latitude, startPoint.longitude, currentPath);
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

  /// Gère le bouton Reprendre
  Future<void> _handleResume() async {
    final trackingLocation = ref.read(trackingLocationProvider);
    final improviseNotifier = ref.read(improviseHikeProvider.notifier);
    final statisticsService = ref.read(statisticsServiceProvider);

    trackingLocation.continueTracking();
    ref.read(storageHikingProvider.notifier).startHike();

    // Réactiver le suivi automatique de la caméra
    ref.read(cameraStateProvider.notifier).setUserExploring(false);

    // Reprendre le chronomètre du service de statistiques
    statisticsService.resumeTimer();

    // Reprendre le compteur de temps
    improviseNotifier.resume();

    // Redémarrer la boussole
    ref.read(compassProvider.notifier).startListening();
  }

  /// Gère l'état d'erreur
  void _handleError() {
    FeedbackOverlay.showError(context, 'Une erreur est survenue');
  }

  /// Gère l'état synchronisé
  void _handleSynchronized() {
    ref.read(homeMapStateProvider.notifier).updateState(HomeMapState.explore);
  }

  /// Construit le bouton de recentrage (mode première personne)
  /// N'apparaît que quand l'utilisateur a interagi avec la carte (zoom/pan)
  Widget _buildRecenterButton() {
    final cameraState = ref.watch(cameraStateProvider);

    // N'afficher le bouton que si l'utilisateur explore (a bougé/zoomé la carte)
    if (!cameraState.isUserExploring) {
      return const SizedBox.shrink();
    }

    return CircleIconButton(
      onPressed: () => _handleRecenter(),
      assetsPath: "assets/icons/location_icon.png",
      size: 40,
    );
  }

  /// Gère le bouton de recentrage : réactive le mode première personne
  Future<void> _handleRecenter() async {
    final mapServicesState = ref.read(mapServicesProvider);
    final trackingLocation = ref.read(trackingLocationProvider);
    final cameraNotifier = ref.read(cameraStateProvider.notifier);

    // Récupérer la position actuelle
    await _getCurrentPosition(mapServicesState);

    // Réactiver le mode première personne
    final cameraModeManager = ref.read(cameraModeManagerProvider);
    if (widget.currentPosition != null && cameraModeManager != null) {
      await cameraModeManager.enableFirstPersonMode(widget.currentPosition!);

      // Réinitialiser l'état d'exploration (cela réactive aussi la rotation du compas)
      trackingLocation.setUserExploring(false);
      cameraNotifier.setUserExploring(false);
    }
  }

  /// Construit le bouton d'ajout de POI
  Widget _buildPoiButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: widget.onOpenPoiTypeSelection,
        icon: const Icon(Icons.add_location_alt, color: Colors.white, size: 20),
      ),
    );
  }

  /// Récupère et met à jour la position actuelle
  Future<void> _getCurrentPosition(MapServicesState mapServicesState) async {
    final position = await ref
        .read(locationStateProvider.notifier)
        .getCurrentPosition();

    if (position != null && mounted) {
      // Note: On ne peut pas utiliser setState ici car currentPosition
      // est une propriété du widget parent. Le parent doit gérer cela.
      // Pour l'instant, on met à jour le provider
      ref.read(mapServicesProvider.notifier).setCurrentPosition(position);

      if (mapServicesState.mapboxMapController != null) {
        await MapCameraService.moveToGeoPosition(
          mapServicesState.mapboxMapController!,
          position: position,
        );
      }
    }
  }
}
