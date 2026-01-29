import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/presentation/explorer/state/ExplorerPageState.dart';

class MockMapboxMap extends Mock implements MapboxMap {}

void main() {
  late MockMapboxMap mockMapboxMap;

  setUp(() {
    mockMapboxMap = MockMapboxMap();
  });

  group('ExplorerPageInitial', () {
    test('should create initial state', () {
      const state = ExplorerPageInitial();
      expect(state, isA<ExplorerPageState>());
    });

    test('should be const', () {
      const state1 = ExplorerPageInitial();
      const state2 = ExplorerPageInitial();
      expect(identical(state1, state2), isTrue);
    });
  });

  group('ExplorerPageInitializing', () {
    test('should create with default step', () {
      const state = ExplorerPageInitializing();
      expect(state.step, equals('Initialisation...'));
      expect(state, isA<ExplorerPageState>());
    });

    test('should create with custom step', () {
      const state = ExplorerPageInitializing(step: 'Loading GPS...');
      expect(state.step, equals('Loading GPS...'));
    });

    test('should create with different initialization steps', () {
      const steps = [
        'Démarrage GPS...',
        'Chargement des randonnées...',
        'Initialisation boussole...',
      ];

      for (final step in steps) {
        final state = ExplorerPageInitializing(step: step);
        expect(state.step, equals(step));
      }
    });
  });

  group('ExplorerPageReady', () {
    test('should create with map controller', () {
      final state = ExplorerPageReady(mapController: mockMapboxMap);

      expect(state.mapController, equals(mockMapboxMap));
      expect(state.currentPosition, isNull);
      expect(state.hasCenteredOnInitialPosition, isFalse);
      expect(state, isA<ExplorerPageState>());
    });

    test('should create with current position', () {
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

      final state = ExplorerPageReady(
        mapController: mockMapboxMap,
        currentPosition: position,
      );

      expect(state.currentPosition, equals(position));
    });

    test('should create with hasCenteredOnInitialPosition flag', () {
      final state = ExplorerPageReady(
        mapController: mockMapboxMap,
        hasCenteredOnInitialPosition: true,
      );

      expect(state.hasCenteredOnInitialPosition, isTrue);
    });

    test('should create with all parameters', () {
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

      final state = ExplorerPageReady(
        mapController: mockMapboxMap,
        currentPosition: position,
        hasCenteredOnInitialPosition: true,
      );

      expect(state.mapController, equals(mockMapboxMap));
      expect(state.currentPosition, equals(position));
      expect(state.hasCenteredOnInitialPosition, isTrue);
    });

    group('copyWith', () {
      test('should copy with new map controller', () {
        final mockMap2 = MockMapboxMap();
        final state = ExplorerPageReady(mapController: mockMapboxMap);

        final newState = state.copyWith(mapController: mockMap2);

        expect(newState.mapController, equals(mockMap2));
        expect(newState.currentPosition, isNull);
        expect(newState.hasCenteredOnInitialPosition, isFalse);
      });

      test('should copy with new position', () {
        final position1 = gl.Position(
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

        final position2 = gl.Position(
          latitude: 48.8600,
          longitude: 2.3600,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 5,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        );

        final state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: position1,
        );

        final newState = state.copyWith(currentPosition: position2);

        expect(newState.currentPosition, equals(position2));
        expect(newState.mapController, equals(mockMapboxMap));
      });

      test('should copy with new centered flag', () {
        final state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: false,
        );

        final newState = state.copyWith(hasCenteredOnInitialPosition: true);

        expect(newState.hasCenteredOnInitialPosition, isTrue);
        expect(newState.mapController, equals(mockMapboxMap));
      });

      test('should keep original values when not specified', () {
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

        final state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: position,
          hasCenteredOnInitialPosition: true,
        );

        final newState = state.copyWith();

        expect(newState.mapController, equals(mockMapboxMap));
        expect(newState.currentPosition, equals(position));
        expect(newState.hasCenteredOnInitialPosition, isTrue);
      });

      test('should update all fields', () {
        final mockMap2 = MockMapboxMap();
        final position1 = gl.Position(
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

        final position2 = gl.Position(
          latitude: 48.8600,
          longitude: 2.3600,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 5,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        );

        final state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: position1,
          hasCenteredOnInitialPosition: false,
        );

        final newState = state.copyWith(
          mapController: mockMap2,
          currentPosition: position2,
          hasCenteredOnInitialPosition: true,
        );

        expect(newState.mapController, equals(mockMap2));
        expect(newState.currentPosition, equals(position2));
        expect(newState.hasCenteredOnInitialPosition, isTrue);
      });
    });
  });

  group('ExplorerPageError', () {
    test('should create with error message', () {
      const state = ExplorerPageError(message: 'GPS permission denied');

      expect(state.message, equals('GPS permission denied'));
      expect(state.details, isEmpty);
      expect(state, isA<ExplorerPageState>());
    });

    test('should create with error message and details', () {
      const state = ExplorerPageError(
        message: 'Initialization failed',
        details: ['GPS error', 'Network error'],
      );

      expect(state.message, equals('Initialization failed'));
      expect(state.details, equals(['GPS error', 'Network error']));
    });

    test('should handle empty details', () {
      const state = ExplorerPageError(
        message: 'Error',
        details: [],
      );

      expect(state.details, isEmpty);
    });

    test('should handle single detail', () {
      const state = ExplorerPageError(
        message: 'Error',
        details: ['Single detail'],
      );

      expect(state.details.length, equals(1));
      expect(state.details.first, equals('Single detail'));
    });

    test('should handle multiple details', () {
      const state = ExplorerPageError(
        message: 'Multiple errors occurred',
        details: ['Error 1', 'Error 2', 'Error 3'],
      );

      expect(state.details.length, equals(3));
      expect(state.details, contains('Error 1'));
      expect(state.details, contains('Error 2'));
      expect(state.details, contains('Error 3'));
    });
  });

  group('ExplorerPageState type checking', () {
    test('should distinguish between different state types', () {
      const initial = ExplorerPageInitial();
      const initializing = ExplorerPageInitializing();
      final ready = ExplorerPageReady(mapController: mockMapboxMap);
      const error = ExplorerPageError(message: 'error');

      expect(initial, isA<ExplorerPageInitial>());
      expect(initializing, isA<ExplorerPageInitializing>());
      expect(ready, isA<ExplorerPageReady>());
      expect(error, isA<ExplorerPageError>());

      expect(initial, isNot(isA<ExplorerPageInitializing>()));
      expect(initializing, isNot(isA<ExplorerPageReady>()));
      expect(ready, isNot(isA<ExplorerPageError>()));
      expect(error, isNot(isA<ExplorerPageInitial>()));
    });
  });

  group('ExplorerPageState flow', () {
    test('should represent typical initialization flow', () {
      // Start with initial
      const state1 = ExplorerPageInitial();
      expect(state1, isA<ExplorerPageInitial>());

      // Move to initializing
      const state2 = ExplorerPageInitializing(step: 'Démarrage GPS...');
      expect(state2, isA<ExplorerPageInitializing>());

      // Then to ready
      final state3 = ExplorerPageReady(mapController: mockMapboxMap);
      expect(state3, isA<ExplorerPageReady>());
    });

    test('should represent error flow', () {
      // Start with initial
      const state1 = ExplorerPageInitial();
      expect(state1, isA<ExplorerPageInitial>());

      // Start initializing
      const state2 = ExplorerPageInitializing();
      expect(state2, isA<ExplorerPageInitializing>());

      // Error occurs
      const state3 = ExplorerPageError(message: 'Failed');
      expect(state3, isA<ExplorerPageError>());
    });

    test('should represent ready state updates', () {
      final position1 = gl.Position(
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

      // Ready without position
      final state1 = ExplorerPageReady(mapController: mockMapboxMap);
      expect(state1.currentPosition, isNull);

      // Update with position
      final state2 = state1.copyWith(currentPosition: position1);
      expect(state2.currentPosition, isNotNull);

      // Update centered flag
      final state3 = state2.copyWith(hasCenteredOnInitialPosition: true);
      expect(state3.hasCenteredOnInitialPosition, isTrue);
    });
  });
}
