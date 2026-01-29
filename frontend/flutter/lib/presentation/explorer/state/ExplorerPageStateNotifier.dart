import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'ExplorerPageState.dart';
import '../../../core/di/HomeMapProvider.dart';
import '../../../core/di/MapProviders.dart';
import '../../../core/services/tracking/camera_handler_service.dart';
import '../../../core/services/tracking/compass_service.dart';
import '../../../core/services/tracking/camera_mode_service.dart';
import '../../../core/services/map/map_camera_service.dart';
import '../../../core/services/poi/poi_display_service.dart';
import '../../map/state/HomeMapState.dart';
import '../../map/state/HomeMapStateNotifier.dart';
import '../../map/state/MapServicesState.dart';
import '../../guided/state/HikeNavigationState.dart';
import '../../guided/state/GuidedHikeTrackingState.dart';
import '../../improvise/state/ImproviseHikeState.dart';

/// Gère la logique de la page Explorer
/// Centralise l'initialisation et les réactions aux changements d'état
class ExplorerPageStateNotifier extends StateNotifier<ExplorerPageState> {
  final Ref _ref;

  ExplorerPageStateNotifier(this._ref) : super(const ExplorerPageInitial());

  // ═══════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════

  /// Initialise la page Explorer (GPS, routes, boussole)
  Future<void> initialize({
    List<String>? wkbStrings,
    List<String>? routeNames,
    gl.Position? initialPosition,
  }) async {
    state = const ExplorerPageInitializing(step: 'Démarrage GPS...');

    try {
      // 1. Démarrer le tracking GPS de manière asynchrone
      _ref.read(locationStateProvider.notifier).startTracking();

      // 2. Charger les routes via le provider
      state = const ExplorerPageInitializing(
        step: 'Chargement des randonnées...',
      );

      // Si des WKB sont fournis, charger depuis la mémoire
      if (wkbStrings != null && wkbStrings.isNotEmpty) {
        await _ref
            .read(routeSelectionProvider.notifier)
            .loadRoutes(
              providedWkbStrings: wkbStrings,
              providedRouteNames: routeNames,
            );
      } else {
        // Sinon, charger depuis l'API en utilisant la position
        gl.Position? position = initialPosition;

        // Si pas de position fournie, récupérer la position actuelle
        if (position == null) {
          final locationState = _ref.read(locationStateProvider);
          position = locationState.currentPosition;
        }

        // Si toujours pas de position, attendre une position
        position ??= await _ref
            .read(locationStateProvider.notifier)
            .getCurrentPosition();

        // Charger les randonnées depuis l'API
        if (position != null) {
          await _ref
              .read(routeSelectionProvider.notifier)
              .loadHikesFromApi(
                latitude: position.latitude,
                longitude: position.longitude,
                radius: 20, // 20km de rayon
              );
        } else {
          // Fallback : charger depuis les fichiers JSON locaux
          await _ref.read(routeSelectionProvider.notifier).loadRoutes();
        }
      }

      // 3. La boussole sera démarrée uniquement lors du lancement d'une randonnée
      // (improvise ou guidée) pour éviter la rotation de la carte en mode exploration
      state = const ExplorerPageInitializing(step: 'Finalisation...');
    } catch (e) {
      state = ExplorerPageError(
        message: 'Erreur lors de l\'initialisation',
        details: [e.toString()],
      );
    }
  }

  /// Appelé quand la carte Mapbox est prête
  Future<void> onMapReady(MapboxMap mapboxMap) async {
    // Initialiser le controller dans les providers
    _ref.read(mapControllerProvider.notifier).onMapCreated(mapboxMap);
    _ref.read(mapServicesProvider.notifier).setMapController(mapboxMap);

    // Initialiser CameraModeManager
    final compassService = CompassService(
      onHeadingChanged: (heading) {
        if (kDebugMode) {}
      },
      headingThreshold: 0.5, // Ultra fluide: 0.5° au lieu de 5.0°
      smoothingEnabled: true, // Lissage activé pour des mouvements naturels
    );

    final cameraService = CameraHandlerService(mapboxMap: mapboxMap);
    final cameraModeManager = CameraModeManager(
      cameraService: cameraService,
      compassService: compassService,
    );
    _ref.read(cameraModeManagerProvider.notifier).state = cameraModeManager;

    // Configurer le TrackingLocationService
    final trackingLocation = _ref.read(trackingLocationProvider);
    trackingLocation.setMapController(mapboxMap);

    // Récupérer la position actuelle
    final locationState = _ref.read(locationStateProvider);
    gl.Position? currentPosition = locationState.currentPosition;

    // Si pas de position en cache, récupérer la position actuelle
    currentPosition ??= await _ref
        .read(locationStateProvider.notifier)
        .getCurrentPosition();

    // Centrer la caméra sur la position de l'utilisateur de manière instantanée
    if (currentPosition != null) {
      _ref
          .read(mapServicesProvider.notifier)
          .setCurrentPosition(currentPosition);

      // Centrage instantané sans animation pour éviter de voir la position par défaut
      await mapboxMap.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              currentPosition.longitude,
              currentPosition.latitude,
            ),
          ),
          zoom: 15.0,
        ),
      );
    }

    // Charger les POI sauvegardés
    await PoiDisplayService.loadAndDisplayPois(mapboxMap);

    // Mettre à jour l'état
    state = ExplorerPageReady(
      mapController: mapboxMap,
      currentPosition: currentPosition,
      hasCenteredOnInitialPosition: currentPosition != null,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // POSITION UPDATES
  // ═══════════════════════════════════════════════════════════

  /// Met à jour la position courante
  void updatePosition(gl.Position position) {
    final currentState = state;
    if (currentState is ExplorerPageReady) {
      state = currentState.copyWith(currentPosition: position);
    }
  }

  /// Rafraîchit la position actuelle depuis le GPS
  Future<gl.Position?> refreshCurrentPosition() async {
    final position = await _ref
        .read(locationStateProvider.notifier)
        .getCurrentPosition();

    if (position != null) {
      _ref.read(mapServicesProvider.notifier).setCurrentPosition(position);

      final currentState = state;
      if (currentState is ExplorerPageReady) {
        state = currentState.copyWith(currentPosition: position);

        await MapCameraService.moveToGeoPosition(
          currentState.mapController,
          position: position,
        );
      }
    }

    return position;
  }

  // ═══════════════════════════════════════════════════════════
  // POSITION LISTENERS LOGIC
  // ═══════════════════════════════════════════════════════════

  /// Vérifie si on peut centrer automatiquement sur la position
  /// (uniquement en mode explorer normal, pas en navigation/tracking)
  bool canAutoCenterOnPosition() {
    final currentState = state;
    if (currentState is! ExplorerPageReady) return false;
    if (currentState.hasCenteredOnInitialPosition) return false;

    final hikeNavState = _ref.read(hikeNavigationProvider);
    final guidedState = _ref.read(guidedHikeTrackingProvider);
    final improviseState = _ref.read(improviseHikeProvider);
    final homeMapState = _ref.read(homeMapStateProvider);

    return hikeNavState is HikeNavigationIdle &&
        guidedState is GuidedHikeTrackingIdle &&
        improviseState is ImproviseHikeIdle &&
        homeMapState == HomeMapState.explore;
  }

  /// Marque la position initiale comme centrée
  void markInitialPositionCentered() {
    final currentState = state;
    if (currentState is ExplorerPageReady) {
      state = currentState.copyWith(hasCenteredOnInitialPosition: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  /// Appelé quand l'app passe en foreground
  void onAppResumed() {
    refreshCurrentPosition();
  }

  /// Appelé quand l'app passe en background
  void onAppPaused() {}

  /// Appelé quand l'app est détachée
  void onAppDetached() {
    _ref.read(locationStateProvider.notifier).stopTracking();
    _ref.read(trackingLocationProvider).stopTracking();
  }

  /// Nettoie les ressources
  void cleanup() {
    _ref.read(locationStateProvider.notifier).stopTracking();
    _ref.read(compassProvider.notifier).stopListening();
  }

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  /// Retourne le controller Mapbox si disponible
  MapboxMap? get mapController {
    final currentState = state;
    if (currentState is ExplorerPageReady) {
      return currentState.mapController;
    }
    return null;
  }

  /// Retourne la position courante si disponible
  gl.Position? get currentPosition {
    final currentState = state;
    if (currentState is ExplorerPageReady) {
      return currentState.currentPosition;
    }
    return null;
  }

  /// Vérifie si la page est prête
  bool get isReady => state is ExplorerPageReady;
}
