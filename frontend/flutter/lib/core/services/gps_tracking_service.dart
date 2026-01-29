import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide CameraState;
import 'package:naavi/data/models/gps_tracking_data.dart';

/// Service for GPS tracking functionality
class GpsTrackingService {
  CameraState _lastCameraState = const CameraState();

  /// Handle camera changes and detect user exploration
  bool handleCameraChange(
    CameraChangedEventData data,
    Function(bool)? onUserExploringChanged,
  ) {
    final camera = data.cameraState;
    final newCameraState = CameraState(
      zoom: camera.zoom,
      pitch: camera.pitch,
      center: camera.center,
    );

    final isExploring = newCameraState.hasChanged(_lastCameraState);

    if (onUserExploringChanged != null) {
      onUserExploringChanged(isExploring);
    }

    _lastCameraState = newCameraState;
    return isExploring;
  }

  /// Check and request location permissions
  Future<void> setupLocationPermissions(Function() onPermissionGranted) async {
    bool serviceEnabled;
    gl.LocationPermission permission;

    serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service disabled');
    }

    permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    onPermissionGranted();
  }
}
