import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/data/models/gps_tracking_data.dart';
import 'package:naavi/data/models/route_data.dart';
import 'package:naavi/presentation/map/widget/GpsTrackingMapWidget.dart';

import '../../core/services/tracking/camera_handler_service.dart';

class MapView extends StatefulWidget {
  final gl.Position? currentPosition;
  final gl.Position? initialPosition;
  final double? deviceHeading;
  final Function(bool isExploring)? onUserExploringChanged;
  final Function() onSetupPositionTracking;
  final Function(MapboxMap)? onMapReady;
  final List<String>? wkbStrings;
  final List<String>? routeNames;
  final List<Map<String, dynamic>>? routesData;
  final void Function(Map<String, dynamic> info)? onHikeSelected;
  final bool enableCameraTracking;
  final VoidCallback? onMapTap;
  final Function(double latitude, double longitude)? onMapTapWithCoordinates;
  final VoidCallback? onMapScroll;

  const MapView({
    super.key,
    required this.currentPosition,
    this.initialPosition,
    this.deviceHeading,
    this.onUserExploringChanged,
    required this.onSetupPositionTracking,
    this.onMapReady,
    this.wkbStrings,
    this.routeNames,
    this.routesData,
    this.onHikeSelected,
    this.enableCameraTracking = false,
    this.onMapTap,
    this.onMapTapWithCoordinates,
    this.onMapScroll,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late CameraHandlerService _cameraHandlerService;

  @override
  Widget build(BuildContext context) {
    // Utiliser GpsTrackingMap si on a des routes statiques ou un suivi GPS actif
    if (_isStaticRoutesMode || _isTrackingMode) {
      return _buildGpsTrackingMap();
    }

    // Sinon utiliser la carte basique
    return _buildBasicMap();
  }

  bool get _isTrackingMode => widget.currentPosition != null;

  bool get _isStaticRoutesMode =>
      widget.wkbStrings != null && widget.wkbStrings!.isNotEmpty;

  Widget _buildGpsTrackingMap() {
    final data = GpsTrackingData(
      currentPosition: widget.currentPosition,
      initialPosition: widget.initialPosition,
      deviceHeading: widget.deviceHeading,
      onUserExploringChanged: widget.onUserExploringChanged,
      onSetupPositionTracking: widget.onSetupPositionTracking,
      onMapReady: widget.onMapReady,
      onMapTap: widget.onMapTap,
      onMapTapWithCoordinates: widget.onMapTapWithCoordinates,
      onMapScroll: widget.onMapScroll,
    );

    StaticRoutesData? routesData;
    if (_isStaticRoutesMode) {
      routesData = StaticRoutesData(
        wkbStrings: widget.wkbStrings!,
        routeNames: widget.routeNames,
        routesData: widget.routesData,
        onHikeSelected: widget.onHikeSelected,
      );
    }

    return GpsTrackingMapWidget(data: data, routesData: routesData);
  }

  Widget _buildBasicMap() {
    // Utiliser la position initiale si disponible, sinon les coordonnées par défaut de Nantes
    final centerPosition = widget.initialPosition != null
        ? Position(
            widget.initialPosition!.longitude,
            widget.initialPosition!.latitude,
          )
        : Position(-1.5536, 47.2184);

    final zoom = widget.initialPosition != null ? 15.0 : 12.0;

    return MapWidget(
      key: const ValueKey("basicMapWidget"),
      cameraOptions: CameraOptions(
        center: Point(coordinates: centerPosition),
        zoom: zoom, // Zoom plus proche si on a la position
      ),
      styleUri: MapboxStyles.OUTDOORS,
      textureView: true,
      onMapCreated: _onMapCreated,
      onScrollListener: (MapContentGestureContext context) {
        if (widget.enableCameraTracking) {
          _cameraHandlerService.onUserInteractionStart();
        }
        widget.onMapScroll?.call();
      },
      onZoomListener: (MapContentGestureContext context) {
        if (widget.enableCameraTracking) {
          _cameraHandlerService.onUserInteractionStart();
        }
      },
      onTapListener: (MapContentGestureContext context) {
        if (widget.enableCameraTracking) {
          _cameraHandlerService.onUserInteractionStart();
        }
        widget.onMapTap?.call();
        if (widget.onMapTapWithCoordinates != null) {
          final point = context.point;
          widget.onMapTapWithCoordinates!(
            point.coordinates.lat.toDouble(),
            point.coordinates.lng.toDouble(),
          );
        }
      },
      onLongTapListener: (MapContentGestureContext context) {
        if (widget.enableCameraTracking) {
          _cameraHandlerService.onUserInteractionStart();
        }
      },
    );
  }

  void _onMapCreated(MapboxMap controller) async {
    _cameraHandlerService = CameraHandlerService(mapboxMap: controller);

    _cameraHandlerService.onUserInteractionChanged = (isInteracting) {
      widget.onUserExploringChanged?.call(isInteracting);
    };

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

    await controller.location.updateSettings(
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

    // Permissions GPS gérées centralement par LocationStateNotifier
    // Plus besoin de les demander ici

    if (widget.onMapReady != null) {
      widget.onMapReady!(controller);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
