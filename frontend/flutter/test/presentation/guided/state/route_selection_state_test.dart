import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/presentation/guided/state/RouteSelectionState.dart';

void main() {
  group('RouteSelectionLoading', () {
    test('should create loading state', () {
      const state = RouteSelectionLoading();
      expect(state, isA<RouteSelectionState>());
    });

    test('should be const', () {
      const state1 = RouteSelectionLoading();
      const state2 = RouteSelectionLoading();
      expect(identical(state1, state2), isTrue);
    });
  });

  group('RouteSelectionLoaded', () {
    test('should create with empty routes', () {
      const state = RouteSelectionLoaded(
        routes: [],
        wkbStrings: [],
        routeNames: [],
      );

      expect(state.routes, isEmpty);
      expect(state.wkbStrings, isEmpty);
      expect(state.routeNames, isEmpty);
      expect(state.routeCount, equals(0));
      expect(state, isA<RouteSelectionState>());
    });

    test('should create with routes', () {
      final routes = [
        {'id': 1, 'name': 'Route 1'},
        {'id': 2, 'name': 'Route 2'},
      ];

      final state = RouteSelectionLoaded(
        routes: routes,
        wkbStrings: ['wkb1', 'wkb2'],
        routeNames: ['Route 1', 'Route 2'],
      );

      expect(state.routes.length, equals(2));
      expect(state.wkbStrings.length, equals(2));
      expect(state.routeNames.length, equals(2));
      expect(state.routeCount, equals(2));
    });

    test('routeCount should return correct count', () {
      final routes = List.generate(5, (i) => {'id': i});

      final state = RouteSelectionLoaded(
        routes: routes,
        wkbStrings: List.generate(5, (i) => 'wkb$i'),
        routeNames: List.generate(5, (i) => 'Route $i'),
      );

      expect(state.routeCount, equals(5));
    });
  });

  group('RouteSelectionSelected', () {
    test('should create with selected hike', () {
      final selectedHike = {
        'id': 1,
        'name': 'Mountain Trail',
        'start_point': {
          'latitude': 48.8566,
          'longitude': 2.3522,
        },
      };

      final state = RouteSelectionSelected(
        selectedHikeInfo: selectedHike,
        allRoutes: [selectedHike],
        wkbStrings: ['wkb1'],
        routeNames: ['Mountain Trail'],
      );

      expect(state.selectedHikeInfo, equals(selectedHike));
      expect(state.allRoutes.length, equals(1));
      expect(state, isA<RouteSelectionState>());
    });

    test('calculateDistanceToStart should return null when no current position', () {
      final state = RouteSelectionSelected(
        selectedHikeInfo: {
          'start_point': {
            'latitude': 48.8566,
            'longitude': 2.3522,
          },
        },
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );

      final distance = state.calculateDistanceToStart(null);
      expect(distance, isNull);
    });

    test('calculateDistanceToStart should return null when no start point', () {
      final state = RouteSelectionSelected(
        selectedHikeInfo: {},
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );

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

      final distance = state.calculateDistanceToStart(position);
      expect(distance, isNull);
    });

    test('calculateDistanceToStart should return null when start point incomplete', () {
      final state = RouteSelectionSelected(
        selectedHikeInfo: {
          'start_point': {
            'latitude': 48.8566,
            // Missing longitude
          },
        },
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );

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

      final distance = state.calculateDistanceToStart(position);
      expect(distance, isNull);
    });

    test('calculateDistanceToStart should calculate distance correctly', () {
      final state = RouteSelectionSelected(
        selectedHikeInfo: {
          'start_point': {
            'latitude': 48.8566,
            'longitude': 2.3522,
          },
        },
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );

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

      final distance = state.calculateDistanceToStart(position);
      expect(distance, isNotNull);
      expect(distance, closeTo(0.0, 0.001)); // Same position = 0 km
    });

    test('calculateDistanceToStart should calculate non-zero distance', () {
      final state = RouteSelectionSelected(
        selectedHikeInfo: {
          'start_point': {
            'latitude': 48.8600, // Slightly different
            'longitude': 2.3600,
          },
        },
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );

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

      final distance = state.calculateDistanceToStart(position);
      expect(distance, isNotNull);
      expect(distance! > 0, isTrue);
      expect(distance, lessThan(1.0)); // Should be less than 1 km for nearby points
    });

    test('calculateDistanceToStart should calculate large distance', () {
      final state = RouteSelectionSelected(
        selectedHikeInfo: {
          'start_point': {
            'latitude': 40.7128, // New York
            'longitude': -74.0060,
          },
        },
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );

      final position = gl.Position(
        latitude: 48.8566, // Paris
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

      final distance = state.calculateDistanceToStart(position);
      expect(distance, isNotNull);
      expect(distance! > 5000, isTrue); // Paris to NY is ~5800 km
      expect(distance, lessThan(6500));
    });

    test('calculateDistanceToStart should handle negative coordinates', () {
      final state = RouteSelectionSelected(
        selectedHikeInfo: {
          'start_point': {
            'latitude': -33.8688, // Sydney
            'longitude': 151.2093,
          },
        },
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );

      final position = gl.Position(
        latitude: 48.8566, // Paris
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

      final distance = state.calculateDistanceToStart(position);
      expect(distance, isNotNull);
      expect(distance! > 15000, isTrue); // Paris to Sydney is ~17000 km
    });
  });

  group('RouteSelectionError', () {
    test('should create with error message', () {
      const state = RouteSelectionError('Failed to load routes');

      expect(state.message, equals('Failed to load routes'));
      expect(state, isA<RouteSelectionState>());
    });

    test('should handle empty error message', () {
      const state = RouteSelectionError('');
      expect(state.message, isEmpty);
    });

    test('should handle detailed error message', () {
      const errorMsg = 'Network error: Connection timeout after 30s';
      const state = RouteSelectionError(errorMsg);
      expect(state.message, equals(errorMsg));
    });
  });

  group('RouteSelectionState type checking', () {
    test('should distinguish between different state types', () {
      const loading = RouteSelectionLoading();
      const loaded = RouteSelectionLoaded(
        routes: [],
        wkbStrings: [],
        routeNames: [],
      );
      const selected = RouteSelectionSelected(
        selectedHikeInfo: {},
        allRoutes: [],
        wkbStrings: [],
        routeNames: [],
      );
      const error = RouteSelectionError('error');

      expect(loading, isA<RouteSelectionLoading>());
      expect(loaded, isA<RouteSelectionLoaded>());
      expect(selected, isA<RouteSelectionSelected>());
      expect(error, isA<RouteSelectionError>());

      expect(loading, isNot(isA<RouteSelectionLoaded>()));
      expect(loaded, isNot(isA<RouteSelectionSelected>()));
      expect(selected, isNot(isA<RouteSelectionError>()));
      expect(error, isNot(isA<RouteSelectionLoading>()));
    });
  });

  group('RouteSelectionState flow', () {
    test('should represent typical route selection flow', () {
      // Start loading
      const state1 = RouteSelectionLoading();
      expect(state1, isA<RouteSelectionLoading>());

      // Routes loaded
      final routes = [
        {'id': 1, 'name': 'Route 1'},
      ];
      final state2 = RouteSelectionLoaded(
        routes: routes,
        wkbStrings: ['wkb1'],
        routeNames: ['Route 1'],
      );
      expect(state2, isA<RouteSelectionLoaded>());

      // Route selected
      final state3 = RouteSelectionSelected(
        selectedHikeInfo: routes[0],
        allRoutes: routes,
        wkbStrings: ['wkb1'],
        routeNames: ['Route 1'],
      );
      expect(state3, isA<RouteSelectionSelected>());
    });

    test('should represent error flow', () {
      // Start loading
      const state1 = RouteSelectionLoading();
      expect(state1, isA<RouteSelectionLoading>());

      // Error occurs
      const state2 = RouteSelectionError('Failed');
      expect(state2, isA<RouteSelectionError>());
    });
  });
}
