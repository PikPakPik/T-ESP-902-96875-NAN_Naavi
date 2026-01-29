import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/data/models/improvise_hike.dart';
import 'package:naavi/presentation/common/recap/RecapHikeState.dart';

void main() {
  group('RecapHikeStateLoading', () {
    test('should create loading state', () {
      const state = RecapHikeStateLoading();
      expect(state, isA<RecapHikeState>());
    });
  });

  group('RecapHikeStateHikeFetched', () {
    test('should create with hike data', () {
      final hike = ImproviseHike(
        distance: '5.2 km',
        finalTime: const Duration(hours: 1, minutes: 30),
        poiTypes: [],
        pois: [],
      );

      final state = RecapHikeStateHikeFetched(hike);

      expect(state.hike, equals(hike));
      expect(state, isA<RecapHikeState>());
    });

    test('should create with empty hike', () {
      final hike = ImproviseHike(
        distance: '0 km',
        finalTime: Duration.zero,
        poiTypes: [],
        pois: [],
      );
      final state = RecapHikeStateHikeFetched(hike);

      expect(state.hike.pois, isEmpty);
    });

    test('should create with title', () {
      final hike = ImproviseHike(
        title: 'My Hike',
        distance: '10.5 km',
        finalTime: const Duration(hours: 2, minutes: 45),
        poiTypes: [],
        pois: [],
      );
      final state = RecapHikeStateHikeFetched(hike);

      expect(state.hike.title, equals('My Hike'));
      expect(state.hike.distance, equals('10.5 km'));
    });

    test('should create with elevation data', () {
      final hike = ImproviseHike(
        distance: '8.3 km',
        finalTime: const Duration(hours: 2),
        poiTypes: [],
        pois: [],
        elevationGainPositive: 250.5,
        elevationGainNegative: 180.3,
      );
      final state = RecapHikeStateHikeFetched(hike);

      expect(state.hike.elevationGainPositive, equals(250.5));
      expect(state.hike.elevationGainNegative, equals(180.3));
    });
  });

  group('RecapHikeStateHikeNotFetched', () {
    test('should create not fetched state', () {
      const state = RecapHikeStateHikeNotFetched();
      expect(state, isA<RecapHikeState>());
    });
  });

  group('RecapHikeStateError', () {
    test('should create with error message', () {
      const state = RecapHikeStateError('Failed to load hike');
      expect(state.message, equals('Failed to load hike'));
      expect(state, isA<RecapHikeState>());
    });

    test('should handle empty error message', () {
      const state = RecapHikeStateError('');
      expect(state.message, isEmpty);
    });

    test('should handle detailed error message', () {
      const errorMsg = 'Network error: Connection timeout after 30s';
      const state = RecapHikeStateError(errorMsg);
      expect(state.message, equals(errorMsg));
    });
  });

  group('RecapHikeState type checking', () {
    test('should distinguish between different state types', () {
      const loading = RecapHikeStateLoading();
      final fetched = RecapHikeStateHikeFetched(ImproviseHike(
        distance: '0 km',
        finalTime: Duration.zero,
        poiTypes: [],
        pois: [],
      ));
      const notFetched = RecapHikeStateHikeNotFetched();
      const error = RecapHikeStateError('error');

      expect(loading, isA<RecapHikeStateLoading>());
      expect(fetched, isA<RecapHikeStateHikeFetched>());
      expect(notFetched, isA<RecapHikeStateHikeNotFetched>());
      expect(error, isA<RecapHikeStateError>());
    });
  });

  group('RecapHikeState flow', () {
    test('should represent typical loading flow', () {
      // Start loading
      const state1 = RecapHikeStateLoading();
      expect(state1, isA<RecapHikeStateLoading>());

      // Fetch successful
      final hike = ImproviseHike(
        distance: '0 km',
        finalTime: Duration.zero,
        poiTypes: [],
        pois: [],
      );
      final state2 = RecapHikeStateHikeFetched(hike);
      expect(state2, isA<RecapHikeStateHikeFetched>());
    });

    test('should represent error flow', () {
      // Start loading
      const state1 = RecapHikeStateLoading();
      expect(state1, isA<RecapHikeStateLoading>());

      // Error occurred
      const state2 = RecapHikeStateError('Network error');
      expect(state2, isA<RecapHikeStateError>());
    });

    test('should represent not fetched flow', () {
      // No hike to fetch
      const state = RecapHikeStateHikeNotFetched();
      expect(state, isA<RecapHikeStateHikeNotFetched>());
    });
  });
}
