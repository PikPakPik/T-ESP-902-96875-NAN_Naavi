import 'package:geolocator/geolocator.dart' as gl;

/// État de la localisation GPS
class LocationState {
  final gl.Position? currentPosition;
  final bool isTracking;
  final bool hasPermission;
  final String? error;

  const LocationState({
    this.currentPosition,
    this.isTracking = false,
    this.hasPermission = false,
    this.error,
  });

  LocationState copyWith({
    gl.Position? currentPosition,
    bool? isTracking,
    bool? hasPermission,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isTracking: isTracking ?? this.isTracking,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error ?? this.error,
    );
  }
}
