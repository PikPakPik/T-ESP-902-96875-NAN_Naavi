import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingStateNotifier.dart';

// Mocks
class MockRef extends Mock implements Ref {}

class MockLocationStateNotifier extends Mock {
  gl.Position? get currentPosition => _currentPosition;
  gl.Position? _currentPosition;
  void setPosition(gl.Position? position) => _currentPosition = position;
}

class MockCameraModeManager extends Mock {
  bool get isFirstPersonMode => _isFirstPersonMode;
  bool _isFirstPersonMode = false;

  Future<void> enableFirstPersonMode(gl.Position position) async {
    _isFirstPersonMode = true;
  }

  Future<void> disableFirstPersonMode() async {
    _isFirstPersonMode = false;
  }

  Future<void> updateCamera(gl.Position position) async {}
}

// Fake for ProviderListenable
class FakeProviderListenable extends Fake
    implements ProviderListenable<Object?> {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      gl.Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    registerFallbackValue(FakeProviderListenable());
  });

  group('GuidedHikeTrackingStateNotifier', () {
    late GuidedHikeTrackingStateNotifier notifier;
    late MockRef mockRef;
    late MockLocationStateNotifier mockLocationState;

    setUp(() {
      mockRef = MockRef();
      mockLocationState = MockLocationStateNotifier();

      // Set up default mock behavior
      mockLocationState.setPosition(
        gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      );

      when(() => mockRef.read(any())).thenReturn(mockLocationState);

      notifier = GuidedHikeTrackingStateNotifier(mockRef);
    });

    tearDown(() {
      if (notifier.mounted) {
        notifier.dispose();
      }
    });

    test('initial state should be GuidedHikeTrackingIdle', () {
      expect(notifier.state, isA<GuidedHikeTrackingIdle>());
    });

    group('startTracking', () {
      test('should not start tracking with empty route coordinates', () {
        notifier.startTracking(routeCoordinates: [], hikeInfo: null);
        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });

      test(
        'should emit GuidedHikeTrackingActive state on successful start',
        () async {
          final routeCoordinates = [
            [2.3522, 48.8566], // lon, lat (Paris)
            [2.3540, 48.8570],
            [2.3560, 48.8575],
          ];
          final hikeInfo = {'name': 'Test Hike', 'difficulty': 'easy'};

          notifier.startTracking(
            routeCoordinates: routeCoordinates,
            hikeInfo: hikeInfo,
          );

          await Future.delayed(Duration.zero);

          expect(notifier.state, isA<GuidedHikeTrackingActive>());
          final state = notifier.state as GuidedHikeTrackingActive;
          expect(state.routeCoordinates, routeCoordinates);
          expect(state.hikeInfo, hikeInfo);
          expect(state.currentWaypointIndex, 0);
          expect(state.elapsedSeconds, 0);
          expect(state.distanceKm, 0.0);
          expect(state.isPaused, false);
          expect(state.hasInitialCameraOriented, false);
        },
      );

      test('should calculate initial direction correctly', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        expect(notifier.state, isA<GuidedHikeTrackingActive>());
        final state = notifier.state as GuidedHikeTrackingActive;
        expect(state.currentDirection, isNotEmpty);
        expect(state.currentDirectionType, isA<DirectionType>());
        expect(state.distanceToNextWaypointMeters, greaterThan(0));
      });

      test('should start timer after starting tracking', () async {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final initialState = notifier.state as GuidedHikeTrackingActive;
        expect(initialState.elapsedSeconds, 0);

        // Wait for timer to tick
        await Future.delayed(const Duration(milliseconds: 1100));

        final updatedState = notifier.state as GuidedHikeTrackingActive;
        expect(updatedState.elapsedSeconds, greaterThanOrEqualTo(1));
      });
    });

    group('updatePosition', () {
      test('should do nothing if state is not GuidedHikeTrackingActive', () {
        final position = gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        notifier.updatePosition(position);
        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });

      test('should update distance to next waypoint when position changes', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
          [2.3560, 48.8575],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final initialState = notifier.state as GuidedHikeTrackingActive;
        final initialDistance = initialState.distanceToNextWaypointMeters;

        // Update with a position closer to the next waypoint
        final newPosition = gl.Position(
          latitude: 48.8567,
          longitude: 2.3530,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        notifier.updatePosition(newPosition);

        final updatedState = notifier.state as GuidedHikeTrackingActive;
        expect(
          updatedState.distanceToNextWaypointMeters,
          isNot(equals(initialDistance)),
        );
      });

      test('should advance waypoint index when reaching next waypoint', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
          [2.3560, 48.8575],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        expect(
          (notifier.state as GuidedHikeTrackingActive).currentWaypointIndex,
          0,
        );

        // Update position to be very close to second waypoint
        final newPosition = gl.Position(
          latitude: 48.8570,
          longitude: 2.3540,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        notifier.updatePosition(newPosition);

        final state = notifier.state as GuidedHikeTrackingActive;
        expect(state.currentWaypointIndex, greaterThan(0));
      });

      test('should update distance traveled when advancing waypoints', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
          [2.3560, 48.8575],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final initialState = notifier.state as GuidedHikeTrackingActive;
        expect(initialState.distanceKm, 0.0);

        // Move to second waypoint
        final newPosition = gl.Position(
          latitude: 48.8570,
          longitude: 2.3540,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        notifier.updatePosition(newPosition);

        final updatedState = notifier.state as GuidedHikeTrackingActive;
        expect(updatedState.distanceKm, greaterThan(0.0));
      });

      test('should call stopTracking when reaching final waypoint', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        // Move to very close to final waypoint (within 30m)
        final finalPosition = gl.Position(
          latitude: 48.8570,
          longitude: 2.3540,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        notifier.updatePosition(finalPosition);

        expect(notifier.state, isA<GuidedHikeTrackingCompleted>());
      });
    });

    group('pause and resume', () {
      test('pause should set isPaused to true', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.pause();

        expect(notifier.state, isA<GuidedHikeTrackingActive>());
        final state = notifier.state as GuidedHikeTrackingActive;
        expect(state.isPaused, true);
      });

      test('pause should do nothing if state is not active', () {
        notifier.pause();
        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });

      test('pause should do nothing if already paused', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.pause();

        final pausedState = notifier.state as GuidedHikeTrackingActive;
        notifier.pause(); // Pause again

        expect(notifier.state, equals(pausedState));
      });

      test('resume should set isPaused to false', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.pause();
        notifier.resume();

        expect(notifier.state, isA<GuidedHikeTrackingActive>());
        final state = notifier.state as GuidedHikeTrackingActive;
        expect(state.isPaused, false);
      });

      test('resume should do nothing if state is not active', () {
        notifier.resume();
        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });

      test('timer should not increment elapsed time when paused', () async {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        // Wait for timer to tick once
        await Future.delayed(const Duration(milliseconds: 1100));

        notifier.pause();
        final pausedTime =
            (notifier.state as GuidedHikeTrackingActive).elapsedSeconds;

        // Wait while paused
        await Future.delayed(const Duration(milliseconds: 1100));

        final stillPausedTime =
            (notifier.state as GuidedHikeTrackingActive).elapsedSeconds;
        expect(stillPausedTime, equals(pausedTime));
      });

      test('timer should resume incrementing after resume', () async {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        await Future.delayed(const Duration(milliseconds: 1100));
        notifier.pause();

        final pausedTime =
            (notifier.state as GuidedHikeTrackingActive).elapsedSeconds;

        notifier.resume();

        await Future.delayed(const Duration(milliseconds: 1100));

        final resumedTime =
            (notifier.state as GuidedHikeTrackingActive).elapsedSeconds;
        expect(resumedTime, greaterThan(pausedTime));
      });
    });

    group('stopTracking', () {
      test('should do nothing if state is not active', () {
        notifier.stopTracking(completed: false);
        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });

      test('should emit GuidedHikeTrackingCompleted state on stop', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
          [2.3560, 48.8575],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.stopTracking(completed: false);

        expect(notifier.state, isA<GuidedHikeTrackingCompleted>());
      });

      test('should set wasManuallyFinished to true when completed=false', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.stopTracking(completed: false);

        final state = notifier.state as GuidedHikeTrackingCompleted;
        expect(state.wasManuallyFinished, true);
      });

      test('should set wasManuallyFinished to false when completed=true', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.stopTracking(completed: true);

        final state = notifier.state as GuidedHikeTrackingCompleted;
        expect(state.wasManuallyFinished, false);
      });

      test(
        'should preserve elapsed time and distance in completed state',
        () async {
          final routeCoordinates = [
            [2.3522, 48.8566],
            [2.3540, 48.8570],
          ];

          notifier.startTracking(routeCoordinates: routeCoordinates);

          // Wait for some time to elapse
          await Future.delayed(const Duration(milliseconds: 1100));

          final activeState = notifier.state as GuidedHikeTrackingActive;

          notifier.stopTracking(completed: true);

          final completedState = notifier.state as GuidedHikeTrackingCompleted;
          expect(completedState.elapsedSeconds, activeState.elapsedSeconds);
          expect(completedState.distanceKm, activeState.distanceKm);
        },
      );

      test('should create segments from traveled route', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
          [2.3560, 48.8575],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        // Simulate traveling to second waypoint
        final newPosition = gl.Position(
          latitude: 48.8570,
          longitude: 2.3540,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        notifier.updatePosition(newPosition);

        notifier.stopTracking(completed: false);

        final state = notifier.state as GuidedHikeTrackingCompleted;
        expect(state.segments, isNotEmpty);
        expect(state.segments.first, isNotEmpty);
      });

      test('should create empty segments when no waypoints traveled', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.stopTracking(completed: false);

        final state = notifier.state as GuidedHikeTrackingCompleted;
        expect(state.segments, isEmpty);
      });
    });

    group('markCameraOriented', () {
      test('should set hasInitialCameraOriented to true', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final initialState = notifier.state as GuidedHikeTrackingActive;
        expect(initialState.hasInitialCameraOriented, false);

        notifier.markCameraOriented();

        final updatedState = notifier.state as GuidedHikeTrackingActive;
        expect(updatedState.hasInitialCameraOriented, true);
      });

      test('should do nothing if state is not active', () {
        notifier.markCameraOriented();
        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });

      test('should do nothing if already marked as oriented', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.markCameraOriented();

        final markedState = notifier.state as GuidedHikeTrackingActive;
        notifier.markCameraOriented(); // Mark again

        expect(notifier.state, equals(markedState));
      });
    });

    group('reset', () {
      test('should reset state to GuidedHikeTrackingIdle', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.stopTracking(completed: true);

        expect(notifier.state, isA<GuidedHikeTrackingCompleted>());

        notifier.reset();

        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });
    });

    group('isActive and isCompleted getters', () {
      test(
        'isActive should return true when state is GuidedHikeTrackingActive',
        () {
          final routeCoordinates = [
            [2.3522, 48.8566],
            [2.3540, 48.8570],
          ];

          expect(notifier.isActive, false);

          notifier.startTracking(routeCoordinates: routeCoordinates);

          expect(notifier.isActive, true);
        },
      );

      test(
        'isCompleted should return true when state is GuidedHikeTrackingCompleted',
        () {
          final routeCoordinates = [
            [2.3522, 48.8566],
            [2.3540, 48.8570],
          ];

          expect(notifier.isCompleted, false);

          notifier.startTracking(routeCoordinates: routeCoordinates);
          notifier.stopTracking(completed: true);

          expect(notifier.isCompleted, true);
        },
      );

      test('isActive should return false after stopping', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        expect(notifier.isActive, true);

        notifier.stopTracking(completed: true);

        expect(notifier.isActive, false);
      });
    });

    group('State Transitions', () {
      test('should transition from idle to active to completed', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        expect(notifier.state, isA<GuidedHikeTrackingIdle>());

        notifier.startTracking(routeCoordinates: routeCoordinates);

        expect(notifier.state, isA<GuidedHikeTrackingActive>());

        notifier.stopTracking(completed: true);

        expect(notifier.state, isA<GuidedHikeTrackingCompleted>());
      });

      test('should transition from completed back to idle on reset', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);
        notifier.stopTracking(completed: true);

        expect(notifier.state, isA<GuidedHikeTrackingCompleted>());

        notifier.reset();

        expect(notifier.state, isA<GuidedHikeTrackingIdle>());
      });

      test('should allow starting new tracking after reset', () {
        final routeCoordinates1 = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        final routeCoordinates2 = [
          [2.2945, 48.8584],
          [2.2960, 48.8590],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates1);
        notifier.stopTracking(completed: true);
        notifier.reset();

        notifier.startTracking(routeCoordinates: routeCoordinates2);

        expect(notifier.state, isA<GuidedHikeTrackingActive>());
        final state = notifier.state as GuidedHikeTrackingActive;
        expect(state.routeCoordinates, routeCoordinates2);
      });
    });

    group('Direction Calculation', () {
      test('should return arrived direction for last waypoint', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final state = notifier.state as GuidedHikeTrackingActive;
        expect(state.currentDirection, 'Vous êtes arrivé !');
        expect(state.currentDirectionType, DirectionType.arrived);
        expect(state.distanceToNextWaypointMeters, 0.0);
      });

      test('should update direction when advancing to next waypoint', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
          [2.3560, 48.8575],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        // Move to next waypoint
        final newPosition = gl.Position(
          latitude: 48.8570,
          longitude: 2.3540,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 100.0,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        notifier.updatePosition(newPosition);

        final updatedState = notifier.state as GuidedHikeTrackingActive;
        // Direction may change or stay the same depending on the route geometry
        expect(updatedState.currentDirection, isNotEmpty);
      });
    });

    group('Error Handling', () {
      test(
        'should handle null current position gracefully in startTracking',
        () async {
          mockLocationState.setPosition(null);

          final routeCoordinates = [
            [2.3522, 48.8566],
            [2.3540, 48.8570],
          ];

          // Should not throw
          expect(
            () => notifier.startTracking(routeCoordinates: routeCoordinates),
            returnsNormally,
          );

          expect(notifier.state, isA<GuidedHikeTrackingActive>());
        },
      );

      test('should handle dispose when timer is active', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        // Should not throw
        expect(() => notifier.dispose(), returnsNormally);
      });

      test('should handle dispose when no timer is active', () {
        // Should not throw
        expect(() => notifier.dispose(), returnsNormally);
      });
    });

    group('GuidedHikeTrackingActive State', () {
      test('formattedTime should format time correctly', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final state = notifier.state as GuidedHikeTrackingActive;
        final updatedState = state.copyWith(elapsedSeconds: 125);

        notifier.state = updatedState;

        final finalState = notifier.state as GuidedHikeTrackingActive;
        expect(finalState.formattedTime, '2:05');
      });

      test('formattedDistance should format distance correctly', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final state = notifier.state as GuidedHikeTrackingActive;
        final updatedState = state.copyWith(distanceKm: 3.456);

        notifier.state = updatedState;

        final finalState = notifier.state as GuidedHikeTrackingActive;
        expect(finalState.formattedDistance, '3.46 km');
      });

      test('progressPercentage should calculate correctly', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
          [2.3560, 48.8575],
          [2.3580, 48.8580],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final state = notifier.state as GuidedHikeTrackingActive;

        // At waypoint 0 of 3 (indices 0-3)
        expect(state.progressPercentage, 0.0);

        // At waypoint 1 of 3
        final updatedState = state.copyWith(currentWaypointIndex: 1);
        notifier.state = updatedState;

        final finalState = notifier.state as GuidedHikeTrackingActive;
        expect(finalState.progressPercentage, closeTo(33.33, 0.1));
      });

      test('progressPercentage should handle empty route', () {
        final emptyState = const GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 0,
          distanceKm: 0,
        );

        expect(emptyState.progressPercentage, 0.0);
      });
    });

    group('GuidedHikeTrackingCompleted State', () {
      test('formattedTime should format time correctly', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final state = notifier.state as GuidedHikeTrackingActive;
        final updatedState = state.copyWith(elapsedSeconds: 125);
        notifier.state = updatedState;

        notifier.stopTracking(completed: true);

        final completedState = notifier.state as GuidedHikeTrackingCompleted;
        expect(completedState.formattedTime, '2 min 5 s');
      });

      test('formattedDistance should format distance correctly', () {
        final routeCoordinates = [
          [2.3522, 48.8566],
          [2.3540, 48.8570],
        ];

        notifier.startTracking(routeCoordinates: routeCoordinates);

        final state = notifier.state as GuidedHikeTrackingActive;
        final updatedState = state.copyWith(distanceKm: 5.678);
        notifier.state = updatedState;

        notifier.stopTracking(completed: true);

        final completedState = notifier.state as GuidedHikeTrackingCompleted;
        expect(completedState.formattedDistance, '5.68 km');
      });
    });
  });
}
