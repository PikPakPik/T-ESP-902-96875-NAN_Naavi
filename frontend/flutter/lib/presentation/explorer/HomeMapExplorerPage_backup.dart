/*import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/core/resources/typography.dart';
import 'package:naavi/data/models/HikeModel.dart';
import 'package:naavi/core/services/statistics/statistics_service.dart';
import 'package:naavi/presentation/map/state/HomeMapState.dart';
import 'package:naavi/presentation/improvise/state/StorageHikingState.dart';
import 'package:naavi/presentation/widgets/MapView.dart';
import 'package:naavi/presentation/widgets/RecapHike.dart';
import 'package:naavi/presentation/widgets/GuidedHikeTrackingPopup.dart';
import 'package:naavi/presentation/widgets/NavigationInstructionBar.dart';
import 'package:naavi/presentation/widgets/HikeDetailPopup.dart';
import 'package:naavi/presentation/pages/HikeDetailPage.dart';

import '../../core/di/HomeMapProvider.dart';
import '../../core/di/StorageHikingProvider.dart';
import '../../core/di/PoiProvider.dart';
import '../../core/services/tracking/tracking_location_service.dart';
import '../../core/services/tracking/camera_handler_service.dart';
import '../../core/services/tracking/compass_service.dart';
import '../../core/services/tracking/camera_mode_service.dart';
import '../../core/services/tracking/location_service.dart';
import '../../domain/entities/Hike.dart';

import 'package:naavi/core/utils/route_popup_helper.dart';
import 'package:naavi/core/services/user_poi_service.dart';
import 'package:naavi/core/services/poi_manager.dart';
import 'package:naavi/core/models/user_poi.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/presentation/widgets/PlacePoiDialog.dart';
import 'package:naavi/presentation/controllers/global_route_controller.dart';

import '../common/compass/CompassState.dart';
import '../common/poi_placement/PoiPlacementState.dart';
import '../map/state/HomeMapStateNotifier.dart';
import '../state/MapServicesState.dart';
import '../../core/di/MapProviders.dart';
import '../widgets/poi/PoiSelectionBottomSheet.dart';
import '../guided/state/HikeNavigationState.dart';
import '../state/route_selection/RouteSelectionState.dart';
import '../state/improvise_hike/ImproviseHikeState.dart';
import '../state/guided_hike_tracking/GuidedHikeTrackingState.dart';
import '../../core/services/geometry/geometry_calculation_service.dart';
import '../widgets/common/action_buttons.dart';

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

  MapboxMap? mapboxMapController;
  gl.Position? currentPosition;
  gl.Position? startPoint;
  gl.Position? endPoint;

  late LocationService _locationService;
  late TrackingLocationService trackingLocation;

  StatisticsService? _statisticsService;
  bool showRecapModal = false;

  // POI placement - managed by poiPlacementProvider

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _locationService = ref.read(locationServiceProvider);
    trackingLocation = ref.read(trackingLocationProvider);

    // Utiliser la position initiale si elle est fournie
    if (widget.initialPosition != null) {
      currentPosition = widget.initialPosition;
    }

    _initializeServices();
    _getCurrentPosition(ref.read(mapServicesProvider));

    // Différer l'initialisation après la construction du widget tree
    // pour éviter l'erreur "Tried to modify a provider while the widget tree was building"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHybridMode();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //super.didChangeAppLifecycleState(state);


    switch (state) {
      case AppLifecycleState.resumed:
        final mapServicesState = ref.read(mapServicesProvider);
        _getCurrentPosition(mapServicesState);
        break;

      case AppLifecycleState.paused:
        break;

      case AppLifecycleState.detached:
        _locationService.stopTracking();
        trackingLocation.stopTracking();
        break;

      default:
        break;
    }
  }

  void _initializeServices() {
    _statisticsService = StatisticsService();
  }

  Future<void> _initializeHybridMode() async {
    // Charger les routes via le provider
    await ref
        .read(routeSelectionProvider.notifier)
        .loadRoutes(
          providedWkbStrings: widget.wkbStrings,
          providedRouteNames: widget.routeNames,
        );

    // Démarrer le GPS et la boussole
    await _setupLocationTracking();
  }

  Future<void> _setupLocationTracking() async {
    try {
      final mapServicesState = ref.read(mapServicesProvider);
      await _moveToCurrentPosition(mapServicesState);

      // Démarrer l'écoute de la boussole via le provider
      ref.read(compassProvider.notifier).startListening();

    } catch (e) {
    }
  }

  Future<void> _moveToCurrentPosition(MapServicesState mapServicesState) async {

    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        currentPosition = position;
      });

      if (mapServicesState.mapboxMapController != null) {
        await _moveCamera(position, mapServicesState);
      }
    }
  }

  Future<void> _setupPermissionPositionTracking() async {
    bool serviceEnabled;
    gl.LocationPermission permission;

    serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location service disabled');
    }

    permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
  }

  Future<void> _getCurrentPosition(MapServicesState mapServicesState) async {
    if (currentPosition != null) {
      if (mapServicesState.mapboxMapController != null) {
        await _moveCamera(currentPosition!, mapServicesState);
      }
      return;
    }

    try {
      await _setupPermissionPositionTracking();

      gl.Position? lastKnownPosition =
          await gl.Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        setState(() {
          currentPosition = lastKnownPosition;
        });
        if (mapServicesState.mapboxMapController != null) {
          await _moveCamera(lastKnownPosition, mapServicesState);
        }
      }

      gl.Position position = await gl.Geolocator.getCurrentPosition(
        desiredAccuracy: gl.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
        if (mapServicesState.mapboxMapController != null) {
          await _moveCamera(position, mapServicesState);
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  Future<void> _moveCamera(
    gl.Position position,
    MapServicesState mapServicesState,
  ) async {
    if (mapServicesState.mapboxMapController != null) {
      await mapServicesState.mapboxMapController!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15,
        ),
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    }
  }

  Future<void> startImprovising() async {
    ref.read(homeMapStateProvider.notifier).updateState(HomeMapState.improvise);

    final isMapReady = ref.read(isMapReadyProvider);

    // Démarrer via le provider
    await ref
        .read(improviseHikeProvider.notifier)
        .startHike(mapboxMap: mapboxMapController!, isMapReady: isMapReady);

    // Gérer les erreurs
    final improviseState = ref.read(improviseHikeProvider);
    if (improviseState is ImproviseHikeError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(improviseState.message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      ref.read(mapServicesProvider.notifier).setFirstPersonMode(false);
    } else if (improviseState is ImproviseHikeActive) {
      setState(() {
        startPoint = improviseState.startPoint;
      });
      ref.read(mapServicesProvider.notifier).setFirstPersonMode(true);
    }
  }

  void startOrganizing() async {
    ref.read(homeMapStateProvider.notifier).updateState(HomeMapState.organise);
  }

  void updateMapState(HomeMapState newState) {
    ref.read(homeMapStateProvider.notifier).updateState(newState);
  }

  void _exitFirstPersonMode() async {
    trackingLocation.stopTracking();

    // Désactiver le mode première personne et arrêter le suivi de l'orientation
    final cameraModeManager = ref.read(cameraModeManagerProvider);
    await cameraModeManager?.disableFirstPersonMode();
  }

  /// Déplace la caméra vers un POI spécifique et l'agrandit visuellement
  /// Le POI sera centré dans la partie visible de la carte (au-dessus du modal)
  Future<void> _navigateToPoiLocation(UserPOI poi) async {
    if (mapboxMapController == null) {
      return;
    }

    try {

      // Ajouter un padding en bas pour que le POI soit visible au-dessus du modal
      // Le modal occupe environ 40-50% de la hauteur de l'écran
      const double modalPadding = 450.0;

      // Animer la caméra vers le POI avec un zoom approprié
      await mapboxMapController!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(poi.longitude, poi.latitude)),
          zoom: 15.0, // Zoom suffisant pour bien voir le POI
          padding: MbxEdgeInsets(
            top: 100.0,
            left: 20.0,
            bottom: modalPadding,
            right: 20.0,
          ),
        ),
        MapAnimationOptions(duration: 1500, startDelay: 0),
      );

      // Ajouter un POI surligné (agrandi) pour le mettre en évidence
      await POIManager.highlightPOI(
        mapboxMapController!,
        poi.latitude,
        poi.longitude,
        poiType: poi.type,
        iconSize: 0.6, // 2x la taille normale (0.3)
      );

    } catch (e) {
    }
  }

  /// Cadre la caméra sur l'entièreté du parcours avec un padding pour la bottom sheet
  Future<void> _fitCameraToHikePath(List<List<gl.Position>> segments) async {
    if (segments.isEmpty || mapboxMapController == null) return;

    // Récupérer tous les points du parcours
    List<gl.Position> allPoints = [];
    for (var segment in segments) {
      allPoints.addAll(segment);
    }

    if (allPoints.isEmpty) return;

    // Calculer les bounds (min/max lat/lng)
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Calculer le centre
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Calculer la distance pour déterminer le zoom
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // Calculer le zoom approximatif (plus la différence est grande, moins on zoom)
    double zoom = 15.0;
    if (maxDiff > 0.05)
      zoom = 11.0;
    else if (maxDiff > 0.02)
      zoom = 12.0;
    else if (maxDiff > 0.01)
      zoom = 13.0;
    else if (maxDiff > 0.005)
      zoom = 14.0;

    // Padding en bas pour la bottom sheet RecapHike (~350-400px)
    final padding = MbxEdgeInsets(
      top: 100,
      left: 50,
      bottom: 400, // Espace pour la bottom sheet
      right: 50,
    );

    // Déplacer la caméra
    await mapboxMapController!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: zoom,
        pitch: 0.0, // Vue de dessus
        bearing: 0.0, // Nord en haut
        padding: padding,
      ),
      MapAnimationOptions(duration: 1500, startDelay: 0),
    );
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {

    // Retirer l'observer
    WidgetsBinding.instance.removeObserver(this);

    // Note: Ne pas utiliser ref.read() dans dispose() car le widget peut déjà être disposé
    // Les providers gèrent leur propre cycle de vie via Riverpod

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final homeMapState = ref.watch(homeMapStateProvider);
    final mapServicesState = ref.watch(mapServicesProvider);
    final storageHikingState = ref.watch(storageHikingProvider);
    final hikeNavState = ref.watch(hikeNavigationProvider);
    final isNavigatingToHike = ref.watch(isNavigatingToHikeProvider);
    final poiPlacementState = ref.watch(poiPlacementProvider);
    final isPlacingPoi = ref.watch(isPlacingPoiProvider);

    // Nouveaux providers
    final routeSelectionState = ref.watch(routeSelectionProvider);
    final compassState = ref.watch(compassProvider);
    final improviseHikeState = ref.watch(improviseHikeProvider);
    final guidedHikeState = ref.watch(guidedHikeTrackingProvider);

    // Écouter les changements de POI pour synchroniser avec la carte
    ref.listen(poiRefreshProvider, (previous, next) {
      if (mapboxMapController != null) {
        _loadSavedPOIs();
      }
    });

    // Écouter les changements de position pour mettre à jour le guided hike tracking
    ref.listen(locationServiceProvider, (previous, next) {
      final guidedState = ref.read(guidedHikeTrackingProvider);
      if (guidedState is GuidedHikeTrackingActive && currentPosition != null) {
        ref
            .read(guidedHikeTrackingProvider.notifier)
            .updatePosition(currentPosition!);
      }
    });

    // Afficher un indicateur de chargement pendant le chargement des randonnées
    if (routeSelectionState is RouteSelectionLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des randonnées...'),
            ],
          ),
        ),
      );
    }

    // Obtenir le heading de la boussole
    final deviceHeading = compassState is CompassActive
        ? compassState.currentHeading
        : null;

    // Obtenir la randonnée sélectionnée
    final selectedHikeInfo = routeSelectionState is RouteSelectionSelected
        ? routeSelectionState.selectedHikeInfo
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // Mode Hybride : Randonnées + GPS simultanément
          MapView(
            // Paramètres pour les randonnées (si disponibles)
            wkbStrings:
                routeSelectionState is RouteSelectionLoaded ||
                    routeSelectionState is RouteSelectionSelected
                ? (routeSelectionState is RouteSelectionLoaded
                      ? routeSelectionState.wkbStrings
                      : (routeSelectionState as RouteSelectionSelected)
                            .wkbStrings)
                : null,
            routeNames:
                routeSelectionState is RouteSelectionLoaded ||
                    routeSelectionState is RouteSelectionSelected
                ? (routeSelectionState is RouteSelectionLoaded
                      ? routeSelectionState.routeNames
                      : (routeSelectionState as RouteSelectionSelected)
                            .routeNames)
                : null,
            routesData:
                routeSelectionState is RouteSelectionLoaded ||
                    routeSelectionState is RouteSelectionSelected
                ? (routeSelectionState is RouteSelectionLoaded
                      ? routeSelectionState.routes
                      : (routeSelectionState as RouteSelectionSelected)
                            .allRoutes)
                : null,
            onHikeSelected: (info) async {

              // Sélectionner via le provider
              ref.read(routeSelectionProvider.notifier).selectRoute(info);

              // Forcer la récupération de la position actuelle
              if (currentPosition == null && _locationService != null) {
                final position = await _locationService.getCurrentPosition();
                if (position != null && mounted) {
                  setState(() {
                    currentPosition = position;
                  });
                }
              }
            },
            // Paramètres pour le GPS (si disponible)
            currentPosition: mapServicesState.currentPosition,
            initialPosition: widget.initialPosition ?? currentPosition,
            deviceHeading: deviceHeading,
            enableCameraTracking:
                true, // Active la détection des interactions utilisateur
            onSetupPositionTracking: () async {
              await _getCurrentPosition(mapServicesState);
            },
            onMapTap: () {
              // Fermer la sélection de POI quand on clique sur la carte
              if (poiPlacementState is PoiPlacementSelectingType) {
                ref.read(poiPlacementProvider.notifier).closeTypeSelection();
              }
            },
            onMapReady: (MapboxMap mapboxMap) async {
              // IMPORTANT: Assigner la variable locale pour que toutes les fonctionnalités marchent
              setState(() {
                mapboxMapController = mapboxMap;
              });

              // Initialiser le map controller provider
              ref.read(mapControllerProvider.notifier).onMapCreated(mapboxMap);

              ref
                  .read(mapServicesProvider.notifier)
                  .setMapController(mapboxMap);

              // Initialiser CameraModeManager dans le provider avec le CompassService
              final compassService = CompassService(
                onHeadingChanged: (heading) {
                  // Callback optionnel pour des mises à jour supplémentaires
                  if (kDebugMode) {
                  }
                },
                headingThreshold: 5.0,
              );

              final cameraService = CameraHandlerService(mapboxMap: mapboxMap);
              final cameraModeManager = CameraModeManager(
                cameraService: cameraService,
                compassService: compassService,
              );
              ref.read(cameraModeManagerProvider.notifier).state =
                  cameraModeManager;
              trackingLocation.setMapController(mapboxMapController!);

              // Récupérer la position si elle n'est pas encore disponible
              if (currentPosition == null && _locationService != null) {
                final position = await _locationService!.getCurrentPosition();
                if (position != null) {
                  setState(() {
                    currentPosition = position;
                  });
                }
              }

              // Déplacer la caméra vers la position actuelle
              final mapServicesState = ref.read(mapServicesProvider);
              if (currentPosition != null) {
                await _moveCamera(currentPosition!, mapServicesState);
              } else {
                // Si on n'a pas encore la position, essayer de la récupérer
                await _moveToCurrentPosition(mapServicesState);
              }

              if (widget.hike != null) {
                updateMapState(HomeMapState.improvise);
                await trackingLocation.restoreHike(
                  widget.hike!,
                  mapboxMapController!,
                );

                ref
                    .read(storageHikingProvider.notifier)
                    .pausedHike(
                      widget.hike!.startPoint.latitude,
                      widget.hike!.startPoint.longitude,
                      widget.hike!.paths,
                    );
              }

              // Charger les POI sauvegardés
              _loadSavedPOIs();
            },
            onUserExploringChanged: (bool isUserExploring) {
              trackingLocation.setUserExploring(isUserExploring);
              ref
                  .read(cameraStateProvider.notifier)
                  .setUserExploring(isUserExploring);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primaryColor.withValues(alpha: 0.35),
                    AppColors.primaryColor.withValues(alpha: 0.70),
                  ],
                  stops: const [0.0, 0.8, 1.0],
                ),
              ),
            ),
          ),
          // Interface hybride : Randonnées sélectionnées ou options par défaut
          if (selectedHikeInfo != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              // Utiliser une clé pour forcer la reconstruction quand currentPosition change
              key: ValueKey(
                'hike-detail-${currentPosition?.latitude}-${currentPosition?.longitude}',
              ),
              child: Builder(
                builder: (context) {
                  final distance = _calculateDistanceToHikeStart(
                    selectedHikeInfo,
                  );
                  final isNearby = distance != null && distance <= 5.0;


                  return HikeDetailPopup(
                    hikeInfo: selectedHikeInfo!,
                    isNearby: isNearby,
                    distance: distance,
                    onClose: () async {
                      ref.read(routeSelectionProvider.notifier).deselectRoute();
                      await RoutePopupHelper.onPopupClosed();
                    },
                    onLaunch: () async {
                      await _startNavigationToHikeStart();
                    },
                    onAddPoi: () {
                      ref.read(routeSelectionProvider.notifier).deselectRoute();
                      _openPoiTypeSelection();
                    },
                    onShowDetails: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HikeDetailPage(
                            hikeInfo: selectedHikeInfo!,
                            onStart: () async {
                              await _startNavigationToHikeStart();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // Popup GPS pour la navigation vers le départ
          if (hikeNavState is HikeNavigationActive)
            Builder(
              builder: (context) {
                final navData = hikeNavState as HikeNavigationActive;
                return Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Navigation vers le départ',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(navData.distanceToStartKm * 1000).toInt()} m',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${navData.estimatedTimeMinutes.toInt()} min',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                                onPressed: () async {
                                  // Annuler la navigation
                                  if (mapboxMapController != null) {
                                    await ref
                                        .read(hikeNavigationProvider.notifier)
                                        .cleanupNavigationRoute(
                                          mapboxMapController!,
                                        );
                                  }
                                  ref
                                      .read(hikeNavigationProvider.notifier)
                                      .stopNavigation();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Navigation vers le départ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _calculateDistanceToHikeStart(
                                            selectedHikeInfo,
                                          ) !=
                                          null
                                      ? '${(_calculateDistanceToHikeStart(selectedHikeInfo)! * 1000).toInt()} m'
                                      : '${(navData.distanceToStartKm * 1000).toInt()} m',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Suivez le tracé noir pour rejoindre le point de départ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () async {
                              // Annuler la navigation
                              if (mapboxMapController != null) {
                                await ref
                                    .read(hikeNavigationProvider.notifier)
                                    .cleanupNavigationRoute(
                                      mapboxMapController!,
                                    );
                              }
                              ref
                                  .read(hikeNavigationProvider.notifier)
                                  .stopNavigation();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Navigation instruction bar pendant le suivi de randonnée guidée
          if (guidedHikeState is GuidedHikeTrackingActive &&
              !guidedHikeState.isPaused)
            Builder(
              builder: (context) {
                final state = guidedHikeState as GuidedHikeTrackingActive;
                return Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: NavigationInstructionBar(
                    instruction: state.currentDirection,
                    distanceToNextPoint: state.distanceToNextWaypointMeters,
                    directionType: state.currentDirectionType,
                  ),
                );
              },
            ),

          // Popup de suivi de randonnée guidée (en bas) avec bouton intégré
          if (guidedHikeState is GuidedHikeTrackingActive && !isPlacingPoi)
            Builder(
              builder: (context) {
                final state = guidedHikeState as GuidedHikeTrackingActive;
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GuidedHikeTrackingPopup(
                    elapsedSeconds: state.elapsedSeconds,
                    distanceKm: state.distanceKm,
                    isExpanded: true, // Toujours étendue par défaut
                    isPaused: state.isPaused,
                    onExpandedChanged: (expanded) {
                      // Plus besoin de gérer l'expansion localement
                    },
                    onHeightChanged: (height) {
                      // Plus besoin de gérer la hauteur localement
                    },
                    onPauseResume: () {
                      if (state.isPaused) {
                        ref.read(guidedHikeTrackingProvider.notifier).resume();
                      } else {
                        ref.read(guidedHikeTrackingProvider.notifier).pause();
                      }
                    },
                    onFinish: () {
                      ref
                          .read(guidedHikeTrackingProvider.notifier)
                          .stopTracking(completed: false);
                    },
                    onAddPoi: () {
                      _openPoiTypeSelection();
                    },
                  ),
                );
              },
            )
          else if (homeMapState == HomeMapState.explore &&
              !(poiPlacementState is PoiPlacementSelectingType) &&
              !isPlacingPoi &&
              selectedHikeInfo == null &&
              !isNavigatingToHike)
            Positioned(
              bottom: 54,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Column(
                  spacing: 10,
                  children: [
                    LargeButton(
                      onPressed: () {
                        ref
                            .read(homeMapStateProvider.notifier)
                            .updateState(HomeMapState.organise);
                      },
                      text: "Organiser ma propre randonnée",
                    ),
                    LargeButton(
                      onPressed: () {
                        startImprovising();
                        ref.read(storageHikingProvider.notifier).startHike();
                      },
                      text: "Partir à l'improviste",
                    ),
                  ],
                ),
              ),
            ),
          if (homeMapState == HomeMapState.improvise && !isPlacingPoi)
            Positioned(
              bottom: 24,
              left: 28,
              child: Row(
                children: [
                  ActionButton(
                    isLoading: false,
                    onPressed: () async {
                      _exitFirstPersonMode();
                      final mapServicesState = ref.read(mapServicesProvider);
                      await _getCurrentPosition(mapServicesState);
                      await trackingLocation.setEndPoint(
                        currentPosition,
                        mapboxMapController,
                      );

                      // Cadrer la caméra sur l'entièreté du parcours
                      final segments = trackingLocation.getAllSegments();
                      await _fitCameraToHikePath(segments);

                      setState(() {
                        showRecapModal = true;
                      });
                    },
                    text: "Finish",
                  ),
                  switch (storageHikingState) {
                    StorageHikingStateIdle() => const ActionButton(
                      isLoading: false,
                      onPressed: null,
                    ),
                    StorageHikingStateTracking() => ActionButton(
                      isLoading: false,
                      onPressed: () async {
                        final List<List<PathPoint>> currentPath =
                            await trackingLocation.getCurrentPath();

                        final endPosition =
                            trackingLocation.getLastKnownPosition() ??
                            _locationService?.currentPosition;

                        if (endPosition == null) {
                          final mapServicesState = ref.read(
                            mapServicesProvider,
                          );
                          await _moveToCurrentPosition(mapServicesState);
                          final currentPos = _locationService?.currentPosition;
                          if (currentPos != null) {
                            await trackingLocation.setEndPoint(
                              currentPos,
                              mapboxMapController,
                            );
                          }
                        } else {
                          await trackingLocation.setEndPoint(
                            endPosition,
                            mapboxMapController,
                          );
                        }

                        trackingLocation.pauseTracking();

                        if (startPoint != null && currentPath.isNotEmpty) {
                          await ref
                              .read(storageHikingProvider.notifier)
                              .pausedHike(
                                startPoint!.latitude,
                                startPoint!.longitude,
                                currentPath,
                              );
                        } else {
                          ref.read(storageHikingProvider.notifier).pauseHike();
                        }

                        // Arrêter la boussole via le provider
                        ref.read(compassProvider.notifier).stopListening();

                        _statisticsService?.setFinalTime();

                        final allSegments = trackingLocation.getAllSegments();
                        final totalDistance =
                            _statisticsService?.calculateTotalDistance(
                              allSegments,
                            ) ??
                            0.0;
                        _statisticsService?.setFinalDistance(totalDistance);

                        ref.read(poiServiceProvider).setPoiTypesImproviseHike();
                      },
                      text: "Pause",
                    ),
                    StorageHikingStateLoading() => const ActionButton(
                      isLoading: true,
                    ),
                    StorageHikingStatePaused() => ActionButton(
                      isLoading: false,
                      onPressed: () async {
                        trackingLocation.continueTracking();
                        ref.read(storageHikingProvider.notifier).startHike();
                      },
                      text: "Reprendre",
                    ),
                    StorageHikingStateError() => ActionButton(
                      isLoading: false,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Une erreur est survenue"),
                          ),
                        );
                      },
                      text: "Réessayer",
                    ),

                    StorageHikingStateSyncronized() => ActionButton(
                      isLoading: false,
                      onPressed: () {
                        updateMapState(HomeMapState.explore);
                      },
                      text: "OK",
                    ),
                  },
                  const SizedBox(width: 8),
                  CircleIconButton(
                    onPressed: () async {
                      // Réactiver le mode première personne et le suivi automatique
                      final mapServicesState = ref.read(mapServicesProvider);
                      await _getCurrentPosition(mapServicesState);

                      final cameraModeManager = ref.read(
                        cameraModeManagerProvider,
                      );
                      if (currentPosition != null &&
                          cameraModeManager != null) {
                        // Réactiver le mode première personne avec le padding et l'orientation actuelle
                        await cameraModeManager.enableFirstPersonMode(
                          currentPosition!,
                        );

                        // Réinitialiser l'état d'exploration pour réactiver le suivi automatique
                        trackingLocation.setUserExploring(false);
                      }
                    },
                    assetsPath: "assets/icons/location_icon.png",
                    size: 40,
                  ),
                  const SizedBox(width: 8),
                  // Bouton pour ajouter un POI en mode improvise
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _openPoiTypeSelection();
                      },
                      icon: const Icon(
                        Icons.add_location_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showRecapModal || guidedHikeState is GuidedHikeTrackingCompleted)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  // Priorité aux segments de la randonnée guidée si disponibles
                  final segments =
                      guidedHikeState is GuidedHikeTrackingCompleted
                      ? (guidedHikeState as GuidedHikeTrackingCompleted)
                            .segments
                      : trackingLocation.getAllSegments();

                  return RecapHike(
                    onClose: () async {
                      // Nettoyer le POI surligné s'il y en a un
                      await POIManager.clearHighlightedPOI();

                      await trackingLocation.clearTracking();
                      updateMapState(HomeMapState.explore);

                      _statisticsService?.reset();

                      // Réinitialiser le guided hike state si nécessaire
                      if (guidedHikeState is GuidedHikeTrackingCompleted) {
                        ref.read(guidedHikeTrackingProvider.notifier).reset();
                      }

                      setState(() {
                        showRecapModal = false;
                      });
                    },
                    segments: segments,
                    onNavigateToPoi: (poi) {
                      _navigateToPoiLocation(poi);
                    },
                  );
                },
              ),
            ),
          // Bouton flottant pour ajouter un POI
          if (homeMapState == HomeMapState.explore &&
              !isPlacingPoi &&
              !(poiPlacementState is PoiPlacementSelectingType))
            Positioned(
              bottom: 180,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  _openPoiTypeSelection();
                },
                backgroundColor: AppColors.primaryColor,
                child: const Icon(Icons.add_location_alt, color: Colors.white),
              ),
            ),
          // Dialog de placement de POI (affiché comme overlay, pas comme dialog)
          if (poiPlacementState is PoiPlacementActive &&
              mapboxMapController != null)
            Builder(
              builder: (context) {
                final placementData = poiPlacementState as PoiPlacementActive;
                return PlacePoiDialog(
                  poiType: placementData.selectedType,
                  mapboxMap: mapboxMapController!,
                  initialLatitude: currentPosition?.latitude,
                  initialLongitude: currentPosition?.longitude,
                  onPlacePoi: (lat, lon) async {
                    await ref
                        .read(poiPlacementProvider.notifier)
                        .savePoi(latitude: lat, longitude: lon);
                    await _loadSavedPOIs();
                  },
                  onCancel: () {
                    ref.read(poiPlacementProvider.notifier).cancelPlacement();
                  },
                );
              },
            ),
          // Les anciens bottom sheets POI ont été remplacés par PoiSelectionBottomSheet

          // Bouton flottant pour ajouter un POI supprimé - utiliser celui défini plus haut
        ],
      ),
    );
  }

  /// Affiche un menu pour sélectionner entre Signalements et POI
  /// Ferme toutes les popups pour n'en laisser qu'une seule ouverte à la fois
  void _closeAllPopups() {
    setState(() {
      showRecapModal = false;
    });
  }

  void _openPoiTypeSelection() async {
    _closeAllPopups(); // Fermer les autres popups d'abord

    // Afficher le choix initial : Signalements vs POI
    final choice = await PoiSelectionBottomSheet.showInitialChoice(context);
    if (choice == null) return;

    PoiType? selectedType;
    if (choice == 'signalement') {
      selectedType = await PoiSelectionBottomSheet.showReportTypes(context);
    } else if (choice == 'poi') {
      selectedType = await PoiSelectionBottomSheet.showPoiTypes(context);
    }

    if (selectedType != null && currentPosition != null) {
      // Démarrer le placement avec le provider
      ref
          .read(poiPlacementProvider.notifier)
          .startPlacement(
            selectedType,
            Position(currentPosition!.longitude, currentPosition!.latitude),
          );
    }
  }

  /// Gère le long press sur un POI pour ouvrir le dialog de placement
  /// Lance la navigation vers le point de départ de la randonnée
  Future<void> _startNavigationToHikeStart() async {
    final routeSelectionState = ref.read(routeSelectionProvider);
    if (routeSelectionState is! RouteSelectionSelected) {
      return;
    }

    if (currentPosition == null || mapboxMapController == null) {
      return;
    }

    final selectedHike = routeSelectionState.selectedHikeInfo;
    final startLat = selectedHike['startLat'];
    final startLon = selectedHike['startLon'];

    if (startLat == null || startLon == null) {
      return;
    }


    // Utiliser le provider pour calculer la route
    await ref
        .read(hikeNavigationProvider.notifier)
        .startNavigation(
          currentPosition: currentPosition!,
          startLat: startLat,
          startLon: startLon,
        );

    final navState = ref.read(hikeNavigationProvider);
    if (navState is HikeNavigationActive && mounted) {
      // Récupérer les coordonnées de la randonnée
      final hikeIndex = selectedHike['hikeIndex'] ?? selectedHike['routeIndex'];
      List<List<double>>? hikeRouteCoordinates;

      if (hikeIndex != null) {
        final coords =
            routeSelectionState.allRoutes[hikeIndex]['coordinates']
                as List<dynamic>?;
        if (coords != null) {
          hikeRouteCoordinates = coords
              .map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
              .toList();
        }
      }

      // Désélectionner la randonnée visuellement (mais garder le tracé)
      ref.read(routeSelectionProvider.notifier).deselectRoute();

      // Afficher le tracé de navigation vers le départ via le state notifier
      await ref
          .read(hikeNavigationProvider.notifier)
          .displayNavigationRoute(mapboxMapController!);

      // Orienter la caméra vers la route
      if (currentPosition != null) {
        await ref
            .read(hikeNavigationProvider.notifier)
            .orientCameraToRoute(
              mapboxMap: mapboxMapController!,
              currentPosition: currentPosition!,
            );
      }


      // Vérifier si on est déjà au point de départ (< 50m)
      final distanceInMeters = navState.distanceToStartKm * 1000;
      if (distanceInMeters < 50 && hikeRouteCoordinates != null) {
        await ref
            .read(hikeNavigationProvider.notifier)
            .cleanupNavigationRoute(mapboxMapController!);
        ref.read(hikeNavigationProvider.notifier).stopNavigation();

        // Démarrer le suivi de la randonnée guidée
        ref
            .read(guidedHikeTrackingProvider.notifier)
            .startTracking(
              routeCoordinates: hikeRouteCoordinates,
              hikeInfo: selectedHike,
            );
        return;
      }

      // Commencer à surveiller la position pour détecter l'arrivée
      if (hikeRouteCoordinates != null) {
        ref
            .read(hikeNavigationProvider.notifier)
            .startMonitoringArrival(
              onArrival: () async {
                // Nettoyer le tracé de navigation
                await ref
                    .read(hikeNavigationProvider.notifier)
                    .cleanupNavigationRoute(mapboxMapController!);

                // Arrêter la navigation
                ref.read(hikeNavigationProvider.notifier).stopNavigation();

                // Démarrer le suivi de la randonnée guidée
                ref
                    .read(guidedHikeTrackingProvider.notifier)
                    .startTracking(
                      routeCoordinates: hikeRouteCoordinates!,
                      hikeInfo: selectedHike,
                    );
              },
            );
      }
    } else {
      ref.read(hikeNavigationProvider.notifier).stopNavigation();
    }
  }

  /// Calcule la distance en km entre la position actuelle et le point de départ de la randonnée
  double? _calculateDistanceToHikeStart(Map<String, dynamic>? hikeInfo) {
    if (currentPosition == null || hikeInfo == null) return null;

    final startLat = hikeInfo['startLat'];
    final startLon = hikeInfo['startLon'];

    if (startLat == null || startLon == null) return null;

    return GeometryCalculationService.calculateDistanceToPoint(
      currentPosition: currentPosition,
      targetLat: startLat,
      targetLon: startLon,
    );
  }

  /// Charge les POI sauvegardés et les affiche sur la carte
  Future<void> _loadSavedPOIs() async {
    if (mapboxMapController == null) return;

    // Supprimer tous les POI custom affichés sur la carte avant de recharger les POI sauvegardés
    await POIManager.clearAllCustomPOIs(mapboxMapController!);

    try {
      final savedPois = await UserPoiService.getAllPOIs();

      // Charger tous les POIs en parallèle
      final poiFutures = savedPois.map((poi) {
        return POIManager.addCustomPOI(
          mapboxMapController!,
          poi.latitude,
          poi.longitude,
          poiType: poi.type,
          title: poi.name,
          iconSize: 0.5,
        );
      });

      await Future.wait(poiFutures);
    } catch (e) {
    }
  }
}
*/