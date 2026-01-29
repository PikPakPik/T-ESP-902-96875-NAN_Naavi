import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/data/models/HikeModel.dart';
import 'package:naavi/domain/usecases/storeHikingUseCase.dart';
import 'package:naavi/presentation/improvise/state/StorageHikingState.dart';
import 'package:naavi/presentation/improvise/state/StorageHikingStateNotifier.dart';

// Mocks
class MockStoreHikingUseCase extends Mock implements StoreHikingUseCase {}

void main() {
  setUpAll(() {
    // Register fallback values for PathPoint list types
    registerFallbackValue(<List<PathPoint>>[]);
  });

  group('StorageHikingStateNotifier', () {
    late StorageHikingStateNotifier notifier;
    late MockStoreHikingUseCase mockStoreHikingUseCase;

    setUp(() {
      mockStoreHikingUseCase = MockStoreHikingUseCase();
      notifier = StorageHikingStateNotifier(
        storeHikingUseCase: mockStoreHikingUseCase,
      );
    });

    test('initial state should be StorageHikingStateIdle', () {
      expect(notifier.state, isA<StorageHikingStateIdle>());
    });

    group('startHike', () {
      test('should emit StorageHikingStateTracking state', () {
        notifier.startHike();

        expect(notifier.state, isA<StorageHikingStateTracking>());
      });

      test('should transition from idle to tracking', () {
        expect(notifier.state, isA<StorageHikingStateIdle>());

        notifier.startHike();

        expect(notifier.state, isA<StorageHikingStateTracking>());
      });
    });

    group('pauseHike', () {
      test('should emit StorageHikingStatePaused state', () {
        notifier.pauseHike();

        expect(notifier.state, isA<StorageHikingStatePaused>());
      });

      test('should emit paused state with zero values', () {
        notifier.pauseHike();

        final state = notifier.state as StorageHikingStatePaused;
        expect(state.startLatitude, 0);
        expect(state.startLongitude, 0);
        expect(state.paths, isEmpty);
      });

      test('should transition from tracking to paused', () {
        notifier.startHike();
        expect(notifier.state, isA<StorageHikingStateTracking>());

        notifier.pauseHike();

        expect(notifier.state, isA<StorageHikingStatePaused>());
      });
    });

    group('pausedHike', () {
      final testStartLat = 48.8566;
      final testStartLng = 2.3522;
      final testPaths = [
        [
          PathPoint(latitude: 48.8566, longitude: 2.3522),
          PathPoint(latitude: 48.8570, longitude: 2.3540),
        ],
        [
          PathPoint(latitude: 48.8575, longitude: 2.3560),
          PathPoint(latitude: 48.8580, longitude: 2.3580),
        ],
      ];

      test('should emit loading then paused state on successful save', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(
              testStartLat,
              testStartLng,
              testPaths,
            )).thenAnswer((_) async => Future.value());

        final states = <StorageHikingState>[];
        final subscription = notifier.stream.listen((state) => states.add(state));

        await notifier.pausedHike(testStartLat, testStartLng, testPaths);
        await Future.delayed(Duration.zero);

        expect(states, [
          isA<StorageHikingStateLoading>(),
          isA<StorageHikingStatePaused>(),
        ]);

        verify(() => mockStoreHikingUseCase.saveHikeLocally(
              testStartLat,
              testStartLng,
              testPaths,
            )).called(1);

        await subscription.cancel();
      });

      test('should emit loading then error state when save fails', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(
              any(),
              any(),
              any(),
            )).thenThrow(Exception('Save error'));

        final states = <StorageHikingState>[];
        final subscription = notifier.stream.listen((state) => states.add(state));

        await notifier.pausedHike(testStartLat, testStartLng, testPaths);
        await Future.delayed(Duration.zero);

        expect(states, [
          isA<StorageHikingStateLoading>(),
          isA<StorageHikingStateError>(),
        ]);

        await subscription.cancel();
      });

      test('should call saveHikeLocally with correct parameters', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(
              testStartLat,
              testStartLng,
              testPaths,
            )).thenAnswer((_) async => Future.value());

        await notifier.pausedHike(testStartLat, testStartLng, testPaths);

        verify(() => mockStoreHikingUseCase.saveHikeLocally(
              testStartLat,
              testStartLng,
              testPaths,
            )).called(1);
      });

      test('should handle empty paths list', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => Future.value());

        await notifier.pausedHike(testStartLat, testStartLng, []);

        expect(notifier.state, isA<StorageHikingStatePaused>());
      });

      test('should handle negative coordinates', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => Future.value());

        await notifier.pausedHike(-48.8566, -2.3522, testPaths);

        expect(notifier.state, isA<StorageHikingStatePaused>());
        verify(() => mockStoreHikingUseCase.saveHikeLocally(
              -48.8566,
              -2.3522,
              testPaths,
            )).called(1);
      });

      test('paused state should reset coordinates to zero', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => Future.value());

        await notifier.pausedHike(testStartLat, testStartLng, testPaths);

        final state = notifier.state as StorageHikingStatePaused;
        expect(state.startLatitude, 0);
        expect(state.startLongitude, 0);
        expect(state.paths, isEmpty);
      });
    });

    group('finishedHike', () {
      final testEndLat = 48.8580;
      final testEndLng = 2.3580;
      final testPaths = [
        [
          PathPoint(latitude: 48.8566, longitude: 2.3522),
          PathPoint(latitude: 48.8570, longitude: 2.3540),
        ],
        [
          PathPoint(latitude: 48.8575, longitude: 2.3560),
          PathPoint(latitude: 48.8580, longitude: 2.3580),
        ],
      ];

      test('should emit loading state on successful finish', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(testPaths))
            .thenAnswer((_) async => Future.value());

        final states = <StorageHikingState>[];
        final subscription = notifier.stream.listen((state) => states.add(state));

        await notifier.finishedHike(testEndLat, testEndLng, testPaths);
        await Future.delayed(Duration.zero);

        expect(states.first, isA<StorageHikingStateLoading>());

        verify(() => mockStoreHikingUseCase.saveCompletedHike(testPaths)).called(1);

        await subscription.cancel();
      });

      test('should emit loading then error state when save fails', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(Exception('Finish error'));

        final states = <StorageHikingState>[];
        final subscription = notifier.stream.listen((state) => states.add(state));

        await notifier.finishedHike(testEndLat, testEndLng, testPaths);
        await Future.delayed(Duration.zero);

        expect(states, [
          isA<StorageHikingStateLoading>(),
          isA<StorageHikingStateError>(),
        ]);

        await subscription.cancel();
      });

      test('should call saveCompletedHike with correct parameters', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(testPaths))
            .thenAnswer((_) async => Future.value());

        await notifier.finishedHike(testEndLat, testEndLng, testPaths);

        verify(() => mockStoreHikingUseCase.saveCompletedHike(testPaths)).called(1);
      });

      test('should handle empty paths list', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenAnswer((_) async => Future.value());

        await notifier.finishedHike(testEndLat, testEndLng, []);

        expect(notifier.state, isA<StorageHikingStateLoading>());
      });

      test('should handle multiple segments in paths', () async {
        final largePaths = List.generate(
          10,
          (i) => [
            PathPoint(latitude: 48.8566 + i * 0.001, longitude: 2.3522 + i * 0.001),
            PathPoint(latitude: 48.8570 + i * 0.001, longitude: 2.3540 + i * 0.001),
          ],
        );

        when(() => mockStoreHikingUseCase.saveCompletedHike(largePaths))
            .thenAnswer((_) async => Future.value());

        await notifier.finishedHike(testEndLat, testEndLng, largePaths);

        verify(() => mockStoreHikingUseCase.saveCompletedHike(largePaths)).called(1);
      });

      test('should not use end point coordinates in saveCompletedHike call', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(testPaths))
            .thenAnswer((_) async => Future.value());

        await notifier.finishedHike(testEndLat, testEndLng, testPaths);

        // Verify only paths are passed, not end coordinates
        verify(() => mockStoreHikingUseCase.saveCompletedHike(testPaths)).called(1);
        verifyNever(() => mockStoreHikingUseCase.saveCompletedHike(any()));
      });
    });

    group('syncronizeHike', () {
      test('should complete without error', () async {
        // Currently empty implementation, should not throw
        expect(() => notifier.syncronizeHike(), returnsNormally);
      });

      test('should not change state', () async {
        final initialState = notifier.state;

        await notifier.syncronizeHike();

        expect(notifier.state, equals(initialState));
      });
    });

    group('State Transitions', () {
      test('should transition from idle to tracking to paused', () {
        expect(notifier.state, isA<StorageHikingStateIdle>());

        notifier.startHike();
        expect(notifier.state, isA<StorageHikingStateTracking>());

        notifier.pauseHike();
        expect(notifier.state, isA<StorageHikingStatePaused>());
      });

      test('should transition from idle to tracking to loading to error', () async {
        expect(notifier.state, isA<StorageHikingStateIdle>());

        notifier.startHike();
        expect(notifier.state, isA<StorageHikingStateTracking>());

        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(Exception('Error'));

        await notifier.finishedHike(0, 0, []);
        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should allow restarting after error', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(Exception('Error'));

        await notifier.finishedHike(0, 0, []);
        expect(notifier.state, isA<StorageHikingStateError>());

        notifier.startHike();
        expect(notifier.state, isA<StorageHikingStateTracking>());
      });

      test('should allow restarting after paused', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenAnswer((_) async => Future.value());

        await notifier.pausedHike(0, 0, []);
        expect(notifier.state, isA<StorageHikingStatePaused>());

        notifier.startHike();
        expect(notifier.state, isA<StorageHikingStateTracking>());
      });

      test('should handle multiple pause operations', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenAnswer((_) async => Future.value());

        notifier.startHike();

        await notifier.pausedHike(0, 0, []);
        expect(notifier.state, isA<StorageHikingStatePaused>());

        notifier.startHike();

        await notifier.pausedHike(0, 0, []);
        expect(notifier.state, isA<StorageHikingStatePaused>());
      });
    });

    group('Error Handling', () {
      test('should handle network error in pausedHike', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenThrow(Exception('Network error'));

        await notifier.pausedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should handle database error in pausedHike', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenThrow(Exception('Database error'));

        await notifier.pausedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should handle generic error in pausedHike', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenThrow(Exception('Unknown error'));

        await notifier.pausedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should handle network error in finishedHike', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(Exception('Network error'));

        await notifier.finishedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should handle database error in finishedHike', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(Exception('Database error'));

        await notifier.finishedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should handle generic error in finishedHike', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(Exception('Unknown error'));

        await notifier.finishedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should catch and handle TypeError', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenThrow(TypeError());

        await notifier.pausedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should catch and handle FormatException', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(const FormatException('Invalid format'));

        await notifier.finishedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent pausedHike calls', () async {
        var callCount = 0;
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Start two concurrent calls
        final future1 = notifier.pausedHike(0, 0, []);
        final future2 = notifier.pausedHike(0, 0, []);

        await Future.wait([future1, future2]);

        // Both should complete
        expect(notifier.state, isA<StorageHikingStatePaused>());
        expect(callCount, 2);
      });

      test('should handle concurrent finishedHike calls', () async {
        var callCount = 0;
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Start two concurrent calls
        final future1 = notifier.finishedHike(0, 0, []);
        final future2 = notifier.finishedHike(0, 0, []);

        await Future.wait([future1, future2]);

        expect(callCount, 2);
      });

      test('should handle pausedHike called during finishedHike', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Start finishedHike
        final future1 = notifier.finishedHike(0, 0, []);

        // Immediately start pausedHike
        await Future.delayed(const Duration(milliseconds: 10));
        final future2 = notifier.pausedHike(0, 0, []);

        await Future.wait([future1, future2]);

        // Last operation should win (pausedHike)
        expect(notifier.state, isA<StorageHikingStatePaused>());
      });
    });

    group('Edge Cases', () {
      test('should handle very long paths list', () async {
        final largePaths = List.generate(
          1000,
          (i) => List.generate(
            100,
            (j) => PathPoint(
              latitude: 48.8566 + (i + j) * 0.0001,
              longitude: 2.3522 + (i + j) * 0.0001,
            ),
          ),
        );

        when(() => mockStoreHikingUseCase.saveCompletedHike(largePaths))
            .thenAnswer((_) async => Future.value());

        await notifier.finishedHike(0, 0, largePaths);

        verify(() => mockStoreHikingUseCase.saveCompletedHike(largePaths)).called(1);
      });

      test('should handle extreme coordinate values', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenAnswer((_) async => Future.value());

        await notifier.pausedHike(90.0, 180.0, []);

        verify(() => mockStoreHikingUseCase.saveHikeLocally(90.0, 180.0, [])).called(1);
      });

      test('should handle single point path', () async {
        final singlePointPath = [
          [PathPoint(latitude: 48.8566, longitude: 2.3522)],
        ];

        when(() => mockStoreHikingUseCase.saveCompletedHike(singlePointPath))
            .thenAnswer((_) async => Future.value());

        await notifier.finishedHike(0, 0, singlePointPath);

        verify(() => mockStoreHikingUseCase.saveCompletedHike(singlePointPath))
            .called(1);
      });

      test('should handle zero coordinates', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenAnswer((_) async => Future.value());

        await notifier.pausedHike(0.0, 0.0, []);

        verify(() => mockStoreHikingUseCase.saveHikeLocally(0.0, 0.0, [])).called(1);
        expect(notifier.state, isA<StorageHikingStatePaused>());
      });
    });

    group('State Persistence', () {
      test('should maintain error state until new action', () async {
        when(() => mockStoreHikingUseCase.saveCompletedHike(any()))
            .thenThrow(Exception('Error'));

        await notifier.finishedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStateError>());

        // Wait and verify state persists
        await Future.delayed(const Duration(milliseconds: 100));
        expect(notifier.state, isA<StorageHikingStateError>());
      });

      test('should maintain paused state until new action', () async {
        when(() => mockStoreHikingUseCase.saveHikeLocally(any(), any(), any()))
            .thenAnswer((_) async => Future.value());

        await notifier.pausedHike(0, 0, []);

        expect(notifier.state, isA<StorageHikingStatePaused>());

        // Wait and verify state persists
        await Future.delayed(const Duration(milliseconds: 100));
        expect(notifier.state, isA<StorageHikingStatePaused>());
      });

      test('should maintain tracking state until new action', () {
        notifier.startHike();

        expect(notifier.state, isA<StorageHikingStateTracking>());

        // State should persist
        expect(notifier.state, isA<StorageHikingStateTracking>());
      });
    });
  });
}
