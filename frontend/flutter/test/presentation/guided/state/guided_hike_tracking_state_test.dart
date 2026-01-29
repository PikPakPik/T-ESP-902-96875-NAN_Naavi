import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';

gl.Position createPosition(double lat, double lon) {
  return gl.Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime.now(),
    accuracy: 10.0,
    altitude: 50.0,
    altitudeAccuracy: 5.0,
    heading: 0.0,
    headingAccuracy: 5.0,
    speed: 0.0,
    speedAccuracy: 1.0,
  );
}

void main() {
  group('GuidedHikeTrackingState', () {
    group('DirectionType', () {
      test('should have all direction types', () {
        expect(DirectionType.values, hasLength(9));
        expect(DirectionType.values, contains(DirectionType.straight));
        expect(DirectionType.values, contains(DirectionType.left));
        expect(DirectionType.values, contains(DirectionType.right));
        expect(DirectionType.values, contains(DirectionType.arrived));
      });
    });

    group('GuidedHikeTrackingIdle', () {
      test('should create idle state', () {
        const state = GuidedHikeTrackingIdle();
        expect(state, isA<GuidedHikeTrackingState>());
      });
    });

    group('GuidedHikeTrackingActive', () {
      test('should create active state with required fields', () {
        final routeCoordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        final state = GuidedHikeTrackingActive(
          routeCoordinates: routeCoordinates,
          currentWaypointIndex: 0,
          currentDirection: 'Continuez tout droit',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 150.0,
          elapsedSeconds: 300,
          distanceKm: 1.5,
        );

        expect(state.routeCoordinates, equals(routeCoordinates));
        expect(state.currentWaypointIndex, equals(0));
        expect(state.currentDirection, equals('Continuez tout droit'));
        expect(state.currentDirectionType, equals(DirectionType.straight));
        expect(state.distanceToNextWaypointMeters, equals(150.0));
        expect(state.elapsedSeconds, equals(300));
        expect(state.distanceKm, equals(1.5));
        expect(state.isPaused, isFalse);
        expect(state.hasInitialCameraOriented, isFalse);
      });

      test('should create active state with all fields', () {
        final routeCoordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        final hikeInfo = {'name': 'Test Trail', 'difficulty': 'easy'};

        final state = GuidedHikeTrackingActive(
          routeCoordinates: routeCoordinates,
          hikeInfo: hikeInfo,
          currentWaypointIndex: 1,
          currentDirection: 'Tournez à gauche',
          currentDirectionType: DirectionType.left,
          distanceToNextWaypointMeters: 50.0,
          elapsedSeconds: 600,
          distanceKm: 2.3,
          isPaused: true,
          hasInitialCameraOriented: true,
        );

        expect(state.hikeInfo, equals(hikeInfo));
        expect(state.isPaused, isTrue);
        expect(state.hasInitialCameraOriented, isTrue);
      });

      test('formattedTime should format seconds correctly', () {
        const state = GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 125, // 2 minutes 5 seconds
          distanceKm: 0,
        );

        expect(state.formattedTime, equals('2:05'));
      });

      test('formattedTime should handle zero seconds', () {
        const state = GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 0,
          distanceKm: 0,
        );

        expect(state.formattedTime, equals('0:00'));
      });

      test('formattedTime should pad seconds with zero', () {
        const state = GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 65, // 1 minute 5 seconds
          distanceKm: 0,
        );

        expect(state.formattedTime, equals('1:05'));
      });

      test('formattedDistance should format km correctly', () {
        const state = GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 0,
          distanceKm: 3.456,
        );

        expect(state.formattedDistance, equals('3.46 km'));
      });

      test('progressPercentage should calculate correctly', () {
        final routeCoordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
          [-1.5600, 47.2150],
          [-1.5550, 47.2180],
        ];

        final state = GuidedHikeTrackingActive(
          routeCoordinates: routeCoordinates,
          currentWaypointIndex: 1,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 0,
          distanceKm: 0,
        );

        // 1 / 3 * 100 = 33.33%
        expect(state.progressPercentage, closeTo(33.33, 0.01));
      });

      test('progressPercentage should return 0 for empty coordinates', () {
        const state = GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 0,
          distanceKm: 0,
        );

        expect(state.progressPercentage, equals(0.0));
      });

      test('copyWith should update specified fields', () {
        final routeCoordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        final state = GuidedHikeTrackingActive(
          routeCoordinates: routeCoordinates,
          currentWaypointIndex: 0,
          currentDirection: 'Straight',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 100,
          elapsedSeconds: 60,
          distanceKm: 1.0,
          isPaused: false,
        );

        final updated = state.copyWith(
          currentWaypointIndex: 1,
          elapsedSeconds: 120,
          isPaused: true,
        );

        expect(updated.currentWaypointIndex, equals(1));
        expect(updated.elapsedSeconds, equals(120));
        expect(updated.isPaused, isTrue);
        expect(updated.currentDirection, equals('Straight'));
        expect(updated.distanceKm, equals(1.0));
      });

      test('copyWith should keep unchanged fields', () {
        final routeCoordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        final state = GuidedHikeTrackingActive(
          routeCoordinates: routeCoordinates,
          currentWaypointIndex: 2,
          currentDirection: 'Turn left',
          currentDirectionType: DirectionType.left,
          distanceToNextWaypointMeters: 200,
          elapsedSeconds: 300,
          distanceKm: 2.5,
        );

        final updated = state.copyWith(isPaused: true);

        expect(updated.currentWaypointIndex, equals(2));
        expect(updated.currentDirection, equals('Turn left'));
        expect(updated.distanceKm, equals(2.5));
        expect(updated.isPaused, isTrue);
      });
    });

    group('GuidedHikeTrackingCompleted', () {
      test('should create completed state', () {
        final segments = [
          [createPosition(47.2173, -1.5534), createPosition(47.2200, -1.5500)],
        ];

        final state = GuidedHikeTrackingCompleted(
          segments: segments,
          elapsedSeconds: 1800,
          distanceKm: 5.2,
        );

        expect(state.segments, equals(segments));
        expect(state.elapsedSeconds, equals(1800));
        expect(state.distanceKm, equals(5.2));
        expect(state.wasManuallyFinished, isFalse);
      });

      test('should create completed state with manual finish flag', () {
        final segments = [
          [createPosition(47.2173, -1.5534)],
        ];

        final state = GuidedHikeTrackingCompleted(
          segments: segments,
          elapsedSeconds: 600,
          distanceKm: 1.5,
          wasManuallyFinished: true,
        );

        expect(state.wasManuallyFinished, isTrue);
      });

      test('formattedTime should format seconds as minutes and seconds', () {
        final state = GuidedHikeTrackingCompleted(
          segments: [],
          elapsedSeconds: 185, // 3 min 5 s
          distanceKm: 0,
        );

        expect(state.formattedTime, equals('3 min 5 s'));
      });

      test('formattedTime should handle zero seconds', () {
        final state = GuidedHikeTrackingCompleted(
          segments: [],
          elapsedSeconds: 0,
          distanceKm: 0,
        );

        expect(state.formattedTime, equals('0 min 0 s'));
      });

      test('formattedTime should handle large durations', () {
        final state = GuidedHikeTrackingCompleted(
          segments: [],
          elapsedSeconds: 7325, // 122 min 5 s
          distanceKm: 0,
        );

        expect(state.formattedTime, equals('122 min 5 s'));
      });

      test('formattedDistance should format km correctly', () {
        final state = GuidedHikeTrackingCompleted(
          segments: [],
          elapsedSeconds: 0,
          distanceKm: 12.456,
        );

        expect(state.formattedDistance, equals('12.46 km'));
      });
    });

    group('State hierarchy', () {
      test('all states should extend GuidedHikeTrackingState', () {
        const idle = GuidedHikeTrackingIdle();
        const active = GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 0,
          distanceKm: 0,
        );
        final completed = GuidedHikeTrackingCompleted(
          segments: [],
          elapsedSeconds: 0,
          distanceKm: 0,
        );

        expect(idle, isA<GuidedHikeTrackingState>());
        expect(active, isA<GuidedHikeTrackingState>());
        expect(completed, isA<GuidedHikeTrackingState>());
      });
    });
  });
}
