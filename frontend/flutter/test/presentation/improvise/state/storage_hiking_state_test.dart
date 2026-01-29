import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/improvise/state/StorageHikingState.dart';
import 'package:naavi/data/models/HikeModel.dart';

void main() {
  group('StorageHikingState', () {
    group('StorageHikingStateIdle', () {
      test('should create idle state', () {
        const state = StorageHikingStateIdle();
        expect(state, isA<StorageHikingState>());
      });

      test('should be const', () {
        const state1 = StorageHikingStateIdle();
        const state2 = StorageHikingStateIdle();
        expect(identical(state1, state2), isTrue);
      });
    });

    group('StorageHikingStateTracking', () {
      test('should create tracking state', () {
        const state = StorageHikingStateTracking();
        expect(state, isA<StorageHikingState>());
      });

      test('should be const', () {
        const state1 = StorageHikingStateTracking();
        const state2 = StorageHikingStateTracking();
        expect(identical(state1, state2), isTrue);
      });
    });

    group('StorageHikingStateLoading', () {
      test('should create loading state', () {
        const state = StorageHikingStateLoading();
        expect(state, isA<StorageHikingState>());
      });

      test('should be const', () {
        const state1 = StorageHikingStateLoading();
        const state2 = StorageHikingStateLoading();
        expect(identical(state1, state2), isTrue);
      });
    });

    group('StorageHikingStateSyncronized', () {
      test('should create syncronized state', () {
        const state = StorageHikingStateSyncronized();
        expect(state, isA<StorageHikingState>());
      });

      test('should be const', () {
        const state1 = StorageHikingStateSyncronized();
        const state2 = StorageHikingStateSyncronized();
        expect(identical(state1, state2), isTrue);
      });
    });

    group('StorageHikingStatePaused', () {
      test('should create paused state with required fields', () {
        final paths = [
          [
            PathPoint(latitude: 48.8566, longitude: 2.3522),
            PathPoint(latitude: 48.8570, longitude: 2.3530),
          ],
        ];

        final state = StorageHikingStatePaused(
          startLatitude: 48.8566,
          startLongitude: 2.3522,
          paths: paths,
        );

        expect(state, isA<StorageHikingState>());
        expect(state.startLatitude, equals(48.8566));
        expect(state.startLongitude, equals(2.3522));
        expect(state.paths, equals(paths));
      });

      test('should handle empty paths', () {
        const state = StorageHikingStatePaused(
          startLatitude: 48.8566,
          startLongitude: 2.3522,
          paths: [],
        );

        expect(state.paths, isEmpty);
      });

      test('should handle multiple paths', () {
        final paths = [
          [
            PathPoint(latitude: 48.8566, longitude: 2.3522),
            PathPoint(latitude: 48.8570, longitude: 2.3530),
          ],
          [
            PathPoint(latitude: 48.8575, longitude: 2.3535),
            PathPoint(latitude: 48.8580, longitude: 2.3540),
          ],
        ];

        final state = StorageHikingStatePaused(
          startLatitude: 48.8566,
          startLongitude: 2.3522,
          paths: paths,
        );

        expect(state.paths.length, equals(2));
      });
    });

    group('StorageHikingStateError', () {
      test('should create error state', () {
        const state = StorageHikingStateError();
        expect(state, isA<StorageHikingState>());
      });

      test('should be const', () {
        const state1 = StorageHikingStateError();
        const state2 = StorageHikingStateError();
        expect(identical(state1, state2), isTrue);
      });
    });

    group('State type checking', () {
      test('all states should extend StorageHikingState', () {
        const idle = StorageHikingStateIdle();
        const tracking = StorageHikingStateTracking();
        const loading = StorageHikingStateLoading();
        const syncronized = StorageHikingStateSyncronized();
        const paused = StorageHikingStatePaused(
          startLatitude: 0,
          startLongitude: 0,
          paths: [],
        );
        const error = StorageHikingStateError();

        expect(idle, isA<StorageHikingState>());
        expect(tracking, isA<StorageHikingState>());
        expect(loading, isA<StorageHikingState>());
        expect(syncronized, isA<StorageHikingState>());
        expect(paused, isA<StorageHikingState>());
        expect(error, isA<StorageHikingState>());
      });

      test('pattern matching works on state types', () {
        StorageHikingState state = const StorageHikingStateIdle();

        String getStateType(StorageHikingState s) {
          return switch (s) {
            StorageHikingStateIdle() => 'idle',
            StorageHikingStateTracking() => 'tracking',
            StorageHikingStateLoading() => 'loading',
            StorageHikingStateSyncronized() => 'syncronized',
            StorageHikingStatePaused() => 'paused',
            StorageHikingStateError() => 'error',
          };
        }

        expect(getStateType(state), equals('idle'));

        state = const StorageHikingStateTracking();
        expect(getStateType(state), equals('tracking'));

        state = const StorageHikingStatePaused(
          startLatitude: 0,
          startLongitude: 0,
          paths: [],
        );
        expect(getStateType(state), equals('paused'));
      });
    });
  });
}
