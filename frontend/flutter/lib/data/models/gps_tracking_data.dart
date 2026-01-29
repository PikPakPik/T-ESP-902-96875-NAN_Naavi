import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Data structure for GPS tracking functionality
class GpsTrackingData {
  final gl.Position? currentPosition;
  final gl.Position? initialPosition;
  final double? deviceHeading;
  final Function(bool isExploring)? onUserExploringChanged;
  final Function()? onSetupPositionTracking;
  final Function(MapboxMap)? onMapReady;
  final VoidCallback? onMapTap;
  final Function(double latitude, double longitude)? onMapTapWithCoordinates;
  final VoidCallback? onMapScroll;

  const GpsTrackingData({
    this.currentPosition,
    this.initialPosition,
    this.deviceHeading,
    this.onUserExploringChanged,
    this.onSetupPositionTracking,
    this.onMapReady,
    this.onMapTap,
    this.onMapTapWithCoordinates,
    this.onMapScroll,
  });

  bool get isTrackingMode =>
      currentPosition != null || onSetupPositionTracking != null;
}

/// Camera state for tracking changes
class CameraState {
  final double? zoom;
  final double? pitch;
  final Point? center;

  const CameraState({this.zoom, this.pitch, this.center});

  CameraState copyWith({double? zoom, double? pitch, Point? center}) {
    return CameraState(
      zoom: zoom ?? this.zoom,
      pitch: pitch ?? this.pitch,
      center: center ?? this.center,
    );
  }

  bool hasChanged(CameraState other) {
    return zoom != other.zoom ||
        pitch != other.pitch ||
        (center?.coordinates.lng != other.center?.coordinates.lng ||
            center?.coordinates.lat != other.center?.coordinates.lat);
  }
}
