import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/common/camera/CameraState.dart';
import '../../presentation/common/camera/CameraStateNotifier.dart';
import '../../presentation/common/compass/CompassState.dart';
import '../../presentation/common/compass/CompassStateNotifier.dart';
import '../../presentation/common/poi_placement/PoiPlacementState.dart';
import '../../presentation/common/poi_placement/PoiPlacementStateNotifier.dart';
import '../../presentation/map/state/MapControllerState.dart';
import '../../presentation/map/state/MapControllerStateNotifier.dart';
import '../../presentation/guided/state/HikeNavigationState.dart';
import '../../presentation/guided/state/HikeNavigationStateNotifier.dart';
import '../../presentation/guided/state/RouteSelectionState.dart';
import '../../presentation/guided/state/RouteSelectionStateNotifier.dart';
import '../../presentation/improvise/state/ImproviseHikeState.dart';
import '../../presentation/improvise/state/ImproviseHikeStateNotifier.dart';
import '../../presentation/guided/state/GuidedHikeTrackingState.dart';
import '../../presentation/guided/state/GuidedHikeTrackingStateNotifier.dart';
import '../../presentation/explorer/state/ExplorerPageState.dart';
import '../../presentation/explorer/state/ExplorerPageStateNotifier.dart';
import '../../presentation/organized/state/OrganizedHikeState.dart';
import '../../presentation/organized/state/OrganizedHikeStateNotifier.dart';
import '../services/tracking/camera_mode_service.dart';
import '../services/hiking_routes_service.dart';
import '../services/hikes_api_service.dart';
import '../../core/di/RecapHikeProvider.dart'
    show poiService, statisticsServiceProvider;
import '../../core/di/HomeMapProvider.dart'
    show locationStateProvider, trackingLocationProvider;

/// Providers pour la gestion de la carte et de ses composants
/// Remplace la logique dispersée dans HomeMapExplorerPage
///
/// Architecture :
/// - CameraStateProvider : gestion de la caméra (vue 1ère personne, exploration)
/// - MapControllerProvider : gestion du contrôleur Mapbox
/// - HikeNavigationProvider : navigation vers point de départ
/// - PoiPlacementProvider : placement et sauvegarde de POI

// ═══════════════════════════════════════════════════════════
// SERVICES (Dépendances)
// ═══════════════════════════════════════════════════════════

/// Service de gestion de caméra (Camera + Compass)
/// Note : Sera initialisé après la création de la carte
final cameraModeManagerProvider = StateProvider<CameraModeManager?>(
  (ref) => null,
);

/// Service API pour les randonnées
final hikesApiServiceProvider = Provider<HikesApiService>((ref) {
  return HikesApiService();
});

// Note : poiService déjà défini dans RecapHikeProvider.dart
// Note : UserPoiService utilise des méthodes statiques, pas besoin de provider

// ═══════════════════════════════════════════════════════════
// STATES & NOTIFIERS
// ═══════════════════════════════════════════════════════════

/// 🎥 Provider de la caméra
/// Gère : vue première personne, exploration utilisateur, recentrage
final cameraStateProvider =
    StateNotifierProvider<CameraStateNotifier, CameraState>((ref) {
      final cameraModeManager = ref.watch(cameraModeManagerProvider);
      return CameraStateNotifier(cameraModeManager: cameraModeManager);
    });

/// 🗺️ Provider du contrôleur de carte
/// Gère : initialisation Mapbox, interactions utilisateur
final mapControllerProvider =
    StateNotifierProvider<MapControllerStateNotifier, MapControllerState>((
      ref,
    ) {
      return MapControllerStateNotifier();
    });

/// 🧭 Provider de navigation vers randonnée
/// Gère : calcul d'itinéraire via Mapbox Directions API, distance, temps estimé
final hikeNavigationProvider =
    StateNotifierProvider<HikeNavigationStateNotifier, HikeNavigationState>((
      ref,
    ) {
      return HikeNavigationStateNotifier(ref);
    });

/// 📍 Provider de placement de POI
/// Gère : sélection type, placement, sauvegarde via UserPoiService.savePOI()
final poiPlacementProvider =
    StateNotifierProvider<PoiPlacementStateNotifier, PoiPlacementState>((ref) {
      final poiService = ref.watch(poiServiceProvider);
      return PoiPlacementStateNotifier(poiService: poiService);
    });

// ═══════════════════════════════════════════════════════════
// COMPUTED STATES (États dérivés)
// ═══════════════════════════════════════════════════════════

/// Vérifie si la carte est prête
final isMapReadyProvider = Provider<bool>((ref) {
  final mapControllerState = ref.watch(mapControllerProvider);
  return mapControllerState is MapControllerReady ||
      mapControllerState is MapControllerInteracting;
});

/// Vérifie si l'utilisateur est en mode exploration
final isUserExploringProvider = Provider<bool>((ref) {
  final cameraState = ref.watch(cameraStateProvider);
  return cameraState.isUserExploring;
});

/// Vérifie si la vue première personne est active
final isFirstPersonModeProvider = Provider<bool>((ref) {
  final cameraState = ref.watch(cameraStateProvider);
  return cameraState.isFirstPersonMode;
});

/// Vérifie si une navigation est en cours
final isNavigatingToHikeProvider = Provider<bool>((ref) {
  final hikeNavState = ref.watch(hikeNavigationProvider);
  return hikeNavState is HikeNavigationActive;
});

/// Vérifie si un placement de POI est en cours
final isPlacingPoiProvider = Provider<bool>((ref) {
  final poiPlacementState = ref.watch(poiPlacementProvider);
  return poiPlacementState is PoiPlacementActive ||
      poiPlacementState is PoiPlacementSaving;
});

/// Alias pour le provider de POI (réutilise celui du RecapHikeProvider)
final poiServiceProvider = poiService;

// ═══════════════════════════════════════════════════════════
// NOUVEAUX PROVIDERS (Refactoring HomeMapExplorerPage)
// ═══════════════════════════════════════════════════════════

/// 🧭 Provider de la boussole
/// Gère : écoute des événements compass, heading du device
final compassProvider =
    StateNotifierProvider<CompassStateNotifier, CompassState>((ref) {
      return CompassStateNotifier(headingThreshold: 0.5); // Ultra fluide
    });

/// 🗺️ Provider de sélection d'itinéraire
/// Gère : chargement des routes depuis JSON ou API, sélection
final routeSelectionProvider =
    StateNotifierProvider<RouteSelectionStateNotifier, RouteSelectionState>((
      ref,
    ) {
      return RouteSelectionStateNotifier(
        routesService: HikingRoutesService(),
        hikesApiService: ref.watch(hikesApiServiceProvider),
      );
    });

/// 🏃 Provider de randonnée improvisation
/// Gère : démarrage mode libre, tracking, caméra première personne
final improviseHikeProvider =
    StateNotifierProvider<ImproviseHikeStateNotifier, ImproviseHikeState>((
      ref,
    ) {
      return ImproviseHikeStateNotifier(
        locationStateNotifier: ref.read(locationStateProvider.notifier),
        trackingLocation: ref.watch(trackingLocationProvider),
        statisticsService: ref.watch(statisticsServiceProvider),
        cameraModeManager: ref.watch(cameraModeManagerProvider),
        poiService: ref.watch(poiServiceProvider),
      );
    });

/// 🗺️ Provider de suivi de randonnée guidée
/// Gère : turn-by-turn, waypoints, directions, timer
final guidedHikeTrackingProvider =
    StateNotifierProvider<
      GuidedHikeTrackingStateNotifier,
      GuidedHikeTrackingState
    >((ref) {
      return GuidedHikeTrackingStateNotifier(ref);
    });

// ═══════════════════════════════════════════════════════════
// COMPUTED STATES - NOUVEAUX (États dérivés)
// ═══════════════════════════════════════════════════════════

/// Vérifie si la boussole est en écoute
final isCompassActiveProvider = Provider<bool>((ref) {
  final compassState = ref.watch(compassProvider);
  return compassState is CompassActive;
});

/// Obtient l'itinéraire sélectionné
final selectedHikeInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  final routeState = ref.watch(routeSelectionProvider);
  return routeState is RouteSelectionSelected
      ? routeState.selectedHikeInfo
      : null;
});

/// Vérifie si des routes sont chargées
final hasLoadedRoutesProvider = Provider<bool>((ref) {
  final routeState = ref.watch(routeSelectionProvider);
  return routeState is RouteSelectionLoaded ||
      routeState is RouteSelectionSelected;
});

/// Vérifie si une randonnée improvisation est active
final isImproviseHikeActiveProvider = Provider<bool>((ref) {
  final improviseState = ref.watch(improviseHikeProvider);
  return improviseState is ImproviseHikeActive;
});

/// Vérifie si une randonnée improvisation est en cours de démarrage
final isImproviseHikeStartingProvider = Provider<bool>((ref) {
  final improviseState = ref.watch(improviseHikeProvider);
  return improviseState is ImproviseHikeStarting;
});

/// Vérifie si une randonnée guidée est active
final isGuidedHikeActiveProvider = Provider<bool>((ref) {
  final guidedState = ref.watch(guidedHikeTrackingProvider);
  return guidedState is GuidedHikeTrackingActive;
});

/// Vérifie si une randonnée guidée est terminée
final isGuidedHikeCompletedProvider = Provider<bool>((ref) {
  final guidedState = ref.watch(guidedHikeTrackingProvider);
  return guidedState is GuidedHikeTrackingCompleted;
});

// ═══════════════════════════════════════════════════════════
// EXPLORER PAGE STATE (Nouveau - Refactoring)
// ═══════════════════════════════════════════════════════════

/// 🗺️ Provider de l'état de la page Explorer
/// Gère : initialisation, position, lifecycle, carte
final explorerPageProvider =
    StateNotifierProvider<ExplorerPageStateNotifier, ExplorerPageState>((ref) {
      return ExplorerPageStateNotifier(ref);
    });

// ═══════════════════════════════════════════════════════════
// ORGANIZED HIKE
// ═══════════════════════════════════════════════════════════

/// 🗺️ Provider d'organisation de randonnée
/// Gère : création d'options, calcul d'itinéraires, comparaison
final organizedHikeProvider =
StateNotifierProvider<OrganizedHikeStateNotifier, OrganizedHikeState>((
    ref,
    ) {
  return OrganizedHikeStateNotifier();
});

/// Vérifie si une organisation est en cours
final isOrganizingHikeProvider = Provider<bool>((ref) {
  final organizedState = ref.watch(organizedHikeProvider);
  return organizedState is! OrganizedHikeIdle;
});

/// Vérifie si au moins une option est complète
final hasCompleteOptionProvider = Provider<bool>((ref) {
  final organizedState = ref.watch(organizedHikeProvider);
  return organizedState is OrganizedHikeOptionComplete;
});

/// Hauteur actuelle de la bottom sheet organisée (en pixels)
/// Utilisé pour positionner les boutons de validation au-dessus de la sheet
final organizedSheetHeightProvider = StateProvider<double>((ref) => 0.0);