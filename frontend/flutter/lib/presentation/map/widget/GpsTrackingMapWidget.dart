import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/data/models/gps_tracking_data.dart';
import 'package:naavi/data/models/route_data.dart';
import 'package:naavi/data/models/map_configuration.dart';
import 'package:naavi/core/services/tracking/gps_tracking_service.dart';
import 'package:naavi/core/services/map/route_management_service.dart';
import 'package:naavi/core/services/map/global_route_service.dart';

/// Specialized widget for GPS tracking functionality
class GpsTrackingMapWidget extends StatefulWidget {
  final GpsTrackingData data;
  final StaticRoutesData? routesData; // Add support for static routes

  const GpsTrackingMapWidget({super.key, required this.data, this.routesData});

  @override
  State<GpsTrackingMapWidget> createState() => _GpsTrackingMapWidgetState();
}

class _GpsTrackingMapWidgetState extends State<GpsTrackingMapWidget> {
  final GpsTrackingService _gpsService = GpsTrackingService();
  final RouteManagementService _routeService = RouteManagementService();
  late final MapConfiguration _mapConfig;
  MapboxMap? _mapboxMap;

  @override
  void initState() {
    super.initState();
    // Utiliser initialPosition si disponible, sinon currentPosition
    final position = widget.data.initialPosition ?? widget.data.currentPosition;
    _mapConfig = MapConfiguration.gpsTracking(position);
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("gpsTrackingMapWidget"),
      cameraOptions: _mapConfig.toCameraOptions(),
      styleUri: _mapConfig.styleUri,
      textureView: _mapConfig.textureView,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
      onScrollListener: (MapContentGestureContext context) {
        widget.data.onUserExploringChanged?.call(true);
        widget.data.onMapScroll?.call();
      },
      onZoomListener: (MapContentGestureContext context) {
        widget.data.onUserExploringChanged?.call(true);
      },
      onTapListener:
          (widget.data.onMapTap != null ||
              widget.data.onMapTapWithCoordinates != null)
          ? (MapContentGestureContext context) {
              widget.data.onMapTap?.call();
              if (widget.data.onMapTapWithCoordinates != null) {
                final point = context.point;
                widget.data.onMapTapWithCoordinates!(
                  point.coordinates.lat.toDouble(),
                  point.coordinates.lng.toDouble(),
                );
              }
            }
          : null,
    );
  }

  Future<void> _onMapCreated(MapboxMap controller) async {
    _mapboxMap = controller;

    // Configure natural, fluid gestures with momentum
    await controller.gestures.updateSettings(
      GesturesSettings(
        scrollDecelerationEnabled: true, // Natural momentum when panning
        pinchToZoomDecelerationEnabled: true, // Smooth zoom deceleration
        rotateDecelerationEnabled: true, // Smooth rotation deceleration
        scrollEnabled: true, // Enable smooth scrolling
        pinchToZoomEnabled: true, // Enable smooth pinch zoom
        rotateEnabled: true, // Enable smooth rotation
        quickZoomEnabled: true, // Enable quick zoom gestures
        pinchPanEnabled: true, // Allow pan during pinch
        simultaneousRotateAndPinchToZoomEnabled: true, // Multi-gesture support
      ),
    );

    await _gpsService.initializeTracking(controller, widget.data);

    // Sur Android, on augmente le marginTop car la barre de statut est différente
    final topMargin = Platform.isAndroid ? 80.0 : 60.0;

    // Ajuster le margin top et right de la boussole native de Mapbox
    await controller.compass.updateSettings(
      CompassSettings(marginTop: topMargin, marginRight: 10),
    );

    // ajuster l'echelle de la carte en fonction de la position de l'utilisateur
    await controller.scaleBar.updateSettings(
      ScaleBarSettings(marginTop: topMargin, marginLeft: 10),
    );

    await _gpsService.initializeTracking(controller, widget.data);
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    // Initialize static routes if available
    await _initializeRoutes();
  }

  @override
  void didUpdateWidget(GpsTrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si les routes passent de "données" à "null", les nettoyer de la carte
    if (oldWidget.routesData != null && widget.routesData == null) {
      debugPrint(
        '[GpsTrackingMapWidget] Routes data changed to null, cleaning up routes',
      );
      _routeService.cleanup();
    }

    // Si les routes passent de "null" à "données", les réinitialiser
    if (oldWidget.routesData == null &&
        widget.routesData != null &&
        _mapboxMap != null) {
      debugPrint(
        '[GpsTrackingMapWidget] Routes data restored, reinitializing routes',
      );
      _initializeRoutes();
    }
  }

  /// Initialize routes on the map
  Future<void> _initializeRoutes() async {
    if (widget.routesData != null &&
        widget.routesData!.hasRoutes &&
        _mapboxMap != null) {
      try {
        await _routeService.initializeRoutes(
          _mapboxMap!,
          widget.routesData!,
          fitCamera: false,
          onRouteSelected: widget.routesData!.onHikeSelected,
        );
        GlobalRouteService().registerRouteService(_routeService);
      } catch (e) {
        debugPrint('[GpsTrackingMapWidget] Error initializing routes: $e');
      }
    }
  }

  @override
  void dispose() {
    // Unregister from global service
    GlobalRouteService().unregisterRouteService();

    _routeService.cleanup();
    super.dispose();
  }
}
