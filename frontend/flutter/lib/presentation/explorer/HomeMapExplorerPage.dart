import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/presentation/map/state/HomeMapState.dart';
import 'package:naavi/presentation/map/state/HomeMapStateNotifier.dart';
import 'package:naavi/presentation/map/MapView.dart';
import 'package:naavi/core/utils/poi_type.dart';

import '../../core/di/HomeMapProvider.dart';
import '../../core/di/StorageHikingProvider.dart';
import '../../core/di/PoiProvider.dart';
import '../../core/di/MapProviders.dart';
import '../../core/di/BottomUiProvider.dart';
import '../../core/resources/colors.dart';
import '../../core/services/geometry/geometry_calculation_service.dart';
import '../../core/services/map/hike_selection_service.dart';
import '../../core/services/map/map_marker_service.dart';
import '../../core/services/map/route_marker_service.dart';
import '../../core/services/poi/poi_display_service.dart';
import '../../data/models/organized_hike_option.dart';
import '../../domain/entities/Hike.dart';
import '../common/widget/search_bar.dart' show CustomSearchBar;
import '../common/compass/CompassState.dart';
import '../common/poi_placement/PoiPlacementState.dart';
import '../common/poi_placement/PoiSelectionBottomSheet.dart';
import '../common/bottom_ui/BottomUiContainer.dart';
import '../common/bottom_ui/BottomUiOverlayContainer.dart';
import '../common/widget/full_page_loader.dart';
import '../map/state/MapServicesState.dart';
import '../map/widget/map_gradient_overlay.dart';
import '../guided/state/HikeNavigationState.dart';
import '../guided/state/RouteSelectionState.dart';
import '../guided/state/GuidedHikeTrackingState.dart';
import '../improvise/state/ImproviseHikeState.dart';
import '../improvise/state/StorageHikingState.dart';
import '../organized/state/OrganizedHikeState.dart';
import '../organized/widget/OrganizedDestinationDragButton.dart';
import './state/ExplorerPageState.dart';

/// Page principale de l'explorateur de carte
///
/// Architecture refactorisée :
/// - ExplorerPageStateNotifier : gestion du cycle de vie et initialisation
/// - HikeSelectionService : logique de sélection et caméra
/// - Providers Riverpod : état réactif centralisé
class HomeMapExplorerPage extends ConsumerStatefulWidget {
  final Hike? hike;
  final List<String>? wkbStrings;
  final List<String>? routeNames;
  final gl.Position? initialPosition;

  const HomeMapExplorerPage({
    super.key,
    this.hike,
    this.wkbStrings,
    this.routeNames,
    this.initialPosition,
  });

  @override
  ConsumerState<HomeMapExplorerPage> createState() =>
      _HomeMapExplorerPageState();
}

class _HomeMapExplorerPageState extends ConsumerState<HomeMapExplorerPage>
    with
        AutomaticKeepAliveClientMixin<HomeMapExplorerPage>,
        WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  // Timer pour mettre à jour l'UI pendant le tracking
  Timer? _uiUpdateTimer;

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialiser via le StateNotifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(explorerPageProvider.notifier)
          .initialize(
            wkbStrings: widget.wkbStrings,
            routeNames: widget.routeNames,
            initialPosition: widget.initialPosition,
          );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(explorerPageProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        notifier.onAppResumed();
        break;
      case AppLifecycleState.paused:
        notifier.onAppPaused();
        break;
      case AppLifecycleState.detached:
        notifier.onAppDetached();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Vérifier si le widget est encore monté avant d'utiliser ref
    if (mounted) {
      try {
        if (ref.read(isPlacingPoiProvider)) {
          ref.read(poiPlacementProvider.notifier).cancelPlacement();
        }

        ref.read(explorerPageProvider.notifier).cleanup();
      } catch (e) {
        // Ignorer les erreurs si ref n'est plus disponible
      }
    }

    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch states
    final routeSelectionState = ref.watch(routeSelectionProvider);
    final storageHikingState = ref.watch(storageHikingProvider);
    final explorerState = ref.watch(explorerPageProvider);

    // Setup listeners
    _setupListeners();

    // Loading state
    if (routeSelectionState is RouteSelectionLoading) {
      return Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.tertiaryColor,
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chargement des randonnées',
                      style: TextStyle(
                        fontFamily: 'Lexend Deca',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recherche dans votre zone...',
                      style: TextStyle(
                        fontFamily: 'Lexend Deca',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Update bottom UI
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBottomUiState());

    // Vérifier si on doit afficher le bouton de drag & drop ou le bouton de validation
    final organizedState = ref.watch(organizedHikeProvider);
    // Pour la sélection de destination
    final showDragButton =
        organizedState is OrganizedHikeSelectingDestination &&
        organizedState.isSheetMinimized &&
        !organizedState.hasPreviewDestination;
    final showValidateButton =
        organizedState is OrganizedHikeSelectingDestination &&
        organizedState.hasPreviewDestination;
    // Pour la sélection manuelle du point de départ
    final showStartDragButton =
        organizedState is OrganizedHikeSelectingStart &&
        organizedState.isSelectingManually &&
        !organizedState.hasPreviewStart;
    final showValidateStartButton =
        organizedState is OrganizedHikeSelectingStart &&
        organizedState.hasPreviewStart;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          const MapGradientOverlay(),
          // Barre de recherche en haut
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 32),
              child: CustomSearchBar(
                placeholder: 'Rechercher dans cette région...',
              ),
            ),
          ),
          BottomUiContainer(
            mapboxMapController: _getMapController(explorerState),
            currentPosition: _getCurrentPosition(explorerState),
            onOpenPoiTypeSelection: _openPoiTypeSelection,
            onStartNavigationToHike: _startNavigationToHikeStart,
          ),

          // Bouton flottant de drag & drop pour sélection destination
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 0,
            right: 0,
            child: Center(
              child: OrganizedDestinationDragButton(
                isVisible: showDragButton || showStartDragButton,
                onDismiss: () {
                  if (showDragButton) {
                    ref
                        .read(organizedHikeProvider.notifier)
                        .dismissDestinationPopup();
                  } else if (showStartDragButton) {
                    ref
                        .read(organizedHikeProvider.notifier)
                        .cancelManualStartSelection();
                  }
                },
                customText: showStartDragButton
                    ? 'Touchez la carte\n pour choisir votre point de départ'
                    : null,
              ),
            ),
          ),

          // Bouton de validation de la destination prévisualisée
          if (showValidateButton)
            Consumer(
              builder: (context, ref, child) {
                final sheetHeight = ref.watch(organizedSheetHeightProvider);
                return Positioned(
                  bottom: sheetHeight + 16,
                  right: 20,
                  child: _buildValidateDestinationButton(),
                );
              },
            ),

          // Bouton de validation du point de départ prévisualisé
          if (showValidateStartButton)
            Consumer(
              builder: (context, ref, child) {
                final sheetHeight = ref.watch(organizedSheetHeightProvider);
                return Positioned(
                  bottom: sheetHeight + 16,
                  right: 20,
                  child: _buildValidateStartButton(),
                );
              },
            ),

          // Loading overlays
          // Finish is now instant - no loader needed
          if (storageHikingState is StorageHikingStateLoading)
            const FullPageLoader(message: 'Saving hike...'),

          BottomUiOverlayContainer(
            onCancelNavigation: _cancelNavigation,
            onOpenPoiTypeSelection: _openPoiTypeSelection,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LISTENERS
  // ═══════════════════════════════════════════════════════════

  void _setupListeners() {
    // POI refresh
    ref.listen(poiRefreshProvider, (_, __) {
      final mapController = ref
          .read(explorerPageProvider.notifier)
          .mapController;
      if (mapController != null) {
        PoiDisplayService.loadAndDisplayPois(mapController);
      }
    });

    // Location updates
    ref.listen(locationStateProvider, (previous, next) {
      final position = next.currentPosition;
      if (position != null && mounted) {
        _handlePositionUpdate(position);
      }
    });

    // Map services updates
    ref.listen(mapServicesProvider, (_, next) {
      if (next.currentPosition != null) {
        ref
            .read(explorerPageProvider.notifier)
            .updatePosition(next.currentPosition!);
      }
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateBottomUiState(),
      );
    });

    // State change listeners for bottom UI
    ref.listen(homeMapStateProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateBottomUiState(),
      );
    });
    ref.listen(guidedHikeTrackingProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateBottomUiState(),
      );
    });
    ref.listen(improviseHikeProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateBottomUiState(),
      );
      if (next is ImproviseHikeError) {
        _showErrorDialog(context, next.message, next.reasons);
      }

      // Gérer le timer pour mettre à jour l'UI toutes les secondes
      if (next is ImproviseHikeActive) {
        // Démarrer le timer s'il n'existe pas déjà
        if (_uiUpdateTimer == null || !_uiUpdateTimer!.isActive) {
          _uiUpdateTimer = Timer.periodic(
            const Duration(seconds: 1),
            (_) => _updateBottomUiState(),
          );
        }
      } else {
        // Arrêter le timer si la randonnée n'est plus active
        _uiUpdateTimer?.cancel();
        _uiUpdateTimer = null;
      }
    });
    ref.listen(poiPlacementProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateBottomUiState(),
      );
    });
    ref.listen(routeSelectionProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateBottomUiState(),
      );
    });

    // Navigation error handling
    ref.listen(hikeNavigationProvider, (previous, next) {
      if (next is HikeNavigationError) {
        _showErrorDialog(context, next.message);
      }
      if (previous is HikeNavigationActive && next is HikeNavigationIdle) {
        final mapController = ref
            .read(explorerPageProvider.notifier)
            .mapController;
        if (mapController != null) {
          ref
              .read(hikeNavigationProvider.notifier)
              .cleanupNavigationRoute(mapController);
        }
      }
    });

    // Organized hike listener - affiche les tracés sur la carte
    ref.listen(organizedHikeProvider, (previous, next) async {
      // Mettre à jour la bottom UI
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateBottomUiState(),
      );

      final mapController = ref
          .read(explorerPageProvider.notifier)
          .mapController;
      if (mapController == null) return;

      // Si on passe à SelectingDestination (après avoir créé le point de départ),
      // afficher le marqueur de départ et nettoyer le marqueur de preview
      if (next is OrganizedHikeSelectingDestination &&
          previous is OrganizedHikeSelectingStart) {
        // Nettoyer le marqueur de preview
        await _cleanupStartPreviewMarker(mapController);
        // Afficher le marqueur de départ permanent
        final startPoint = next.currentOption.startPoint;
        if (startPoint != null) {
          await RouteMarkerService.displayStartMarker(
            mapboxMap: mapController,
            latitude: startPoint.position.lat.toDouble(),
            longitude: startPoint.position.lng.toDouble(),
            prefix: 'organized',
          );
        }
      }

      // Si on passe de OptionComplete à SelectingStart (création d'une nouvelle option),
      // effacer le tracé de l'option précédente
      if (next is OrganizedHikeSelectingStart &&
          previous is OrganizedHikeOptionComplete) {
        developer.log(
          'OptionComplete -> SelectingStart: Cleaning up route for new option',
          name: 'OrganizedHikeListener',
        );
        await _cleanupOrganizedRoute(mapController);
      }

      // Si on passe à OptionComplete, afficher le tracé
      // Cela inclut : changement d'option (switchToOption) ou retour sur une option existante
      if (next is OrganizedHikeOptionComplete) {
        // Vérifier si on a changé d'option (même état mais index différent)
        final previousOptionComplete = previous is OrganizedHikeOptionComplete
            ? previous
            : null;
        final optionChanged =
            previousOptionComplete != null &&
            previousOptionComplete.currentOptionIndex !=
                next.currentOptionIndex;

        if (previousOptionComplete == null || optionChanged) {
          developer.log(
            'Displaying route for option ${next.currentOptionIndex}',
            name: 'OrganizedHikeListener',
          );
          await _displayOrganizedRoute(mapController, next.currentOption);
        }
      }

      // Si on revient à SelectingDestination depuis OptionComplete (via removeLastWaypoint),
      // nettoyer le tracé et le marqueur d'arrivée, garder le marqueur de départ
      // SAUF si on ajoute un waypoint (currentOption.routeCoordinates existe encore)
      if (next is OrganizedHikeSelectingDestination &&
          previous is OrganizedHikeOptionComplete) {
        // Vérifier si le trajet existe encore (cas d'ajout de waypoint)
        final hasExistingRoute =
            next.currentOption.routeCoordinates != null &&
            next.currentOption.routeCoordinates!.isNotEmpty;

        developer.log(
          'OptionComplete -> SelectingDestination: hasExistingRoute=$hasExistingRoute',
          name: 'OrganizedHikeListener',
        );

        if (!hasExistingRoute) {
          developer.log(
            'Cleaning up route and markers...',
            name: 'OrganizedHikeListener',
          );
          // Nettoyer le tracé seulement si on n'a plus de route
          await _cleanupOrganizedRoute(mapController);
          // Nettoyer le marqueur d'arrivée
          await RouteMarkerService.removeEndMarker(
            mapboxMap: mapController,
            prefix: 'organized',
          );
          // Nettoyer les waypoints intermédiaires
          await RouteMarkerService.removeAllWaypointMarkers(
            mapboxMap: mapController,
            prefix: 'organized',
          );
          developer.log('Cleanup complete', name: 'OrganizedHikeListener');
        }
      }

      // Si on reste en SelectingDestination mais qu'on a perdu le trajet
      // (cas : clic sur retour depuis SelectingDestination avec un trajet affiché)
      if (next is OrganizedHikeSelectingDestination &&
          previous is OrganizedHikeSelectingDestination) {
        final hadRoute =
            previous.currentOption.routeCoordinates != null &&
            previous.currentOption.routeCoordinates!.isNotEmpty;
        final hasRoute =
            next.currentOption.routeCoordinates != null &&
            next.currentOption.routeCoordinates!.isNotEmpty;

        if (hadRoute && !hasRoute) {
          // On avait un trajet et on ne l'a plus, nettoyer
          await _cleanupOrganizedRoute(mapController);
          // Nettoyer le marqueur d'arrivée
          await RouteMarkerService.removeEndMarker(
            mapboxMap: mapController,
            prefix: 'organized',
          );
          // Nettoyer les waypoints intermédiaires
          await RouteMarkerService.removeAllWaypointMarkers(
            mapboxMap: mapController,
            prefix: 'organized',
          );
        }
      }

      // Si on quitte l'état organisé, nettoyer les tracés
      if (next is OrganizedHikeIdle && previous is! OrganizedHikeIdle) {
        await _cleanupOrganizedRoute(mapController);
      }

      // Si on revient à SelectingStart (via removeLastWaypoint), nettoyer les marqueurs
      if (next is OrganizedHikeSelectingStart &&
          previous is OrganizedHikeSelectingDestination) {
        await RouteMarkerService.removeAllMarkers(
          mapboxMap: mapController,
          prefix: 'organized',
        );
      }
    });
  }

  void _handlePositionUpdate(gl.Position position) {
    final notifier = ref.read(explorerPageProvider.notifier);
    notifier.updatePosition(position);

    // Auto-center on first position if in explore mode
    if (notifier.canAutoCenterOnPosition()) {
      final mapController = notifier.mapController;
      if (mapController != null) {
        HikeSelectionService.centerOnPoint(
          mapController,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        notifier.markInitialPositionCentered();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBottomUiState());

    // Update navigation/tracking states
    final hikeNavState = ref.read(hikeNavigationProvider);
    if (hikeNavState is HikeNavigationActive) {
      ref.read(hikeNavigationProvider.notifier).updateCurrentPosition(position);
    }

    final guidedState = ref.read(guidedHikeTrackingProvider);
    if (guidedState is GuidedHikeTrackingActive && !guidedState.isPaused) {
      ref.read(guidedHikeTrackingProvider.notifier).updatePosition(position);
    }

    final improviseState = ref.read(improviseHikeProvider);
    if (improviseState is ImproviseHikeActive) {
      final cameraModeManager = ref.read(cameraModeManagerProvider);
      final cameraState = ref.read(cameraStateProvider);
      if (cameraModeManager != null &&
          cameraModeManager.isFirstPersonMode &&
          !cameraState.isUserExploring) {
        cameraModeManager.updateCamera(position);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MAP
  // ═══════════════════════════════════════════════════════════

  Widget _buildMap() {
    final routeSelectionState = ref.watch(routeSelectionProvider);
    final mapServicesState = ref.watch(mapServicesProvider);
    final compassState = ref.watch(compassProvider);
    final explorerState = ref.watch(explorerPageProvider);
    final homeMapState = ref.watch(homeMapStateProvider);

    final deviceHeading = compassState is CompassActive
        ? compassState.currentHeading
        : null;

    // Ne pas afficher les randonnées quand on est en mode improvise
    final isImproviseMode = homeMapState == HomeMapState.improvise;

    return MapView(
      wkbStrings: isImproviseMode ? null : _getWkbStrings(routeSelectionState),
      routeNames: isImproviseMode ? null : _getRouteNames(routeSelectionState),
      routesData: isImproviseMode ? null : _getRoutesData(routeSelectionState),
      onHikeSelected: _handleHikeSelected,
      currentPosition: mapServicesState.currentPosition,
      initialPosition:
          widget.initialPosition ?? _getCurrentPosition(explorerState),
      deviceHeading: deviceHeading,
      enableCameraTracking: true,
      onSetupPositionTracking: () =>
          ref.read(explorerPageProvider.notifier).refreshCurrentPosition(),
      onMapTap: _handleMapTap,
      onMapTapWithCoordinates: _handleMapTapWithCoordinates,
      onMapReady: _handleMapReady,
      onUserExploringChanged: _handleUserExploringChanged,
      onMapScroll: _handleMapScroll,
    );
  }

  void _handleMapScroll() {
    // Fermer la popup "Toucher la carte" quand on fait bouger la carte
    final organizedState = ref.read(organizedHikeProvider);
    if (organizedState is OrganizedHikeSelectingDestination &&
        organizedState.isSheetMinimized) {
      ref.read(organizedHikeProvider.notifier).dismissDestinationPopup();
    }
  }

  Future<void> _handleMapReady(MapboxMap mapboxMap) async {
    await ref.read(explorerPageProvider.notifier).onMapReady(mapboxMap);

    // Restore hike if needed
    if (widget.hike != null) {
      ref
          .read(homeMapStateProvider.notifier)
          .updateState(HomeMapState.improvise);
      final trackingLocation = ref.read(trackingLocationProvider);
      await trackingLocation.restoreHike(widget.hike!, mapboxMap);

      ref
          .read(storageHikingProvider.notifier)
          .pausedHike(
            widget.hike!.startPoint.latitude,
            widget.hike!.startPoint.longitude,
            widget.hike!.paths,
          );
    }
  }

  void _handleMapTap() {
    final poiPlacementState = ref.read(poiPlacementProvider);
    if (poiPlacementState is PoiPlacementSelectingType) {
      ref.read(poiPlacementProvider.notifier).closeTypeSelection();
    }
  }

  void _handleMapTapWithCoordinates(double latitude, double longitude) {
    final organizedState = ref.read(organizedHikeProvider);

    // Si on est en mode sélection de destination, prévisualiser la destination
    if (organizedState is OrganizedHikeSelectingDestination) {
      ref
          .read(organizedHikeProvider.notifier)
          .previewDestination(latitude: latitude, longitude: longitude);
      // Afficher le marqueur de prévisualisation
      _displayPreviewMarker(latitude, longitude);
    }

    // Si on est en mode sélection manuelle du point de départ
    // Créer directement le point de départ sans passer par la preview
    if (organizedState is OrganizedHikeSelectingStart &&
        organizedState.isSelectingManually) {
      // Afficher le marqueur de départ (vert)
      _displayStartPreviewMarker(latitude, longitude);
      // Créer directement le point de départ et passer à la sélection de destination
      ref
          .read(organizedHikeProvider.notifier)
          .setStartPointFromMapTap(latitude: latitude, longitude: longitude);
    }
  }

  /// Affiche un marqueur de prévisualisation sur la carte (rouge pour destination)
  Future<void> _displayPreviewMarker(double latitude, double longitude) async {
    final mapController = ref.read(explorerPageProvider.notifier).mapController;
    if (mapController == null) return;

    await MapMarkerService.displayMarker(
      mapboxMap: mapController,
      markerId: 'preview-destination',
      latitude: latitude,
      longitude: longitude,
      color: Colors.red,
    );
  }

  /// Nettoie le marqueur de prévisualisation de destination
  Future<void> _cleanupPreviewMarker(MapboxMap mapboxMap) async {
    await MapMarkerService.removeMarker(
      mapboxMap: mapboxMap,
      markerId: 'preview-destination',
    );
  }

  /// Affiche un marqueur de prévisualisation pour le point de départ (vert)
  Future<void> _displayStartPreviewMarker(
    double latitude,
    double longitude,
  ) async {
    final mapController = ref.read(explorerPageProvider.notifier).mapController;
    if (mapController == null) return;

    await MapMarkerService.displayMarker(
      mapboxMap: mapController,
      markerId: 'preview-start',
      latitude: latitude,
      longitude: longitude,
      color: Colors.green,
    );
  }

  /// Nettoie le marqueur de prévisualisation du point de départ
  Future<void> _cleanupStartPreviewMarker(MapboxMap mapboxMap) async {
    await MapMarkerService.removeMarker(
      mapboxMap: mapboxMap,
      markerId: 'preview-start',
    );
  }

  /// Construit le bouton de validation de la destination prévisualisée
  Widget _buildValidateDestinationButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Bouton Annuler (croix)
        GestureDetector(
          onTap: () async {
            final mapController = ref
                .read(explorerPageProvider.notifier)
                .mapController;
            if (mapController != null) {
              await _cleanupPreviewMarker(mapController);
            }
            ref.read(organizedHikeProvider.notifier).cancelPreviewDestination();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.close, color: AppColors.primaryColor, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton Valider
        GestureDetector(
          onTap: () async {
            final mapController = ref
                .read(explorerPageProvider.notifier)
                .mapController;
            if (mapController != null) {
              await _cleanupPreviewMarker(mapController);
            }
            await ref
                .read(organizedHikeProvider.notifier)
                .confirmPreviewDestination();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Valider la destination',
                  style: TextStyle(
                    fontFamily: 'Lexend Deca',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le bouton de validation du point de départ prévisualisé
  Widget _buildValidateStartButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Bouton Annuler (croix)
        GestureDetector(
          onTap: () async {
            final mapController = ref
                .read(explorerPageProvider.notifier)
                .mapController;
            if (mapController != null) {
              await _cleanupStartPreviewMarker(mapController);
            }
            ref.read(organizedHikeProvider.notifier).cancelPreviewStartPoint();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.close, color: Color(0xFF324943), size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton Valider
        GestureDetector(
          onTap: () async {
            final mapController = ref
                .read(explorerPageProvider.notifier)
                .mapController;
            if (mapController != null) {
              await _cleanupStartPreviewMarker(mapController);
            }
            await ref
                .read(organizedHikeProvider.notifier)
                .confirmPreviewStartPoint();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF324943),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Valider le départ',
                  style: TextStyle(
                    fontFamily: 'Lexend Deca',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleUserExploringChanged(bool isUserExploring) {
    ref.read(trackingLocationProvider).setUserExploring(isUserExploring);
    ref.read(cameraStateProvider.notifier).setUserExploring(isUserExploring);
  }

  // ═══════════════════════════════════════════════════════════
  // HIKE SELECTION & NAVIGATION
  // ═══════════════════════════════════════════════════════════

  Future<void> _handleHikeSelected(Map<String, dynamic> info) async {
    ref.read(routeSelectionProvider.notifier).selectRoute(info);

    // 1. TOUJOURS désactiver le mode première personne d'abord
    final cameraModeManager = ref.read(cameraModeManagerProvider);
    if (cameraModeManager?.isFirstPersonMode == true) {
      await cameraModeManager?.enableExploreMode();
    }

    // 2. Arrêter toute navigation en cours
    final navState = ref.read(hikeNavigationProvider);
    if (navState is HikeNavigationActive ||
        navState is HikeNavigationNearStart) {
      ref.read(hikeNavigationProvider.notifier).stopNavigation();
    }

    final mapController = ref.read(explorerPageProvider.notifier).mapController;
    if (mapController != null) {
      final coordinates = info['coordinates'] as List<dynamic>?;
      if (coordinates != null && coordinates.isNotEmpty) {
        // 3. Petit délai pour laisser les animations précédentes se terminer
        await Future.delayed(const Duration(milliseconds: 100));

        // 4. MAINTENANT centrer proprement sur le parcours
        await HikeSelectionService.fitCameraToHike(
          mapController,
          coordinates,
          bottomPadding: 350,
          topPadding: 100,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBottomUiState());
  }

  Future<void> _startNavigationToHikeStart() async {
    final routeSelectionState = ref.read(routeSelectionProvider);
    if (routeSelectionState is! RouteSelectionSelected) return;

    final currentPosition = ref
        .read(explorerPageProvider.notifier)
        .currentPosition;
    final mapController = ref.read(explorerPageProvider.notifier).mapController;
    if (currentPosition == null || mapController == null) return;

    final selectedHike = routeSelectionState.selectedHikeInfo;
    final startPoint = HikeSelectionService.extractStartPoint(selectedHike);
    if (startPoint == null) return;

    final hikeRouteCoordinates = HikeSelectionService.extractRouteCoordinates(
      hikeInfo: selectedHike,
      allRoutes: routeSelectionState.allRoutes,
    );

    // Check if already near start
    if (hikeRouteCoordinates != null &&
        HikeSelectionService.isNearStartPoint(
          currentPosition: currentPosition,
          startLat: startPoint.lat,
          startLon: startPoint.lon,
        )) {
      ref.read(routeSelectionProvider.notifier).deselectRoute();
      ref
          .read(guidedHikeTrackingProvider.notifier)
          .startTracking(
            routeCoordinates: hikeRouteCoordinates,
            hikeInfo: selectedHike,
          );
      return;
    }

    // Start navigation
    await ref
        .read(hikeNavigationProvider.notifier)
        .startNavigation(
          currentPosition: currentPosition,
          startLat: startPoint.lat,
          startLon: startPoint.lon,
          hikeInfo: selectedHike,
          hikeRouteCoordinates: hikeRouteCoordinates,
        );

    final navState = ref.read(hikeNavigationProvider);

    if (navState is HikeNavigationActive && mounted) {
      ref.read(routeSelectionProvider.notifier).deselectRoute();
      await ref
          .read(hikeNavigationProvider.notifier)
          .displayNavigationRoute(mapController);

      // D'abord montrer tout le parcours de la randonnée
      if (hikeRouteCoordinates != null) {
        await HikeSelectionService.fitCameraToHike(
          mapController,
          hikeRouteCoordinates,
          bottomPadding: 350, // Même padding que lors de la sélection
          topPadding: 100,
          animationDuration: 800,
        );

        // Attendre 2 secondes pour que l'utilisateur voie le parcours complet
        await Future.delayed(const Duration(seconds: 2));
      }

      // Puis orienter vers la navigation
      await ref
          .read(hikeNavigationProvider.notifier)
          .orientCameraToRoute(
            mapboxMap: mapController,
            currentPosition: currentPosition,
          );
      ref.read(hikeNavigationProvider.notifier).startMonitoringArrival();
    } else {
      ref.read(hikeNavigationProvider.notifier).stopNavigation();
    }
  }

  Future<void> _cancelNavigation() async {
    final hikeNavigationState = ref.read(hikeNavigationProvider);
    Map<String, dynamic>? savedHikeInfo;

    if (hikeNavigationState is HikeNavigationActive) {
      savedHikeInfo = hikeNavigationState.activeHikeInfo;
    } else if (hikeNavigationState is HikeNavigationNearStart) {
      savedHikeInfo = hikeNavigationState.activeHikeInfo;
    }

    final mapController = ref.read(explorerPageProvider.notifier).mapController;
    if (mapController != null) {
      await ref
          .read(hikeNavigationProvider.notifier)
          .cleanupNavigationRoute(mapController);
    }
    ref.read(hikeNavigationProvider.notifier).stopNavigation();

    // Désactiver le mode première personne (sans animation de caméra)
    final cameraModeManager = ref.read(cameraModeManagerProvider);
    if (cameraModeManager?.isFirstPersonMode == true) {
      await cameraModeManager?.enableExploreMode();
    }

    // Recentrer sur la randonnée complète
    if (savedHikeInfo != null) {
      await _handleHikeSelected(savedHikeInfo);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // POI
  // ═══════════════════════════════════════════════════════════

  void _openPoiTypeSelection() async {
    if (!mounted) return;
    final choice = await PoiSelectionBottomSheet.showInitialChoice(context);
    if (choice == null || !mounted) return;

    PoiType? selectedType;
    if (choice == 'signalement') {
      if (!mounted) return;
      selectedType = await PoiSelectionBottomSheet.showReportTypes(context);
    } else if (choice == 'poi') {
      if (!mounted) return;
      selectedType = await PoiSelectionBottomSheet.showPoiTypes(context);
    }

    final currentPosition = ref
        .read(explorerPageProvider.notifier)
        .currentPosition;
    if (selectedType != null && currentPosition != null) {
      ref
          .read(poiPlacementProvider.notifier)
          .startPlacement(
            selectedType,
            Position(currentPosition.longitude, currentPosition.latitude),
          );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UI STATE
  // ═══════════════════════════════════════════════════════════

  void _updateBottomUiState() {
    final currentPosition = ref
        .read(explorerPageProvider.notifier)
        .currentPosition;
    final selectedHikeInfo = ref.read(selectedHikeInfoProvider);

    final distanceToHikeStart =
        HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: currentPosition,
          hikeInfo: selectedHikeInfo,
        );

    final guidedHikeState = ref.read(guidedHikeTrackingProvider);
    final improviseHikeState = ref.read(improviseHikeProvider);
    final showRecapModal =
        guidedHikeState is GuidedHikeTrackingCompleted ||
        improviseHikeState is ImproviseHikeFinished;

    ref
        .read(bottomUiStateProvider.notifier)
        .updateState(
          homeMapState: ref.read(homeMapStateProvider),
          selectedHikeInfo: selectedHikeInfo,
          distanceToHikeStart: distanceToHikeStart,
          guidedHikeState: guidedHikeState,
          improviseHikeState: improviseHikeState,
          hikeNavigationState: ref.read(hikeNavigationProvider),
          poiPlacementState: ref.read(poiPlacementProvider),
          organizedHikeState: ref.read(organizedHikeProvider),
          showRecapModal: showRecapModal,
          isPlacingPoi: ref.read(isPlacingPoiProvider),
          currentPosition: currentPosition,
          improviseSegments: ref
              .read(trackingLocationProvider)
              .getAllSegments(),
          storageHikingState: ref.read(storageHikingProvider),
        );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  MapboxMap? _getMapController(ExplorerPageState state) {
    if (state is ExplorerPageReady) return state.mapController;
    return null;
  }

  gl.Position? _getCurrentPosition(ExplorerPageState state) {
    if (state is ExplorerPageReady) return state.currentPosition;
    return widget.initialPosition;
  }

  List<String>? _getWkbStrings(RouteSelectionState state) {
    if (state is RouteSelectionLoaded) return state.wkbStrings;
    if (state is RouteSelectionSelected) return state.wkbStrings;
    return null;
  }

  List<String>? _getRouteNames(RouteSelectionState state) {
    if (state is RouteSelectionLoaded) return state.routeNames;
    if (state is RouteSelectionSelected) return state.routeNames;
    return null;
  }

  List<Map<String, dynamic>>? _getRoutesData(RouteSelectionState state) {
    if (state is RouteSelectionLoaded) return state.routes;
    if (state is RouteSelectionSelected) return state.allRoutes;
    return null;
  }

  void _showErrorDialog(
    BuildContext context,
    String message, [
    List<String>? reasons,
  ]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (reasons != null && reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...reasons.map(
                (r) => Text('• $r', style: const TextStyle(fontSize: 14)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Affiche le tracé d'une option organisée sur la carte
  Future<void> _displayOrganizedRoute(
    MapboxMap mapboxMap,
    OrganizedHikeOption option,
  ) async {
    if (option.routeCoordinates == null || option.routeCoordinates!.isEmpty) {
      return;
    }

    try {
      // Nettoyer l'ancien tracé s'il existe
      await _cleanupOrganizedRoute(mapboxMap);

      final coordinates = option.routeCoordinates!;

      // Créer le GeoJSON
      final geoJsonSource =
          '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": ${coordinates.toString()}
      }
    }
  ]
}''';

      // Ajouter la source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: "organized-route-source", data: geoJsonSource),
      );

      // Ajouter la ligne (style similaire à guided hike)
      await mapboxMap.style.addLayer(
        LineLayer(
          id: "organized-route-layer",
          sourceId: "organized-route-source",
          lineColor: const Color(0xFF324943).toARGB32(),
          lineWidth: 6.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );

      // Ajouter les markers pour tous les waypoints
      if (option.waypoints.isNotEmpty) {
        // Marker de départ (vert)
        final start = option.waypoints.first;
        await RouteMarkerService.displayStartMarker(
          mapboxMap: mapboxMap,
          latitude: start.position.lat.toDouble(),
          longitude: start.position.lng.toDouble(),
          prefix: 'organized',
        );

        // Markers des waypoints intermédiaires (orange)
        if (option.waypoints.length > 2) {
          for (int i = 1; i < option.waypoints.length - 1; i++) {
            final waypoint = option.waypoints[i];
            await RouteMarkerService.displayWaypointMarker(
              mapboxMap: mapboxMap,
              latitude: waypoint.position.lat.toDouble(),
              longitude: waypoint.position.lng.toDouble(),
              index: i - 1,
              prefix: 'organized',
            );
          }
        }

        // Marker de destination (rouge)
        if (option.destination != null) {
          final end = option.destination!;
          await RouteMarkerService.displayEndMarker(
            mapboxMap: mapboxMap,
            latitude: end.position.lat.toDouble(),
            longitude: end.position.lng.toDouble(),
            prefix: 'organized',
          );
        }
      }

      // Cadrer la caméra sur le tracé
      await _fitCameraToOrganizedRoute(mapboxMap, coordinates);
    } catch (e) {
      // Erreur silencieuse
      developer.log(
        'Error displaying organized route: $e',
        name: 'HomeMapExplorerPage',
      );
    }
  }

  /// Nettoie le tracé organisé de la carte
  Future<void> _cleanupOrganizedRoute(MapboxMap mapboxMap) async {
    try {
      // Supprimer le layer et source du tracé
      try {
        await mapboxMap.style.removeStyleLayer('organized-route-layer');
      } catch (e) {
        // Layer n'existe pas, ignorer
      }
      try {
        await mapboxMap.style.removeStyleSource('organized-route-source');
      } catch (e) {
        // Source n'existe pas, ignorer
      }

      // Supprimer les markers via le RouteMarkerService
      await RouteMarkerService.removeAllMarkers(
        mapboxMap: mapboxMap,
        prefix: 'organized',
      );
    } catch (e) {
      developer.log(
        'Error cleaning up organized route: $e',
        name: 'HomeMapExplorerPage',
      );
    }
  }

  /// Cadre la caméra sur le tracé organisé
  Future<void> _fitCameraToOrganizedRoute(
    MapboxMap mapboxMap,
    List<List<double>> coordinates,
  ) async {
    if (coordinates.isEmpty) return;

    try {
      // Calculer les bounds
      final bounds = GeometryCalculationService.calculateBounds(coordinates);

      // Créer les CoordinateBounds
      final coordinateBounds = CoordinateBounds(
        southwest: Point(coordinates: Position(bounds.minLng, bounds.minLat)),
        northeast: Point(coordinates: Position(bounds.maxLng, bounds.maxLat)),
        infiniteBounds: false,
      );

      // Calculer la caméra pour ces bounds
      final cameraForBounds = await mapboxMap.cameraForCoordinateBounds(
        coordinateBounds,
        MbxEdgeInsets(top: 100, left: 50, bottom: 400, right: 50),
        null,
        null,
        null,
        null,
      );

      // Animer la caméra
      await mapboxMap.flyTo(
        cameraForBounds,
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      developer.log(
        'Error fitting camera to organized route: $e',
        name: 'HomeMapExplorerPage',
      );
    }
  }
}
