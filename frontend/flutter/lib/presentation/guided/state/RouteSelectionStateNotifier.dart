import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/hiking_routes_service.dart';
import '../../../core/services/hikes_api_service.dart';
import '../../../data/models/hike_dto.dart';
import 'RouteSelectionState.dart';
import '../../../core/utils/utils.dart';

/// Gère le chargement et la sélection des itinéraires de randonnée
/// Extrait de HomeMapExplorerPage (~100 lignes)
class RouteSelectionStateNotifier extends StateNotifier<RouteSelectionState> {
  final HikingRoutesService routesService;
  final HikesApiService? hikesApiService;

  RouteSelectionStateNotifier({
    required this.routesService,
    this.hikesApiService,
  }) : super(const RouteSelectionLoading());

  /// Charge les itinéraires depuis les fichiers JSON
  Future<void> loadRoutes({
    List<String>? providedWkbStrings,
    List<String>? providedRouteNames,
  }) async {
    state = const RouteSelectionLoading();

    try {
      List<String> wkbStrings;
      List<String> routeNames;

      // Si des WKB sont fournis, les utiliser directement
      if (providedWkbStrings != null && providedWkbStrings.isNotEmpty) {
        wkbStrings = providedWkbStrings;
        routeNames = providedRouteNames ?? [];
      } else {
        // Sinon, charger depuis les fichiers JSON
        wkbStrings = await HikingRoutesService.getWKBStrings();
        routeNames = await HikingRoutesService.getRouteNames();
      }

      // Construire la liste de routes
      final routes = <Map<String, dynamic>>[];
      for (int i = 0; i < wkbStrings.length; i++) {
        routes.add({
          'wkb': wkbStrings[i],
          'name': i < routeNames.length ? routeNames[i] : 'Route ${i + 1}',
        });
      }

      state = RouteSelectionLoaded(
        routes: routes,
        wkbStrings: wkbStrings,
        routeNames: routeNames,
      );
    } catch (e) {
      state = RouteSelectionError('Erreur lors du chargement: $e');
    }
  }

  /// Sélectionne un itinéraire
  void selectRoute(Map<String, dynamic> hikeInfo) {
    final currentState = state;

    if (currentState is RouteSelectionLoaded) {
      state = RouteSelectionSelected(
        selectedHikeInfo: hikeInfo,
        allRoutes: currentState.routes,
        wkbStrings: currentState.wkbStrings,
        routeNames: currentState.routeNames,
      );
    } else if (currentState is RouteSelectionSelected) {
      state = RouteSelectionSelected(
        selectedHikeInfo: hikeInfo,
        allRoutes: currentState.allRoutes,
        wkbStrings: currentState.wkbStrings,
        routeNames: currentState.routeNames,
      );
    }
  }

  /// Désélectionne l'itinéraire actuel
  void deselectRoute() {
    final currentState = state;

    if (currentState is RouteSelectionSelected) {
      state = RouteSelectionLoaded(
        routes: currentState.allRoutes,
        wkbStrings: currentState.wkbStrings,
        routeNames: currentState.routeNames,
      );
    }
  }

  /// Obtient les coordonnées d'une route par son index
  List<List<double>>? getRouteCoordinates(int routeIndex) {
    final currentState = state;

    if (currentState is RouteSelectionLoaded ||
        currentState is RouteSelectionSelected) {
      final routes = currentState is RouteSelectionLoaded
          ? currentState.routes
          : (currentState as RouteSelectionSelected).allRoutes;

      if (routeIndex >= 0 && routeIndex < routes.length) {
        final route = routes[routeIndex];
        // Note: Cette méthode retourne les coordonnées si elles sont disponibles
        // Sinon, il faudra décoder le WKB ailleurs
        return route['coordinates'] as List<List<double>>?;
      }
    }

    return null;
  }

  /// Vérifie si des routes sont chargées
  bool get hasRoutes {
    final currentState = state;
    return currentState is RouteSelectionLoaded ||
        currentState is RouteSelectionSelected;
  }

  /// Vérifie si une route est sélectionnée
  bool get hasSelection => state is RouteSelectionSelected;

  /// Obtient l'itinéraire sélectionné
  Map<String, dynamic>? get selectedHike {
    final currentState = state;
    return currentState is RouteSelectionSelected
        ? currentState.selectedHikeInfo
        : null;
  }

  /// Charge les randonnées depuis l'API en fonction de la position
  Future<void> loadHikesFromApi({
    required double latitude,
    required double longitude,
    int radius = 20,
  }) async {
    if (hikesApiService == null) {
      state = const RouteSelectionError('HikesApiService non disponible');
      return;
    }

    state = const RouteSelectionLoading();

    try {
      // Ajouter un timeout de 10 secondes
      PaginatedHikesResponse? response;
      try {
        response = await hikesApiService!
            .getHikes(latitude: latitude, longitude: longitude, radius: radius)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                // En cas de timeout, retourner null pour afficher la carte quand même
                return null;
              },
            );
      } on TimeoutException {
        // Timeout atteint, on continue avec response = null pour afficher la carte
        response = null;
      }

      if (response == null || response.items.isEmpty) {
        // Si timeout ou aucune randonnée, afficher la carte avec une liste vide
        state = const RouteSelectionLoaded(
          routes: [],
          wkbStrings: [],
          routeNames: [],
        );
        return;
      }

      final routes = <Map<String, dynamic>>[];
      final wkbStrings = <String>[];
      final routeNames = <String>[];

      for (final hike in response.items) {
        if (hike.wkbGeometry != null && hike.wkbGeometry!.isNotEmpty) {
          // Convertir la distance de mètres en km (avec 1 décimale)
          final distanceKm = (hike.distance / 1000).toStringAsFixed(1);

          // Calculer le dénivelé positif depuis le WKB
          final elevationGain = _calculateElevationGain(hike.wkbGeometry!);

          // Estimer la durée (règle simple: ~4km/h en plat + 300m/h en montée)
          final durationMinutes = _estimateDuration(
            hike.distance,
            elevationGain,
          );
          final durationText = _formatDuration(durationMinutes);

          routes.add({
            'id': hike.id,
            'wkb': hike.wkbGeometry,
            'name': hike.name,
            'location': hike.location,
            'difficulty': hike.difficulty.value,
            'distance': distanceKm, // En km maintenant
            'denivele': elevationGain.round(), // Dénivelé en mètres
            'duree': durationText, // Durée estimée
            'startLat': hike.startingPointLatitude,
            'startLon': hike.startingPointLongitude,
            'start_point': {
              'latitude': hike.startingPointLatitude,
              'longitude': hike.startingPointLongitude,
            },
            'source': hike.source.value,
            'hikeIndex': routes.length,
          });
          wkbStrings.add(hike.wkbGeometry!);
          routeNames.add(hike.name);
        }
      }

      if (routes.isEmpty) {
        // Si aucune randonnée valide, afficher la carte avec une liste vide
        state = const RouteSelectionLoaded(
          routes: [],
          wkbStrings: [],
          routeNames: [],
        );
        return;
      }

      state = RouteSelectionLoaded(
        routes: routes,
        wkbStrings: wkbStrings,
        routeNames: routeNames,
      );
    } catch (e) {
      // En cas d'erreur, afficher la carte avec une liste vide plutôt qu'une erreur
      state = const RouteSelectionLoaded(
        routes: [],
        wkbStrings: [],
        routeNames: [],
      );
    }
  }

  /// Calcule le dénivelé positif depuis un WKB
  double _calculateElevationGain(String wkbString) {
    try {
      final lineString = decodeWKBFromString(wkbString);
      if (lineString.chain.positionCount < 2) return 0;

      double elevationGain = 0;
      double? previousElevation;

      for (int i = 0; i < lineString.chain.positionCount; i++) {
        final pos = lineString.chain[i];
        // La position z contient l'altitude si disponible
        if (pos.is3D) {
          if (previousElevation != null) {
            final diff = pos.z - previousElevation;
            if (diff > 0) {
              elevationGain += diff;
            }
          }
          previousElevation = pos.z;
        }
      }

      return elevationGain;
    } catch (e) {
      return 0;
    }
  }

  /// Estime la durée en minutes basée sur la distance et le dénivelé
  /// Règle de Naismith: 5 km/h en plat + 10 min par 100m de dénivelé
  int _estimateDuration(int distanceMeters, double elevationGainMeters) {
    final distanceKm = distanceMeters / 1000;

    // Temps de marche horizontal (5 km/h)
    final horizontalTime = (distanceKm / 5) * 60; // en minutes

    // Temps de montée (10 min par 100m)
    final verticalTime = (elevationGainMeters / 100) * 10; // en minutes

    return (horizontalTime + verticalTime).round();
  }

  /// Formate une durée en minutes en texte lisible
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}min';
  }
}
