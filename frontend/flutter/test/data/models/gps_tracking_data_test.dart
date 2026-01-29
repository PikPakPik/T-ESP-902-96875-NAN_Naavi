import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide CameraState;
import 'package:naavi/data/models/gps_tracking_data.dart' as model;

void main() {
  group('GpsTrackingData', () {
    test('should create instance with all null fields', () {
      // Act
      const data = model.GpsTrackingData();

      // Assert
      expect(data.currentPosition, isNull);
      expect(data.initialPosition, isNull);
      expect(data.deviceHeading, isNull);
      expect(data.onUserExploringChanged, isNull);
      expect(data.onSetupPositionTracking, isNull);
      expect(data.onMapReady, isNull);
      expect(data.onMapTap, isNull);
    });

    test('should create instance with all fields', () {
      // Arrange
      final currentPos = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 100.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final initialPos = gl.Position(
        latitude: 48.8500,
        longitude: 2.3500,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 100.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      void onExploringChanged(bool isExploring) {}
      void onSetupTracking() {}
      void onMapReady(MapboxMap map) {}
      void onTap() {}

      // Act
      final data = model.GpsTrackingData(
        currentPosition: currentPos,
        initialPosition: initialPos,
        deviceHeading: 45.0,
        onUserExploringChanged: onExploringChanged,
        onSetupPositionTracking: onSetupTracking,
        onMapReady: onMapReady,
        onMapTap: onTap,
      );

      // Assert
      expect(data.currentPosition, equals(currentPos));
      expect(data.initialPosition, equals(initialPos));
      expect(data.deviceHeading, equals(45.0));
      expect(data.onUserExploringChanged, equals(onExploringChanged));
      expect(data.onSetupPositionTracking, equals(onSetupTracking));
      expect(data.onMapReady, equals(onMapReady));
      expect(data.onMapTap, equals(onTap));
    });

    test(
      'isTrackingMode should return true when currentPosition is not null',
      () {
        // Arrange
        final position = gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        );

        final data = model.GpsTrackingData(currentPosition: position);

        // Act & Assert
        expect(data.isTrackingMode, isTrue);
      },
    );

    test(
      'isTrackingMode should return true when onSetupPositionTracking is not null',
      () {
        // Arrange
        void onSetupTracking() {}
        final data = model.GpsTrackingData(
          onSetupPositionTracking: onSetupTracking,
        );

        // Act & Assert
        expect(data.isTrackingMode, isTrue);
      },
    );

    test('isTrackingMode should return true when both are not null', () {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 100.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      void onSetupTracking() {}

      final data = model.GpsTrackingData(
        currentPosition: position,
        onSetupPositionTracking: onSetupTracking,
      );

      // Act & Assert
      expect(data.isTrackingMode, isTrue);
    });

    test('isTrackingMode should return false when both are null', () {
      // Arrange
      const data = model.GpsTrackingData();

      // Act & Assert
      expect(data.isTrackingMode, isFalse);
    });

    test('should handle callbacks correctly', () {
      // Arrange
      bool exploringCalled = false;
      bool setupTrackingCalled = false;
      bool mapTapCalled = false;

      final data = model.GpsTrackingData(
        onUserExploringChanged: (isExploring) {
          exploringCalled = true;
        },
        onSetupPositionTracking: () {
          setupTrackingCalled = true;
        },
        onMapTap: () {
          mapTapCalled = true;
        },
      );

      // Act
      data.onUserExploringChanged?.call(true);
      data.onSetupPositionTracking?.call();
      data.onMapTap?.call();

      // Assert
      expect(exploringCalled, isTrue);
      expect(setupTrackingCalled, isTrue);
      expect(mapTapCalled, isTrue);
    });
  });

  group('CameraState', () {
    test('should create camera state with default null values', () {
      // Act
      const state = model.CameraState();

      // Assert
      expect(state.zoom, isNull);
      expect(state.pitch, isNull);
      expect(state.center, isNull);
    });

    test('should create camera state with all values', () {
      // Arrange
      const zoom = 15.0;
      const pitch = 45.0;
      final center = Point(coordinates: Position(2.3522, 48.8566));

      // Act
      final state = model.CameraState(zoom: zoom, pitch: pitch, center: center);

      // Assert
      expect(state.zoom, equals(zoom));
      expect(state.pitch, equals(pitch));
      expect(state.center, equals(center));
    });

    test('copyWith should create new instance with updated values', () {
      // Arrange
      final original = model.CameraState(
        zoom: 15.0,
        pitch: 0.0,
        center: Point(coordinates: Position(2.3522, 48.8566)),
      );

      // Act
      final updated = original.copyWith(zoom: 16.0);

      // Assert
      expect(updated.zoom, equals(16.0));
      expect(updated.pitch, equals(0.0));
      expect(updated.center, equals(original.center));
    });

    test('copyWith should keep original values when not specified', () {
      // Arrange
      final original = model.CameraState(
        zoom: 15.0,
        pitch: 45.0,
        center: Point(coordinates: Position(2.3522, 48.8566)),
      );

      // Act
      final updated = original.copyWith();

      // Assert
      expect(updated.zoom, equals(original.zoom));
      expect(updated.pitch, equals(original.pitch));
      expect(updated.center, equals(original.center));
    });

    test('hasChanged should return false for identical states', () {
      // Arrange
      final center = Point(coordinates: Position(2.3522, 48.8566));
      final state1 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center);
      final state2 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center);

      // Act & Assert
      expect(state1.hasChanged(state2), isFalse);
    });

    test('hasChanged should return true when zoom differs', () {
      // Arrange
      final center = Point(coordinates: Position(2.3522, 48.8566));
      final state1 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center);
      final state2 = model.CameraState(zoom: 16.0, pitch: 0.0, center: center);

      // Act & Assert
      expect(state1.hasChanged(state2), isTrue);
    });

    test('hasChanged should return true when pitch differs', () {
      // Arrange
      final center = Point(coordinates: Position(2.3522, 48.8566));
      final state1 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center);
      final state2 = model.CameraState(zoom: 15.0, pitch: 45.0, center: center);

      // Act & Assert
      expect(state1.hasChanged(state2), isTrue);
    });

    test('hasChanged should return true when center longitude differs', () {
      // Arrange
      final center1 = Point(coordinates: Position(2.3522, 48.8566));
      final center2 = Point(coordinates: Position(2.3600, 48.8566));
      final state1 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center1);
      final state2 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center2);

      // Act & Assert
      expect(state1.hasChanged(state2), isTrue);
    });

    test('hasChanged should return true when center latitude differs', () {
      // Arrange
      final center1 = Point(coordinates: Position(2.3522, 48.8566));
      final center2 = Point(coordinates: Position(2.3522, 48.8600));
      final state1 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center1);
      final state2 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center2);

      // Act & Assert
      expect(state1.hasChanged(state2), isTrue);
    });

    test('hasChanged should handle null values correctly', () {
      // Arrange
      const state1 = model.CameraState(zoom: 15.0);
      const state2 = model.CameraState(zoom: 15.0);

      // Act & Assert
      expect(state1.hasChanged(state2), isFalse);
    });

    test(
      'hasChanged should return true when one center is null and other is not',
      () {
        // Arrange
        const state1 = model.CameraState(zoom: 15.0, pitch: 0.0);
        final state2 = model.CameraState(
          zoom: 15.0,
          pitch: 0.0,
          center: Point(coordinates: Position(2.3522, 48.8566)),
        );

        // Act & Assert
        expect(state1.hasChanged(state2), isTrue);
      },
    );

    test('hasChanged should detect multiple simultaneous changes', () {
      // Arrange
      final center1 = Point(coordinates: Position(2.3522, 48.8566));
      final center2 = Point(coordinates: Position(2.3600, 48.8600));
      final state1 = model.CameraState(zoom: 15.0, pitch: 0.0, center: center1);
      final state2 = model.CameraState(
        zoom: 16.0,
        pitch: 45.0,
        center: center2,
      );

      // Act & Assert
      expect(state1.hasChanged(state2), isTrue);
    });
  });
}
