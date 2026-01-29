import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/data/models/improvise_hike.dart';
import 'package:naavi/domain/usecases/finishImproviseUseCase.dart';
import 'package:naavi/presentation/common/recap/RecapHikeState.dart';
import 'package:naavi/presentation/common/recap/RecapHikeStateNotifier.dart';

class MockFinishImproviseUseCase extends Mock implements FinishImproviseUseCase {}

void main() {
  late RecapHikeStateNotifier notifier;
  late MockFinishImproviseUseCase mockFinishImproviseUseCase;

  setUp(() {
    mockFinishImproviseUseCase = MockFinishImproviseUseCase();
    notifier = RecapHikeStateNotifier(finishImproviseUseCase: mockFinishImproviseUseCase);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('RecapHikeStateNotifier - Initial State', () {
    test('should start with RecapHikeStateLoading', () {
      expect(notifier.state, isA<RecapHikeStateLoading>());
    });
  });

  group('RecapHikeStateNotifier - Get Final Hike', () {
    test('should fetch hike successfully', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      final expectedHike = ImproviseHike(
        distance: '5.2 km',
        finalTime: const Duration(hours: 1, minutes: 30),
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(expectedHike);

      // Act
      await notifier.getFinalHike(positions);

      // Assert
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
      final state = notifier.state as RecapHikeStateHikeFetched;
      expect(state.hike, equals(expectedHike));
      verify(() => mockFinishImproviseUseCase.buildFinalHike(positions)).called(1);
    });

    test('should reset state to loading before fetching', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      final hike = ImproviseHike(
        distance: '3.5 km',
        finalTime: const Duration(hours: 1),
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(hike);

      // Change to another state first
      notifier.state = const RecapHikeStateHikeNotFetched();

      // Act
      await notifier.getFinalHike(positions);

      // Assert - should end in fetched state after going through loading
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
    });

    test('should handle error and set error state', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenThrow(Exception('Failed to build hike'));

      // Act
      await notifier.getFinalHike(positions);

      // Assert
      expect(notifier.state, isA<RecapHikeStateError>());
      final state = notifier.state as RecapHikeStateError;
      expect(state.message, contains('Failed to build hike'));
    });

    test('should handle empty segments', () async {
      // Arrange
      final List<List<gl.Position>> emptySegments = [];

      final emptyHike = ImproviseHike(
        distance: '0 km',
        finalTime: Duration.zero,
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(emptySegments))
          .thenReturn(emptyHike);

      // Act
      await notifier.getFinalHike(emptySegments);

      // Assert
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
      final state = notifier.state as RecapHikeStateHikeFetched;
      expect(state.hike.distance, equals('0 km'));
      expect(state.hike.finalTime, equals(Duration.zero));
    });

    test('should handle multiple segments', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
        [
          gl.Position(
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
          ),
        ],
      ];

      final hike = ImproviseHike(
        distance: '10.5 km',
        finalTime: const Duration(hours: 2, minutes: 30),
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(hike);

      // Act
      await notifier.getFinalHike(positions);

      // Assert
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
      verify(() => mockFinishImproviseUseCase.buildFinalHike(positions)).called(1);
    });
  });

  group('RecapHikeStateNotifier - Error Handling', () {
    test('should handle generic exception', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenThrow(Exception('Generic error'));

      // Act
      await notifier.getFinalHike(positions);

      // Assert
      expect(notifier.state, isA<RecapHikeStateError>());
      final state = notifier.state as RecapHikeStateError;
      expect(state.message, contains('Generic error'));
    });

    test('should handle string error', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenThrow('String error');

      // Act
      await notifier.getFinalHike(positions);

      // Assert
      expect(notifier.state, isA<RecapHikeStateError>());
      final state = notifier.state as RecapHikeStateError;
      expect(state.message, equals('String error'));
    });
  });

  group('RecapHikeStateNotifier - State Transitions', () {
    test('should transition from loading to fetched', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      final hike = ImproviseHike(
        distance: '7.2 km',
        finalTime: const Duration(hours: 1, minutes: 45),
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(hike);

      // Act & Assert
      expect(notifier.state, isA<RecapHikeStateLoading>());

      await notifier.getFinalHike(positions);

      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
    });

    test('should transition from loading to error', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenThrow(Exception('Error'));

      // Act & Assert
      expect(notifier.state, isA<RecapHikeStateLoading>());

      await notifier.getFinalHike(positions);

      expect(notifier.state, isA<RecapHikeStateError>());
    });

    test('should allow multiple calls to getFinalHike', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      final hike1 = ImproviseHike(
        distance: '5.0 km',
        finalTime: const Duration(hours: 1),
        poiTypes: [],
        pois: [],
      );

      final hike2 = ImproviseHike(
        distance: '10.0 km',
        finalTime: const Duration(hours: 2),
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(hike1);

      // First call
      await notifier.getFinalHike(positions);
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
      final state1 = notifier.state as RecapHikeStateHikeFetched;
      expect(state1.hike.distance, equals('5.0 km'));

      // Change mock return
      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(hike2);

      // Second call
      await notifier.getFinalHike(positions);
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
      final state2 = notifier.state as RecapHikeStateHikeFetched;
      expect(state2.hike.distance, equals('10.0 km'));
    });
  });

  group('RecapHikeStateNotifier - Edge Cases', () {
    test('should handle very long hike', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      final longHike = ImproviseHike(
        distance: '100.0 km',
        finalTime: const Duration(hours: 24),
        poiTypes: [],
        pois: [],
        elevationGainPositive: 2000.0,
        elevationGainNegative: 1800.0,
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(longHike);

      // Act
      await notifier.getFinalHike(positions);

      // Assert
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
      final state = notifier.state as RecapHikeStateHikeFetched;
      expect(state.hike.distance, equals('100.0 km'));
      expect(state.hike.finalTime, equals(const Duration(hours: 24)));
    });

    test('should handle hike with title', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      final hikeWithTitle = ImproviseHike(
        title: 'Mountain Adventure',
        distance: '15.0 km',
        finalTime: const Duration(hours: 4),
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(hikeWithTitle);

      // Act
      await notifier.getFinalHike(positions);

      // Assert
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
      final state = notifier.state as RecapHikeStateHikeFetched;
      expect(state.hike.title, equals('Mountain Adventure'));
    });

    test('should handle rapid consecutive calls', () async {
      // Arrange
      final positions = [
        [
          gl.Position(
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
          ),
        ],
      ];

      final hike = ImproviseHike(
        distance: '5.0 km',
        finalTime: const Duration(hours: 1),
        poiTypes: [],
        pois: [],
      );

      when(() => mockFinishImproviseUseCase.buildFinalHike(positions))
          .thenReturn(hike);

      // Act - Make multiple rapid calls
      final futures = [
        notifier.getFinalHike(positions),
        notifier.getFinalHike(positions),
        notifier.getFinalHike(positions),
      ];

      await Future.wait(futures);

      // Assert - Should end in fetched state
      expect(notifier.state, isA<RecapHikeStateHikeFetched>());
    });
  });
}
