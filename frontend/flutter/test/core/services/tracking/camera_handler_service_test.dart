import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/services/tracking/camera_handler_service.dart';

class MockMapboxMap extends Mock implements MapboxMap {}

class MockCameraState extends Mock implements CameraState {}

void main() {
  late CameraHandlerService service;
  late MockMapboxMap mockMapboxMap;

  setUpAll(() {
    registerFallbackValue(CameraOptions());
    registerFallbackValue(MapAnimationOptions());
  });

  setUp(() {
    mockMapboxMap = MockMapboxMap();
    service = CameraHandlerService(mapboxMap: mockMapboxMap);
  });

  group('CameraHandlerService - moveTo', () {
    test('should move camera to position with default parameters', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.moveTo(position);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should move camera with custom zoom', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.moveTo(position, zoom: 18.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should move camera with custom pitch and bearing', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.moveTo(position, pitch: 45.0, bearing: 90.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should move camera with custom duration', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.moveTo(position, duration: 500);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should move camera with padding', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      final padding = MbxEdgeInsets(top: 100, left: 50, bottom: 100, right: 50);

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.moveTo(position, padding: padding);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });
  });

  group('CameraHandlerService - enableFirstPersonMode', () {
    test('should enable first person mode with default parameters', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.enableFirstPersonMode(position, 90.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should enable first person mode with custom zoom', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.enableFirstPersonMode(position, 90.0, zoom: 20.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should enable first person mode with custom pitch', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.enableFirstPersonMode(position, 90.0, pitch: 60.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should enable first person mode with custom duration', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.enableFirstPersonMode(position, 90.0, duration: 300);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should handle zero heading', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.enableFirstPersonMode(position, 0.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should handle negative heading', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.enableFirstPersonMode(position, -45.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should handle heading > 360', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.enableFirstPersonMode(position, 450.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });
  });

  group('CameraHandlerService - updateBearing', () {
    test('should update bearing', () async {
      // Arrange
      when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

      // Act
      await service.updateBearing(180.0);

      // Assert
      verify(() => mockMapboxMap.setCamera(any())).called(1);
    });

    test('should handle zero bearing', () async {
      // Arrange
      when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

      // Act
      await service.updateBearing(0.0);

      // Assert
      verify(() => mockMapboxMap.setCamera(any())).called(1);
    });

    test('should handle negative bearing', () async {
      // Arrange
      when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

      // Act
      await service.updateBearing(-90.0);

      // Assert
      verify(() => mockMapboxMap.setCamera(any())).called(1);
    });
  });

  group('CameraHandlerService - resetToNormalView', () {
    test('should reset to normal view with default parameters', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.resetToNormalView(position);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should reset with custom zoom', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.resetToNormalView(position, zoom: 12.0);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });

    test('should reset with custom duration', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.resetToNormalView(position, duration: 500);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
    });
  });

  group('CameraHandlerService - updatePosition', () {
    test('should update position with default zoom', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

      // Act
      await service.updatePosition(position);

      // Assert
      verify(() => mockMapboxMap.setCamera(any())).called(1);
    });

    test('should update position with custom zoom', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

      // Act
      await service.updatePosition(position, zoom: 16.0);

      // Assert
      verify(() => mockMapboxMap.setCamera(any())).called(1);
    });
  });

  group('CameraHandlerService - getCurrentCamera', () {
    test('should get current camera state', () async {
      // Arrange
      final mockCameraState = MockCameraState();
      when(
        () => mockMapboxMap.getCameraState(),
      ).thenAnswer((_) async => mockCameraState);

      // Act
      final result = await service.getCurrentCamera();

      // Assert
      expect(result, equals(mockCameraState));
      verify(() => mockMapboxMap.getCameraState()).called(1);
    });
  });

  group('CameraHandlerService - User Interaction', () {
    test('should notify on user interaction start', () async {
      // Arrange
      bool? interactionState;
      service.onUserInteractionChanged = (isInteracting) {
        interactionState = isInteracting;
      };

      // Act
      service.onUserInteractionStart();

      // Assert
      expect(interactionState, isTrue);

      // Wait for timer
      await Future.delayed(const Duration(milliseconds: 600));
      expect(interactionState, isFalse);
    });

    test('should notify on user interaction end', () {
      // Arrange
      bool? interactionState;
      service.onUserInteractionChanged = (isInteracting) {
        interactionState = isInteracting;
      };

      // Act
      service.onUserInteractionEnd();

      // Assert
      expect(interactionState, isFalse);
    });

    test('should handle interaction start without callback', () {
      // Arrange - no callback set

      // Act & Assert - should not throw
      expect(() => service.onUserInteractionStart(), returnsNormally);
    });

    test('should handle interaction end without callback', () {
      // Arrange - no callback set

      // Act & Assert - should not throw
      expect(() => service.onUserInteractionEnd(), returnsNormally);
    });

    test('should cancel timer on interaction end', () async {
      // Arrange
      int callCount = 0;
      service.onUserInteractionChanged = (isInteracting) {
        callCount++;
      };

      // Act
      service.onUserInteractionStart();
      service.onUserInteractionEnd();

      // Wait for original timer duration
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert - callback should be called twice: start (true) and end (false)
      // but NOT a third time from the timer
      expect(callCount, equals(2));
    });

    test('should handle multiple interaction starts', () async {
      // Arrange
      final states = <bool>[];
      service.onUserInteractionChanged = (isInteracting) {
        states.add(isInteracting);
      };

      // Act
      service.onUserInteractionStart();
      await Future.delayed(const Duration(milliseconds: 100));
      service.onUserInteractionStart();
      await Future.delayed(const Duration(milliseconds: 100));
      service.onUserInteractionStart();

      // Assert - multiple starts should each cancel previous timer
      expect(states.every((state) => state == true), isTrue);
    });
  });

  group('CameraHandlerService - Dispose', () {
    test('should cancel timer on dispose', () async {
      // Arrange
      int callCount = 0;
      service.onUserInteractionChanged = (isInteracting) {
        callCount++;
      };

      service.onUserInteractionStart();

      // Act
      service.dispose();

      // Wait for timer duration
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert - timer should be cancelled, so only 1 call (from start)
      expect(callCount, equals(1));
    });

    test('should handle dispose without active timer', () {
      // Act & Assert - should not throw
      expect(() => service.dispose(), returnsNormally);
    });

    test('should handle multiple dispose calls', () {
      // Act & Assert - should not throw
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });
  });

  group('CameraHandlerService - Integration Scenarios', () {
    test('should handle complete first-person flow', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 45,
        headingAccuracy: 1,
        speed: 5,
        speedAccuracy: 1,
      );

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});
      when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

      // Act - Enable first person
      await service.enableFirstPersonMode(position, 90.0);

      // Update bearing
      await service.updateBearing(120.0);

      // Reset to normal
      await service.resetToNormalView(position);

      // Assert
      verify(() => mockMapboxMap.flyTo(any(), any())).called(2);
      verify(() => mockMapboxMap.setCamera(any())).called(1);
    });

    test('should handle position updates during navigation', () async {
      // Arrange
      final positions = List.generate(
        5,
        (i) => gl.Position(
          latitude: 48.8566 + i * 0.001,
          longitude: 2.3522 + i * 0.001,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 5,
          heading: i * 10.0,
          headingAccuracy: 1,
          speed: 5,
          speedAccuracy: 1,
        ),
      );

      when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

      // Act
      for (final position in positions) {
        await service.updatePosition(position);
      }

      // Assert
      verify(() => mockMapboxMap.setCamera(any())).called(5);
    });

    test('should handle interaction during camera movement', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      final states = <bool>[];
      service.onUserInteractionChanged = (isInteracting) {
        states.add(isInteracting);
      };

      when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});

      // Act
      await service.moveTo(position);
      service.onUserInteractionStart();
      await service.moveTo(position);
      service.onUserInteractionEnd();

      // Assert
      expect(states.contains(true), isTrue);
      expect(states.contains(false), isTrue);
    });
  });
}
