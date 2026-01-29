import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationState.dart';

void main() {
  group('HikeNavigationIdle', () {
    test('should create idle state', () {
      const state = HikeNavigationIdle();
      expect(state, isA<HikeNavigationState>());
    });

    test('should be const', () {
      const state1 = HikeNavigationIdle();
      const state2 = HikeNavigationIdle();
      expect(identical(state1, state2), isTrue);
    });
  });

  group('HikeNavigationCalculating', () {
    test('should create with start coordinates', () {
      const state = HikeNavigationCalculating(
        startLat: 48.8566,
        startLon: 2.3522,
      );

      expect(state.startLat, equals(48.8566));
      expect(state.startLon, equals(2.3522));
      expect(state, isA<HikeNavigationState>());
    });

    test('should handle negative coordinates', () {
      const state = HikeNavigationCalculating(
        startLat: -33.8688,
        startLon: 151.2093,
      );

      expect(state.startLat, equals(-33.8688));
      expect(state.startLon, equals(151.2093));
    });

    test('should handle zero coordinates', () {
      const state = HikeNavigationCalculating(
        startLat: 0.0,
        startLon: 0.0,
      );

      expect(state.startLat, equals(0.0));
      expect(state.startLon, equals(0.0));
    });
  });

  group('HikeNavigationActive', () {
    test('should create with required fields', () {
      const route = [
        [2.3522, 48.8566],
        [2.3600, 48.8600],
      ];

      const state = HikeNavigationActive(
        route: route,
        distanceToStartKm: 5.2,
        estimatedTimeMinutes: 45.0,
        startLat: 48.8566,
        startLon: 2.3522,
      );

      expect(state.route, equals(route));
      expect(state.distanceToStartKm, equals(5.2));
      expect(state.estimatedTimeMinutes, equals(45.0));
      expect(state.startLat, equals(48.8566));
      expect(state.startLon, equals(2.3522));
      expect(state.activeHikeInfo, isNull);
      expect(state.hikeRouteCoordinates, isNull);
      expect(state, isA<HikeNavigationState>());
    });

    test('should create with optional fields', () {
      const route = [
        [2.3522, 48.8566],
      ];

      final hikeInfo = {
        'name': 'Mountain Trail',
        'distance': '10.5 km',
      };

      const hikeRoute = [
        [2.3522, 48.8566],
        [2.3700, 48.8700],
      ];

      final state = HikeNavigationActive(
        route: route,
        distanceToStartKm: 2.0,
        estimatedTimeMinutes: 20.0,
        startLat: 48.8566,
        startLon: 2.3522,
        activeHikeInfo: hikeInfo,
        hikeRouteCoordinates: hikeRoute,
      );

      expect(state.activeHikeInfo, equals(hikeInfo));
      expect(state.hikeRouteCoordinates, equals(hikeRoute));
    });

    test('should handle empty route', () {
      const state = HikeNavigationActive(
        route: [],
        distanceToStartKm: 0.0,
        estimatedTimeMinutes: 0.0,
        startLat: 48.8566,
        startLon: 2.3522,
      );

      expect(state.route, isEmpty);
    });

    group('copyWith', () {
      test('should copy with new route', () {
        const originalRoute = [
          [2.3522, 48.8566],
        ];
        const newRoute = [
          [2.3600, 48.8600],
        ];

        const state = HikeNavigationActive(
          route: originalRoute,
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final newState = state.copyWith(route: newRoute);

        expect(newState.route, equals(newRoute));
        expect(newState.distanceToStartKm, equals(5.0));
        expect(newState.estimatedTimeMinutes, equals(30.0));
      });

      test('should copy with new distance', () {
        const state = HikeNavigationActive(
          route: [],
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final newState = state.copyWith(distanceToStartKm: 3.0);

        expect(newState.distanceToStartKm, equals(3.0));
        expect(newState.route, isEmpty);
      });

      test('should copy with new estimated time', () {
        const state = HikeNavigationActive(
          route: [],
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final newState = state.copyWith(estimatedTimeMinutes: 45.0);

        expect(newState.estimatedTimeMinutes, equals(45.0));
        expect(newState.distanceToStartKm, equals(5.0));
      });

      test('should copy with new start coordinates', () {
        const state = HikeNavigationActive(
          route: [],
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final newState = state.copyWith(
          startLat: 48.8600,
          startLon: 2.3600,
        );

        expect(newState.startLat, equals(48.8600));
        expect(newState.startLon, equals(2.3600));
      });

      test('should copy with new hike info', () {
        const state = HikeNavigationActive(
          route: [],
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final hikeInfo = {'name': 'Trail'};
        final newState = state.copyWith(activeHikeInfo: hikeInfo);

        expect(newState.activeHikeInfo, equals(hikeInfo));
      });

      test('should copy with new hike route coordinates', () {
        const state = HikeNavigationActive(
          route: [],
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        const hikeRoute = [
          [2.3522, 48.8566],
        ];
        final newState = state.copyWith(hikeRouteCoordinates: hikeRoute);

        expect(newState.hikeRouteCoordinates, equals(hikeRoute));
      });

      test('should keep original values when not specified', () {
        const route = [
          [2.3522, 48.8566],
        ];
        final hikeInfo = {'name': 'Trail'};
        const hikeRoute = [
          [2.3522, 48.8566],
        ];

        final state = HikeNavigationActive(
          route: route,
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
          activeHikeInfo: hikeInfo,
          hikeRouteCoordinates: hikeRoute,
        );

        final newState = state.copyWith();

        expect(newState.route, equals(route));
        expect(newState.distanceToStartKm, equals(5.0));
        expect(newState.estimatedTimeMinutes, equals(30.0));
        expect(newState.startLat, equals(48.8566));
        expect(newState.startLon, equals(2.3522));
        expect(newState.activeHikeInfo, equals(hikeInfo));
        expect(newState.hikeRouteCoordinates, equals(hikeRoute));
      });

      test('should update all fields at once', () {
        const state = HikeNavigationActive(
          route: [],
          distanceToStartKm: 5.0,
          estimatedTimeMinutes: 30.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        const newRoute = [
          [2.3600, 48.8600],
        ];
        final newHikeInfo = {'name': 'New Trail'};
        const newHikeRoute = [
          [2.3700, 48.8700],
        ];

        final newState = state.copyWith(
          route: newRoute,
          distanceToStartKm: 3.0,
          estimatedTimeMinutes: 20.0,
          startLat: 48.8600,
          startLon: 2.3600,
          activeHikeInfo: newHikeInfo,
          hikeRouteCoordinates: newHikeRoute,
        );

        expect(newState.route, equals(newRoute));
        expect(newState.distanceToStartKm, equals(3.0));
        expect(newState.estimatedTimeMinutes, equals(20.0));
        expect(newState.startLat, equals(48.8600));
        expect(newState.startLon, equals(2.3600));
        expect(newState.activeHikeInfo, equals(newHikeInfo));
        expect(newState.hikeRouteCoordinates, equals(newHikeRoute));
      });
    });
  });

  group('HikeNavigationNearStart', () {
    test('should create with required fields', () {
      const route = [
        [2.3522, 48.8566],
      ];

      const state = HikeNavigationNearStart(
        route: route,
        distanceToStartKm: 0.015, // 15 meters
        startLat: 48.8566,
        startLon: 2.3522,
      );

      expect(state.route, equals(route));
      expect(state.distanceToStartKm, equals(0.015));
      expect(state.startLat, equals(48.8566));
      expect(state.startLon, equals(2.3522));
      expect(state.activeHikeInfo, isNull);
      expect(state.hikeRouteCoordinates, isNull);
      expect(state, isA<HikeNavigationState>());
    });

    test('should create with optional fields', () {
      const route = [
        [2.3522, 48.8566],
      ];

      final hikeInfo = {'name': 'Mountain Trail'};
      const hikeRoute = [
        [2.3522, 48.8566],
      ];

      final state = HikeNavigationNearStart(
        route: route,
        distanceToStartKm: 0.018,
        startLat: 48.8566,
        startLon: 2.3522,
        activeHikeInfo: hikeInfo,
        hikeRouteCoordinates: hikeRoute,
      );

      expect(state.activeHikeInfo, equals(hikeInfo));
      expect(state.hikeRouteCoordinates, equals(hikeRoute));
    });

    test('should handle very small distance', () {
      const state = HikeNavigationNearStart(
        route: [],
        distanceToStartKm: 0.001, // 1 meter
        startLat: 48.8566,
        startLon: 2.3522,
      );

      expect(state.distanceToStartKm, equals(0.001));
    });
  });

  group('HikeNavigationError', () {
    test('should create with error message', () {
      const state = HikeNavigationError('Route calculation failed');

      expect(state.message, equals('Route calculation failed'));
      expect(state, isA<HikeNavigationState>());
    });

    test('should handle empty error message', () {
      const state = HikeNavigationError('');
      expect(state.message, isEmpty);
    });

    test('should handle detailed error message', () {
      const errorMsg = 'Network error: Unable to reach routing service';
      const state = HikeNavigationError(errorMsg);
      expect(state.message, equals(errorMsg));
    });
  });

  group('HikeNavigationState type checking', () {
    test('should distinguish between different state types', () {
      const idle = HikeNavigationIdle();
      const calculating = HikeNavigationCalculating(
        startLat: 48.8566,
        startLon: 2.3522,
      );
      const active = HikeNavigationActive(
        route: [],
        distanceToStartKm: 5.0,
        estimatedTimeMinutes: 30.0,
        startLat: 48.8566,
        startLon: 2.3522,
      );
      const nearStart = HikeNavigationNearStart(
        route: [],
        distanceToStartKm: 0.015,
        startLat: 48.8566,
        startLon: 2.3522,
      );
      const error = HikeNavigationError('error');

      expect(idle, isA<HikeNavigationIdle>());
      expect(calculating, isA<HikeNavigationCalculating>());
      expect(active, isA<HikeNavigationActive>());
      expect(nearStart, isA<HikeNavigationNearStart>());
      expect(error, isA<HikeNavigationError>());

      expect(idle, isNot(isA<HikeNavigationCalculating>()));
      expect(calculating, isNot(isA<HikeNavigationActive>()));
      expect(active, isNot(isA<HikeNavigationNearStart>()));
      expect(nearStart, isNot(isA<HikeNavigationError>()));
      expect(error, isNot(isA<HikeNavigationIdle>()));
    });
  });

  group('HikeNavigationState flow', () {
    test('should represent typical navigation flow', () {
      // Start idle
      const state1 = HikeNavigationIdle();
      expect(state1, isA<HikeNavigationIdle>());

      // Start calculating
      const state2 = HikeNavigationCalculating(
        startLat: 48.8566,
        startLon: 2.3522,
      );
      expect(state2, isA<HikeNavigationCalculating>());

      // Route calculated, navigation active
      const route = [
        [2.3522, 48.8566],
        [2.3600, 48.8600],
      ];
      const state3 = HikeNavigationActive(
        route: route,
        distanceToStartKm: 5.0,
        estimatedTimeMinutes: 30.0,
        startLat: 48.8566,
        startLon: 2.3522,
      );
      expect(state3, isA<HikeNavigationActive>());

      // Arrived near start
      const state4 = HikeNavigationNearStart(
        route: route,
        distanceToStartKm: 0.015,
        startLat: 48.8566,
        startLon: 2.3522,
      );
      expect(state4, isA<HikeNavigationNearStart>());
    });

    test('should represent error flow', () {
      // Start idle
      const state1 = HikeNavigationIdle();
      expect(state1, isA<HikeNavigationIdle>());

      // Start calculating
      const state2 = HikeNavigationCalculating(
        startLat: 48.8566,
        startLon: 2.3522,
      );
      expect(state2, isA<HikeNavigationCalculating>());

      // Error occurs
      const state3 = HikeNavigationError('Failed');
      expect(state3, isA<HikeNavigationError>());
    });

    test('should represent distance updates during navigation', () {
      const route = [
        [2.3522, 48.8566],
      ];

      // Far from start
      const state1 = HikeNavigationActive(
        route: route,
        distanceToStartKm: 10.0,
        estimatedTimeMinutes: 60.0,
        startLat: 48.8566,
        startLon: 2.3522,
      );
      expect(state1.distanceToStartKm, equals(10.0));

      // Getting closer
      final state2 = state1.copyWith(
        distanceToStartKm: 5.0,
        estimatedTimeMinutes: 30.0,
      );
      expect(state2.distanceToStartKm, equals(5.0));

      // Very close, transition to near start
      const state3 = HikeNavigationNearStart(
        route: route,
        distanceToStartKm: 0.015,
        startLat: 48.8566,
        startLon: 2.3522,
      );
      expect(state3.distanceToStartKm, lessThan(0.02)); // Less than 20m
    });
  });
}
