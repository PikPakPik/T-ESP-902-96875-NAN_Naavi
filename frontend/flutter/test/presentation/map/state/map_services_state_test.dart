import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/presentation/map/state/MapServicesState.dart';

class MockMapboxMap extends Mock implements MapboxMap {}

void main() {
  gl.Position createPosition({
    double latitude = 48.8566,
    double longitude = 2.3522,
  }) => gl.Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 100,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );

  group('MapServicesState', () {
    test('should create with default values', () {
      final state = MapServicesState();

      expect(state.currentPosition, isNull);
      expect(state.mapboxMapController, isNull);
      expect(state.isMapReady, isFalse);
      expect(state.isFirstPersonMode, isFalse);
    });

    test('should create with custom values', () {
      final position = createPosition();
      final state = MapServicesState(
        currentPosition: position,
        isMapReady: true,
        isFirstPersonMode: true,
      );

      expect(state.currentPosition, equals(position));
      expect(state.isMapReady, isTrue);
      expect(state.isFirstPersonMode, isTrue);
    });

    group('copyWith', () {
      test('should copy with new currentPosition', () {
        final state = MapServicesState();
        final position = createPosition();

        final newState = state.copyWith(currentPosition: position);

        expect(newState.currentPosition, equals(position));
        expect(newState.isMapReady, equals(state.isMapReady));
        expect(newState.isFirstPersonMode, equals(state.isFirstPersonMode));
      });

      test('should copy with new isMapReady', () {
        final state = MapServicesState();

        final newState = state.copyWith(isMapReady: true);

        expect(newState.isMapReady, isTrue);
        expect(newState.currentPosition, equals(state.currentPosition));
      });

      test('should copy with new isFirstPersonMode', () {
        final state = MapServicesState();

        final newState = state.copyWith(isFirstPersonMode: true);

        expect(newState.isFirstPersonMode, isTrue);
        expect(newState.isMapReady, equals(state.isMapReady));
      });

      test('should preserve values when copyWith called with no args', () {
        final position = createPosition();
        final state = MapServicesState(
          currentPosition: position,
          isMapReady: true,
          isFirstPersonMode: true,
        );

        final newState = state.copyWith();

        expect(newState.currentPosition, equals(position));
        expect(newState.isMapReady, isTrue);
        expect(newState.isFirstPersonMode, isTrue);
      });
    });
  });

  group('MapServicesNotifier', () {
    late MapServicesNotifier notifier;

    setUp(() {
      notifier = MapServicesNotifier();
    });

    test('should initialize with default state', () {
      expect(notifier.state.currentPosition, isNull);
      expect(notifier.state.mapboxMapController, isNull);
      expect(notifier.state.isMapReady, isFalse);
      expect(notifier.state.isFirstPersonMode, isFalse);
    });

    test('setCurrentPosition should update currentPosition', () {
      final position = createPosition();

      notifier.setCurrentPosition(position);

      expect(notifier.state.currentPosition, equals(position));
    });

    test('setFirstPersonMode should update isFirstPersonMode to true', () {
      notifier.setFirstPersonMode(true);

      expect(notifier.state.isFirstPersonMode, isTrue);
    });

    test('setFirstPersonMode should update isFirstPersonMode to false', () {
      notifier.setFirstPersonMode(true);
      notifier.setFirstPersonMode(false);

      expect(notifier.state.isFirstPersonMode, isFalse);
    });

    test('multiple updates should preserve previous state', () {
      final position = createPosition();

      notifier.setCurrentPosition(position);
      notifier.setFirstPersonMode(true);

      expect(notifier.state.currentPosition, equals(position));
      expect(notifier.state.isFirstPersonMode, isTrue);
    });

    test(
      'setMapController should update mapboxMapController and set isMapReady',
      () {
        final mockMapboxMap = MockMapboxMap();

        notifier.setMapController(mockMapboxMap);

        expect(notifier.state.mapboxMapController, equals(mockMapboxMap));
        expect(notifier.state.isMapReady, isTrue);
      },
    );

    test('setMapController should preserve other state values', () {
      final position = createPosition();
      final mockMapboxMap = MockMapboxMap();

      notifier.setCurrentPosition(position);
      notifier.setFirstPersonMode(true);
      notifier.setMapController(mockMapboxMap);

      expect(notifier.state.currentPosition, equals(position));
      expect(notifier.state.isFirstPersonMode, isTrue);
      expect(notifier.state.mapboxMapController, equals(mockMapboxMap));
      expect(notifier.state.isMapReady, isTrue);
    });
  });

  group('mapServicesProvider', () {
    test('should provide a MapServicesNotifier instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mapServicesProvider.notifier);
      expect(notifier, isA<MapServicesNotifier>());
    });

    test('should initialize with default state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(mapServicesProvider);
      expect(state.currentPosition, isNull);
      expect(state.mapboxMapController, isNull);
      expect(state.isMapReady, isFalse);
      expect(state.isFirstPersonMode, isFalse);
    });

    test('should provide same notifier on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier1 = container.read(mapServicesProvider.notifier);
      final notifier2 = container.read(mapServicesProvider.notifier);
      expect(identical(notifier1, notifier2), isTrue);
    });

    test('should dispose properly when container is disposed', () {
      final container = ProviderContainer();
      final notifier = container.read(mapServicesProvider.notifier);
      expect(notifier.mounted, isTrue);

      container.dispose();
      expect(notifier.mounted, isFalse);
    });
  });
}
