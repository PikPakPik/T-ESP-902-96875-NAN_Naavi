import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/data/models/map_configuration.dart';

void main() {
  group('MapConfiguration', () {
    late Point testCenter;
    late double testZoom;
    late String testStyleUri;

    setUp(() {
      testCenter = Point(coordinates: Position(-1.5536, 47.2184));
      testZoom = 13.0;
      testStyleUri = MapboxStyles.OUTDOORS;
    });

    test('should create MapConfiguration with all required fields', () {
      final config = MapConfiguration(
        center: testCenter,
        zoom: testZoom,
        styleUri: testStyleUri,
      );

      expect(config.center, testCenter);
      expect(config.zoom, testZoom);
      expect(config.styleUri, testStyleUri);
      expect(config.textureView, true); // Default value
    });

    test('should use default textureView value of true', () {
      final config = MapConfiguration(
        center: testCenter,
        zoom: testZoom,
        styleUri: testStyleUri,
      );

      expect(config.textureView, true);
    });

    test('should allow custom textureView value', () {
      final config = MapConfiguration(
        center: testCenter,
        zoom: testZoom,
        styleUri: testStyleUri,
        textureView: false,
      );

      expect(config.textureView, false);
    });

    group('gpsTracking factory', () {
      test('should create config with provided GPS position', () {
        final position = gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 35.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final config = MapConfiguration.gpsTracking(position);

        expect(config.center.coordinates.lng, 2.3522);
        expect(config.center.coordinates.lat, 48.8566);
        expect(config.zoom, 15.0); // Closer zoom when position is available
        expect(config.styleUri, MapboxStyles.OUTDOORS);
        expect(config.textureView, true);
      });

      test('should create config with default position when GPS is null', () {
        final config = MapConfiguration.gpsTracking(null);

        expect(config.center.coordinates.lng, -1.5536);
        expect(config.center.coordinates.lat, 47.2184);
        expect(config.zoom, 13.0); // Default zoom when no position
        expect(config.styleUri, MapboxStyles.OUTDOORS);
      });

      test('should use OUTDOORS style for GPS tracking', () {
        final config = MapConfiguration.gpsTracking(null);

        expect(config.styleUri, MapboxStyles.OUTDOORS);
      });

      test('should use closer zoom level when GPS position is available', () {
        final position = gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 35.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final configWithPosition = MapConfiguration.gpsTracking(position);
        final configWithoutPosition = MapConfiguration.gpsTracking(null);

        expect(configWithPosition.zoom, 15.0);
        expect(configWithoutPosition.zoom, 13.0);
        expect(configWithPosition.zoom, greaterThan(configWithoutPosition.zoom));
      });
    });

    group('staticRoutes factory', () {
      test('should create config with default center position', () {
        final config = MapConfiguration.staticRoutes();

        expect(config.center.coordinates.lng, -1.5536);
        expect(config.center.coordinates.lat, 47.2184);
      });

      test('should use zoom level 12.0 for static routes', () {
        final config = MapConfiguration.staticRoutes();

        expect(config.zoom, 12.0);
      });

      test('should use MAPBOX_STREETS style for static routes', () {
        final config = MapConfiguration.staticRoutes();

        expect(config.styleUri, MapboxStyles.MAPBOX_STREETS);
      });

      test('should use default textureView value', () {
        final config = MapConfiguration.staticRoutes();

        expect(config.textureView, true);
      });
    });

    group('toCameraOptions', () {
      test('should convert to CameraOptions with correct center', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: testZoom,
          styleUri: testStyleUri,
        );

        final cameraOptions = config.toCameraOptions();

        expect(cameraOptions.center, testCenter);
      });

      test('should convert to CameraOptions with correct zoom', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: testZoom,
          styleUri: testStyleUri,
        );

        final cameraOptions = config.toCameraOptions();

        expect(cameraOptions.zoom, testZoom);
      });

      test('should maintain precision for coordinates', () {
        final preciseCenter = Point(
          coordinates: Position(-1.55367890123456, 47.21845678901234),
        );
        final config = MapConfiguration(
          center: preciseCenter,
          zoom: 15.5,
          styleUri: testStyleUri,
        );

        final cameraOptions = config.toCameraOptions();

        expect(cameraOptions.center?.coordinates.lng, -1.55367890123456);
        expect(cameraOptions.center?.coordinates.lat, 47.21845678901234);
        expect(cameraOptions.zoom, 15.5);
      });
    });

    group('Different Style URIs', () {
      test('should support OUTDOORS style', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: testZoom,
          styleUri: MapboxStyles.OUTDOORS,
        );

        expect(config.styleUri, MapboxStyles.OUTDOORS);
      });

      test('should support MAPBOX_STREETS style', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: testZoom,
          styleUri: MapboxStyles.MAPBOX_STREETS,
        );

        expect(config.styleUri, MapboxStyles.MAPBOX_STREETS);
      });

      test('should support SATELLITE style', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: testZoom,
          styleUri: MapboxStyles.SATELLITE,
        );

        expect(config.styleUri, MapboxStyles.SATELLITE);
      });

      test('should support SATELLITE_STREETS style', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: testZoom,
          styleUri: MapboxStyles.SATELLITE_STREETS,
        );

        expect(config.styleUri, MapboxStyles.SATELLITE_STREETS);
      });
    });

    group('Zoom Levels', () {
      test('should support minimum zoom level', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: 0.0,
          styleUri: testStyleUri,
        );

        expect(config.zoom, 0.0);
      });

      test('should support maximum zoom level', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: 22.0,
          styleUri: testStyleUri,
        );

        expect(config.zoom, 22.0);
      });

      test('should support fractional zoom levels', () {
        final config = MapConfiguration(
          center: testCenter,
          zoom: 13.5,
          styleUri: testStyleUri,
        );

        expect(config.zoom, 13.5);
      });
    });

    group('Edge Cases', () {
      test('should handle position at equator and prime meridian', () {
        final center = Point(coordinates: Position(0.0, 0.0));
        final config = MapConfiguration(
          center: center,
          zoom: testZoom,
          styleUri: testStyleUri,
        );

        expect(config.center.coordinates.lng, 0.0);
        expect(config.center.coordinates.lat, 0.0);
      });

      test('should handle position at maximum longitude', () {
        final center = Point(coordinates: Position(180.0, 0.0));
        final config = MapConfiguration(
          center: center,
          zoom: testZoom,
          styleUri: testStyleUri,
        );

        expect(config.center.coordinates.lng, 180.0);
      });

      test('should handle position at minimum longitude', () {
        final center = Point(coordinates: Position(-180.0, 0.0));
        final config = MapConfiguration(
          center: center,
          zoom: testZoom,
          styleUri: testStyleUri,
        );

        expect(config.center.coordinates.lng, -180.0);
      });

      test('should handle position at north pole', () {
        final center = Point(coordinates: Position(0.0, 90.0));
        final config = MapConfiguration(
          center: center,
          zoom: testZoom,
          styleUri: testStyleUri,
        );

        expect(config.center.coordinates.lat, 90.0);
      });

      test('should handle position at south pole', () {
        final center = Point(coordinates: Position(0.0, -90.0));
        final config = MapConfiguration(
          center: center,
          zoom: testZoom,
          styleUri: testStyleUri,
        );

        expect(config.center.coordinates.lat, -90.0);
      });

      test('should handle GPS position with extreme accuracy values', () {
        final position = gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 0.1, // Very high accuracy
          altitude: 35.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final config = MapConfiguration.gpsTracking(position);

        expect(config.center.coordinates.lat, 48.8566);
        expect(config.center.coordinates.lng, 2.3522);
      });
    });

    group('Factory Methods Comparison', () {
      test('gpsTracking and staticRoutes should have different default zooms', () {
        final gpsConfig = MapConfiguration.gpsTracking(null);
        final staticConfig = MapConfiguration.staticRoutes();

        expect(gpsConfig.zoom, isNot(equals(staticConfig.zoom)));
      });

      test('gpsTracking and staticRoutes should have different styles', () {
        final gpsConfig = MapConfiguration.gpsTracking(null);
        final staticConfig = MapConfiguration.staticRoutes();

        expect(gpsConfig.styleUri, isNot(equals(staticConfig.styleUri)));
        expect(gpsConfig.styleUri, MapboxStyles.OUTDOORS);
        expect(staticConfig.styleUri, MapboxStyles.MAPBOX_STREETS);
      });

      test('gpsTracking and staticRoutes should have same default center', () {
        final gpsConfig = MapConfiguration.gpsTracking(null);
        final staticConfig = MapConfiguration.staticRoutes();

        expect(
          gpsConfig.center.coordinates.lng,
          staticConfig.center.coordinates.lng,
        );
        expect(
          gpsConfig.center.coordinates.lat,
          staticConfig.center.coordinates.lat,
        );
      });
    });
  });
}
