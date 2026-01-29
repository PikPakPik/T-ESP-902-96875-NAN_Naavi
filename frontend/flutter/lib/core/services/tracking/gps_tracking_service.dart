import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/data/models/gps_tracking_data.dart';
import 'package:naavi/core/services/map_service.dart';

/// Service for GPS tracking functionality
class GpsTrackingService {
  /// Initialize GPS tracking on the map
  Future<void> initializeTracking(
    MapboxMap mapboxMap,
    GpsTrackingData data,
  ) async {
    // Setup location component
    await MapService.setupLocationComponent(mapboxMap);

    // Setup permission tracking if needed
    if (data.onSetupPositionTracking != null) {
      await _setupPositionTracking(data.onSetupPositionTracking!);
    }

    // Call onMapReady callback if provided
    if (data.onMapReady != null) {
      data.onMapReady!(mapboxMap);
    }
  }

  /// Setup location permissions and tracking
  Future<void> _setupPositionTracking(
    Function() onSetupPositionTracking,
  ) async {
    try {
      // Permissions gérées centralement par LocationStateNotifier
      // Juste appeler le callback
      onSetupPositionTracking();
    } catch (e) {
      // Intentionally empty catch block
    }
  }
}
