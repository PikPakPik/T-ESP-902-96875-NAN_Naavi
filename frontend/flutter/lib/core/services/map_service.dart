import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:image/image.dart' as img;

/// Service for basic map operations and configuration
class MapService {
  /// Load and register an icon from assets to the map style
  static Future<void> ensureIconRegistered(
    StyleManager style,
    String iconId,
    String assetPath,
  ) async {
    try {
      await style.addStyleImage(
        iconId,
        1.0,
        await _loadAssetImage(assetPath),
        false,
        [],
        [],
        null,
      );
    } catch (e) {
      // Image loading errors are silently ignored
    }
  }

  /// Load an image from assets
  static Future<MbxImage> _loadAssetImage(String path) async {
    final byteData = await rootBundle.load(path);
    final bytes = byteData.buffer.asUint8List();
    final decoded = img.decodeImage(bytes)!;
    return MbxImage(width: decoded.width, height: decoded.height, data: bytes);
  }

  /// Setup location component for GPS tracking
  static Future<void> setupLocationComponent(MapboxMap mapboxMap) async {
    await mapboxMap.location.updateSettings(
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
  }

  /// Setup location component with custom navigation arrow (like AllTrails)
  static Future<void> setupNavigationArrow(MapboxMap mapboxMap) async {
    // Load the custom navigation arrow image as bytes (PNG for Mapbox compatibility)
    final byteData = await rootBundle.load('assets/icons/navigation_arrow.png');
    final arrowBytes = byteData.buffer.asUint8List();

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        puckBearingEnabled: true,
        // HEADING utilise le compas pour montrer où tu regardes (comme AllTrails)
        puckBearing: PuckBearing.HEADING,
        pulsingEnabled:
            true, // Enable pulsing blue circle like AllTrails/Google Maps
        showAccuracyRing: false, // Hide accuracy ring, keep only pulsing effect
        locationPuck: LocationPuck(
          locationPuck2D: LocationPuck2D(topImage: arrowBytes),
        ),
      ),
    );
  }

  /// Animate camera to a specific position with zoom
  static Future<void> animateCameraTo(
    MapboxMap mapboxMap,
    double longitude,
    double latitude,
    double zoom,
  ) async {
    await mapboxMap.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }
}
