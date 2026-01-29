import 'dart:async';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/services/mapbox_directions_service.dart';
import '../../../core/services/geometry/geometry_calculation_service.dart';
import 'HikeNavigationState.dart';
import '../../../core/di/MapProviders.dart';
import '../../../core/di/HomeMapProvider.dart';
import '../state/RouteSelectionState.dart';

/// Gère la navigation vers le point de départ d'une randonnée planifiée
/// Extrait de HomeMapExplorerPage (~300 lignes)
/// Gère également l'affichage des routes sur la carte et le monitoring d'arrivée
class HikeNavigationStateNotifier extends StateNotifier<HikeNavigationState> {
  Timer? _arrivalMonitoringTimer;
  final Ref _ref;

  HikeNavigationStateNotifier(this._ref) : super(const HikeNavigationIdle());

  /// Démarre la navigation vers un point de départ
  Future<void> startNavigation({
    required double startLat,
    required double startLon,
    required gl.Position currentPosition,
    Map<String, dynamic>? hikeInfo,
    List<List<double>>? hikeRouteCoordinates,
  }) async {
    try {
      // État : calcul en cours
      state = HikeNavigationCalculating(startLat: startLat, startLon: startLon);

      // Calcul de l'itinéraire via Mapbox Directions API
      final route = await MapboxDirectionsService.getWalkingRoute(
        fromLat: currentPosition.latitude,
        fromLon: currentPosition.longitude,
        toLat: startLat,
        toLon: startLon,
      );

      if (route == null || route.isEmpty) {
        state = const HikeNavigationError(
          'Impossible de calculer l\'itinéraire',
        );
        return;
      }

      // Calcul de la distance et du temps estimé
      final distance = GeometryCalculationService.calculateDistanceKm(
        currentPosition.latitude,
        currentPosition.longitude,
        startLat,
        startLon,
      );

      // Temps estimé : 5 km/h en moyenne
      final estimatedTime = (distance / 5.0) * 60; // en minutes

      // État : navigation active
      state = HikeNavigationActive(
        route: route,
        distanceToStartKm: distance,
        estimatedTimeMinutes: estimatedTime,
        startLat: startLat,
        startLon: startLon,
        activeHikeInfo: hikeInfo,
        hikeRouteCoordinates: hikeRouteCoordinates,
      );
    } catch (e) {
      // Intentionally empty catch block
      state = HikeNavigationError('Erreur lors du calcul de l\'itinéraire: $e');
    }
  }

  /// Met à jour la position actuelle (recalcule distance et temps)
  void updateCurrentPosition(gl.Position position) {
    if (state is! HikeNavigationActive) return;

    final currentState = state as HikeNavigationActive;

    // Recalcul de la distance
    final distance = GeometryCalculationService.calculateDistanceKm(
      position.latitude,
      position.longitude,
      currentState.startLat,
      currentState.startLon,
    );

    // Recalcul du temps estimé
    final estimatedTime = (distance / 5.0) * 60;

    state = currentState.copyWith(
      distanceToStartKm: distance,
      estimatedTimeMinutes: estimatedTime,
    );
  }

  /// Arrête la navigation
  void stopNavigation() {
    _arrivalMonitoringTimer?.cancel();
    _arrivalMonitoringTimer = null;
    state = const HikeNavigationIdle();
  }

  /// Affiche le tracé de navigation sur la carte avec des points
  Future<void> displayNavigationRoute(MapboxMap mapboxMap) async {
    if (state is! HikeNavigationActive) {
      return;
    }

    final currentState = state as HikeNavigationActive;
    final route = currentState.route;

    try {
      // Créer un GeoJSON pour la ligne de navigation complète
      final coordinates = route.map((point) => [point[0], point[1]]).toList();

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

      // Ajouter la source GeoJSON
      await mapboxMap.style.addSource(
        GeoJsonSource(id: "navigation-route-source", data: geoJsonSource),
      );

      // Ajouter une ligne blanche en dessous pour le contour
      await mapboxMap.style.addLayer(
        LineLayer(
          id: "navigation-route-casing",
          sourceId: "navigation-route-source",
          lineColor: Colors.white.toARGB32(),
          lineWidth: 6.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineOpacity: 0.6,
        ),
      );

      // Ajouter une couche de ligne pour le tracé principal
      await mapboxMap.style.addLayer(
        LineLayer(
          id: "navigation-route-layer",
          sourceId: "navigation-route-source",
          lineColor: Colors.black.toARGB32(),
          lineWidth: 4.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineOpacity: 0.8,
        ),
      );
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Nettoie le tracé de navigation de la carte
  Future<void> cleanupNavigationRoute(MapboxMap mapboxMap) async {
    try {
      // Supprimer les couches de ligne
      try {
        await mapboxMap.style.removeStyleLayer("navigation-route-layer");
      } catch (e) {
        // Intentionally empty catch block
      }

      try {
        await mapboxMap.style.removeStyleLayer("navigation-route-casing");
      } catch (e) {
        // Intentionally empty catch block
      }

      // Supprimer la source
      try {
        await mapboxMap.style.removeStyleSource("navigation-route-source");
      } catch (e) {
        // Intentionally empty catch block
      }
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Démarre la surveillance de l'arrivée au point de départ
  /// Passe à l'état "arrivé à proximité" quand l'utilisateur est à moins de 20m
  void startMonitoringArrival() {
    if (state is! HikeNavigationActive) {
      return;
    }

    final currentState = state as HikeNavigationActive;

    // Vérifier immédiatement si on est déjà à proximité
    final currentPosition = _ref.read(locationStateProvider).currentPosition;
    if (currentPosition != null) {
      final distance = GeometryCalculationService.calculateDistanceKm(
        currentPosition.latitude,
        currentPosition.longitude,
        currentState.startLat,
        currentState.startLon,
      );
      final distanceMeters = distance * 1000;

      if (distanceMeters < 20) {
        state = HikeNavigationNearStart(
          route: currentState.route,
          distanceToStartKm: distance,
          startLat: currentState.startLat,
          startLon: currentState.startLon,
          activeHikeInfo: currentState.activeHikeInfo,
          hikeRouteCoordinates: currentState.hikeRouteCoordinates,
        );
      }
    }

    _arrivalMonitoringTimer?.cancel();
    _arrivalMonitoringTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) {
      final latestState = state;
      if (latestState is! HikeNavigationActive &&
          latestState is! HikeNavigationNearStart) {
        timer.cancel();
        return;
      }

      // Si on est déjà à proximité, continuer à surveiller
      if (latestState is HikeNavigationNearStart) {
        // Mettre à jour la distance même si on est déjà à proximité
        final currentPosition = _ref
            .read(locationStateProvider)
            .currentPosition;
        if (currentPosition != null) {
          final distance = GeometryCalculationService.calculateDistanceKm(
            currentPosition.latitude,
            currentPosition.longitude,
            latestState.startLat,
            latestState.startLon,
          );
          final distanceMeters = distance * 1000;

          // Si l'utilisateur s'éloigne à nouveau (> 20m), revenir à l'état actif
          if (distanceMeters >= 20) {
            state = HikeNavigationActive(
              route: latestState.route,
              distanceToStartKm: distance,
              estimatedTimeMinutes: (distance / 5.0) * 60,
              startLat: latestState.startLat,
              startLon: latestState.startLon,
              activeHikeInfo: latestState.activeHikeInfo,
              hikeRouteCoordinates: latestState.hikeRouteCoordinates,
            );
          }
        }
        return;
      }

      // Si on est en état actif, vérifier si on arrive à proximité
      if (latestState is HikeNavigationActive) {
        final currentPosition = _ref
            .read(locationStateProvider)
            .currentPosition;
        if (currentPosition == null) {
          return;
        }

        final distance = GeometryCalculationService.calculateDistanceKm(
          currentPosition.latitude,
          currentPosition.longitude,
          latestState.startLat,
          latestState.startLon,
        );
        final distanceMeters = distance * 1000;

        // Si l'utilisateur est à moins de 20 mètres du point de départ
        if (distanceMeters < 20) {
          // Passer à l'état "arrivé à proximité" pour afficher le bouton
          state = HikeNavigationNearStart(
            route: latestState.route,
            distanceToStartKm: distance,
            startLat: latestState.startLat,
            startLon: latestState.startLon,
            activeHikeInfo: latestState.activeHikeInfo,
            hikeRouteCoordinates: latestState.hikeRouteCoordinates,
          );
        } else {
          // Mettre à jour la distance dans l'état actif
          state = latestState.copyWith(
            distanceToStartKm: distance,
            estimatedTimeMinutes: (distance / 5.0) * 60,
          );
        }
      }
    });
  }

  /// Arrête la surveillance de l'arrivée
  void stopMonitoringArrival() {
    _arrivalMonitoringTimer?.cancel();
    _arrivalMonitoringTimer = null;
  }

  /// Démarre le tracking guidé depuis l'état "arrivé à proximité"
  /// Nettoie la navigation et démarre le suivi de la randonnée
  Future<void> startGuidedHikeFromNearStart(MapboxMap mapboxMap) async {
    final currentState = state;

    if (currentState is! HikeNavigationNearStart) {
      return;
    }

    // Essayer de récupérer les coordonnées depuis l'état ou depuis activeHikeInfo
    List<List<double>>? hikeRouteCoordinates =
        currentState.hikeRouteCoordinates;

    // Si les coordonnées ne sont pas dans l'état, essayer de les récupérer depuis activeHikeInfo
    if (hikeRouteCoordinates == null && currentState.activeHikeInfo != null) {
      final hikeInfo = currentState.activeHikeInfo!;
      final hikeIndex = hikeInfo['hikeIndex'] ?? hikeInfo['routeIndex'];

      if (hikeIndex != null) {
        // Essayer de récupérer depuis routeSelectionProvider
        try {
          final routeSelectionState = _ref.read(routeSelectionProvider);
          if (routeSelectionState is RouteSelectionSelected) {
            final coords =
                routeSelectionState.allRoutes[hikeIndex]['coordinates']
                    as List<dynamic>?;
            if (coords != null && coords.isNotEmpty) {
              hikeRouteCoordinates = coords
                  .map(
                    (c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()],
                  )
                  .toList();
            }
          }
        } catch (e) {
          // Intentionally empty catch block
          // Ignorer l'erreur et continuer
        }
      }

      // Si toujours null, essayer directement depuis hikeInfo
      if (hikeRouteCoordinates == null) {
        final coords = hikeInfo['coordinates'] as List<dynamic>?;
        if (coords != null && coords.isNotEmpty) {
          hikeRouteCoordinates = coords
              .map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
              .toList();
        }
      }
    }

    if (hikeRouteCoordinates == null || hikeRouteCoordinates.isEmpty) {
      return;
    }

    // Nettoyer le tracé de navigation
    await cleanupNavigationRoute(mapboxMap);

    // Arrêter la surveillance
    stopMonitoringArrival();

    // Démarrer le tracking guidé
    _ref
        .read(guidedHikeTrackingProvider.notifier)
        .startTracking(
          routeCoordinates: hikeRouteCoordinates,
          hikeInfo: currentState.activeHikeInfo,
        );

    // Arrêter la navigation
    stopNavigation();
  }

  /// Oriente la caméra vers le chemin de navigation
  /// Centre la caméra sur la position actuelle avec une vue optimale du tracé
  Future<void> orientCameraToRoute({
    required MapboxMap mapboxMap,
    required gl.Position currentPosition,
  }) async {
    if (state is! HikeNavigationActive) {
      return;
    }

    final currentState = state as HikeNavigationActive;
    final route = currentState.route;

    if (route.isEmpty) {
      return;
    }

    // Récupérer la position GPS la plus récente
    final latestPosition =
        _ref.read(locationStateProvider).currentPosition ?? currentPosition;

    // Trouver le prochain point sur l'itinéraire de navigation
    // Le premier point est généralement très proche, on prend le 2ème ou 3ème point pour avoir une bonne direction
    int targetIndex = route.length > 2 ? 2 : 1;
    if (targetIndex >= route.length) {
      targetIndex = route.length - 1;
    }

    final targetPoint = route[targetIndex];
    final targetLon = targetPoint[0];
    final targetLat = targetPoint[1];

    // Calculer le bearing vers ce point
    final bearing = GeometryCalculationService.calculateBearing(
      latestPosition.latitude,
      latestPosition.longitude,
      targetLat,
      targetLon,
    );

    try {
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              latestPosition.longitude,
              latestPosition.latitude,
            ),
          ),
          zoom: 16.5,
          pitch: 55,
          bearing: bearing,
        ),
        MapAnimationOptions(duration: 800, startDelay: 0),
      );
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  @override
  void dispose() {
    _arrivalMonitoringTimer?.cancel();
    super.dispose();
  }
}
