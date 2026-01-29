import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/presentation/common/camera/CameraState.dart';

void main() {
  group('CameraInitial', () {
    test('should initialize with correct default values', () {
      const state = CameraInitial();

      expect(state.isFirstPersonMode, isFalse);
      expect(state.isUserExploring, isFalse);
      expect(state.currentPosition, isNull);
    });
  });

  group('CameraFirstPersonMode', () {
    test('should initialize in first person mode', () {
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

      final state = CameraFirstPersonMode(
        currentPosition: position,
        isUserExploring: false,
      );

      expect(state.isFirstPersonMode, isTrue);
      expect(state.isUserExploring, isFalse);
      expect(state.currentPosition, equals(position));
    });

    test('should support user exploring in first person mode', () {
      const state = CameraFirstPersonMode(
        currentPosition: null,
        isUserExploring: true,
      );

      expect(state.isFirstPersonMode, isTrue);
      expect(state.isUserExploring, isTrue);
    });
  });

  group('CameraNormalMode', () {
    test('should initialize in normal mode without position', () {
      const state = CameraNormalMode();

      expect(state.isFirstPersonMode, isFalse);
      expect(state.isUserExploring, isFalse);
      expect(state.currentPosition, isNull);
    });

    test('should initialize in normal mode with position', () {
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

      final state = CameraNormalMode(currentPosition: position);

      expect(state.isFirstPersonMode, isFalse);
      expect(state.isUserExploring, isFalse);
      expect(state.currentPosition, equals(position));
    });
  });

  group('CameraUserExploring', () {
    test('should indicate user is exploring in normal mode', () {
      const state = CameraUserExploring(isFirstPersonMode: false);

      expect(state.isFirstPersonMode, isFalse);
      expect(state.isUserExploring, isTrue);
      expect(state.currentPosition, isNull);
    });

    test('should indicate user is exploring in first person mode', () {
      const state = CameraUserExploring(isFirstPersonMode: true);

      expect(state.isFirstPersonMode, isTrue);
      expect(state.isUserExploring, isTrue);
      expect(state.currentPosition, isNull);
    });

    test('should support position while exploring', () {
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

      final state = CameraUserExploring(
        isFirstPersonMode: false,
        currentPosition: position,
      );

      expect(state.currentPosition, equals(position));
    });
  });

  group('CameraState type checking', () {
    test('should distinguish between different state types', () {
      const initial = CameraInitial();
      const firstPerson = CameraFirstPersonMode(
        currentPosition: null,
        isUserExploring: false,
      );
      const normal = CameraNormalMode();
      const exploring = CameraUserExploring(isFirstPersonMode: false);

      expect(initial, isA<CameraInitial>());
      expect(firstPerson, isA<CameraFirstPersonMode>());
      expect(normal, isA<CameraNormalMode>());
      expect(exploring, isA<CameraUserExploring>());
    });
  });
}
