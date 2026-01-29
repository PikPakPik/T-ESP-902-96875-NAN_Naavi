import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/models/location_state.dart';

void main() {
  group('LocationState', () {
    test('should create initial state with default values', () {
      const state = LocationState();

      expect(state.currentPosition, isNull);
      expect(state.isTracking, isFalse);
      expect(state.hasPermission, isFalse);
      expect(state.error, isNull);
    });

    test('should create state with custom values', () {
      final position = gl.Position(
        latitude: 47.2173,
        longitude: -1.5534,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 50.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 5.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final state = LocationState(
        currentPosition: position,
        isTracking: true,
        hasPermission: true,
        error: 'Test error',
      );

      expect(state.currentPosition, equals(position));
      expect(state.isTracking, isTrue);
      expect(state.hasPermission, isTrue);
      expect(state.error, equals('Test error'));
    });

    test('copyWith should update only specified fields', () {
      const initial = LocationState(isTracking: false, hasPermission: false);

      final updated = initial.copyWith(isTracking: true, hasPermission: true);

      expect(updated.isTracking, isTrue);
      expect(updated.hasPermission, isTrue);
      expect(updated.currentPosition, isNull);
      expect(updated.error, isNull);
    });

    test('copyWith should keep unchanged fields', () {
      final position = gl.Position(
        latitude: 47.2173,
        longitude: -1.5534,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 50.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 5.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final initial = LocationState(
        currentPosition: position,
        isTracking: true,
        hasPermission: true,
        error: 'Initial error',
      );

      final updated = initial.copyWith(isTracking: false);

      expect(updated.isTracking, isFalse);
      expect(updated.currentPosition, equals(position));
      expect(updated.hasPermission, isTrue);
      expect(updated.error, equals('Initial error'));
    });

    test('copyWith should handle null position', () {
      const initial = LocationState(isTracking: true, hasPermission: true);

      final updated = initial.copyWith(error: 'New error');

      expect(updated.currentPosition, isNull);
      expect(updated.isTracking, isTrue);
      expect(updated.hasPermission, isTrue);
      expect(updated.error, equals('New error'));
    });
  });
}
