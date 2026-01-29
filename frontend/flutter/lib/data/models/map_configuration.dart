import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Configuration for map initialization and display
class MapConfiguration {
  final Point center;
  final double zoom;
  final String styleUri;
  final bool textureView;

  const MapConfiguration({
    required this.center,
    required this.zoom,
    required this.styleUri,
    this.textureView = true,
  });

  /// Default configuration for GPS tracking mode
  static MapConfiguration gpsTracking(gl.Position? currentPosition) {
    return MapConfiguration(
      center: currentPosition != null
          ? Point(
              coordinates: Position(
                currentPosition.longitude,
                currentPosition.latitude,
              ),
            )
          : Point(coordinates: Position(-1.5536, 47.2184)),
      zoom: currentPosition != null ? 15.0 : 13.0, // Zoom plus proche si on a la position
      styleUri: MapboxStyles.OUTDOORS,
    );
  }

  /// Default configuration for static routes mode
  static MapConfiguration staticRoutes() {
    return MapConfiguration(
      center: Point(coordinates: Position(-1.5536, 47.2184)),
      zoom: 12.0,
      styleUri: MapboxStyles.MAPBOX_STREETS,
    );
  }

  CameraOptions toCameraOptions() {
    return CameraOptions(center: center, zoom: zoom);
  }
}
