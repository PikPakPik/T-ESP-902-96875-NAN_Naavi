import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/data/models/route_data.dart';
import 'package:naavi/core/services/route_service.dart';
import 'package:naavi/core/services/map_service.dart';

/// Service for managing static routes on the map with state
class RouteManagementService {
  final RouteService _routeService = RouteService();
  MapboxMap? _mapboxMap;
  List<RouteInfo> _routes = [];
  int? _highlightedRouteIndex;
  Function(Map<String, dynamic>)? _onRouteSelected;

  List<RouteInfo> get routes => _routes;
  int? get highlightedRouteIndex => _highlightedRouteIndex;

  /// Initialize routes on the map with clustering
  Future<void> initializeRoutes(
    MapboxMap mapboxMap,
    StaticRoutesData data, {
    bool fitCamera = true,
    Function(Map<String, dynamic>)? onRouteSelected,
  }) async {
    _mapboxMap = mapboxMap;
    _onRouteSelected = onRouteSelected;

    if (!data.hasRoutes) {
      return;
    }

    // Initialize routes from WKB data
    _routes = _routeService.initializeRoutes(
      data.wkbStrings,
      data.routeNames,
      data.routesData,
    );

    // Ensure start icon is registered
    await MapService.ensureIconRegistered(
      mapboxMap.style,
      'start-point-icon',
      'assets/icons/start-icon.png',
    );

    // Add all routes to the map (without individual start points)
    for (int i = 0; i < _routes.length; i++) {
      await _routeService.addRouteToMap(
        mapboxMap,
        _routes[i],
        i,
        addStartPoint: false, // Use clustered points instead
      );
    }

    // Add clustered start points
    await _routeService.addClusteredStartPoints(mapboxMap, _routes);

    // Setup clustered interactions
    await _routeService.setupClusteredRouteInteractions(
      mapboxMap,
      _routes,
      _onRouteTapped,
    );

    // Fit camera to show all routes only if requested
    // (skip if we have an initial position to preserve user's location)
    if (fitCamera) {
      await _routeService.fitCameraToRoutes(mapboxMap, _routes);
    }
  }

  /// Handle route tap event
  void _onRouteTapped(int routeIndex) {
    if (routeIndex < _routes.length) {
      final route = _routes[routeIndex];

      // Show and highlight the selected route
      _showAndHighlightRoute(routeIndex);

      // Trigger callback with route info
      _onRouteSelected?.call(route.hikeLine.info);
    }
  }

  /// Show and highlight a specific route
  Future<void> _showAndHighlightRoute(int routeIndex) async {
    if (_mapboxMap == null || routeIndex >= _routes.length) return;

    try {
      await _routeService.showAndHighlightRoute(
        _mapboxMap!,
        routeIndex,
        _highlightedRouteIndex,
        _routes,
      );

      _highlightedRouteIndex = routeIndex;
    } catch (e) {
      // Route highlight errors are silently ignored
    }
  }

  /// Get route info for a specific index
  RouteInfo? getRoute(int index) {
    if (index >= 0 && index < _routes.length) {
      return _routes[index];
    }
    return null;
  }

  /// Hide currently selected route only (public method for popup close)
  Future<void> hideCurrentRoute() async {
    if (_mapboxMap != null && _highlightedRouteIndex != null) {
      try {
        await _mapboxMap!.style.setStyleLayerProperty(
          "linestring-layer-$_highlightedRouteIndex",
          "visibility",
          "none",
        );
        _highlightedRouteIndex = null;
      } catch (e) {
        // Layer visibility errors are silently ignored
      }
    }
  }

  /// Cleanup service resources and remove all routes from map
  Future<void> cleanup() async {
    // Supprimer toutes les routes de la carte
    if (_mapboxMap != null && _routes.isNotEmpty) {
      try {
        debugPrint(
          '[RouteManagementService] Removing ${_routes.length} routes from map',
        );
        await _routeService.removeAllRoutes(_mapboxMap!, _routes.length);
        debugPrint('[RouteManagementService] Routes removed successfully');
      } catch (e) {
        // Ignorer les erreurs si la map est déjà disposée
        debugPrint('[RouteManagementService] Error removing routes: $e');
      }
    } else {
      debugPrint(
        '[RouteManagementService] cleanup: mapboxMap=$_mapboxMap, routes count=${_routes.length}',
      );
    }
    _mapboxMap = null;
    _routes = [];
    _highlightedRouteIndex = null;
    _onRouteSelected = null;
  }
}
