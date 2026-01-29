import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/presentation/improvise/state/ImproviseHikeState.dart';

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

  group('ImproviseHikeState', () {
    test('ImproviseHikeIdle should be instance of ImproviseHikeState', () {
      const state = ImproviseHikeIdle();
      expect(state, isA<ImproviseHikeState>());
    });

    test('ImproviseHikeStarting should be instance of ImproviseHikeState', () {
      const state = ImproviseHikeStarting();
      expect(state, isA<ImproviseHikeState>());
    });

    test('ImproviseHikeActive should store start point and time', () {
      final position = createPosition();
      final startTime = DateTime.now();

      final state = ImproviseHikeActive(
        startPoint: position,
        startTime: startTime,
      );

      expect(state, isA<ImproviseHikeState>());
      expect(state.startPoint, equals(position));
      expect(state.startTime, equals(startTime));
    });

    test('ImproviseHikeActive elapsedTime should return duration', () {
      final position = createPosition();
      final startTime = DateTime.now().subtract(const Duration(hours: 1));

      final state = ImproviseHikeActive(
        startPoint: position,
        startTime: startTime,
      );

      expect(state.elapsedTime.inMinutes, greaterThanOrEqualTo(59));
    });

    test('ImproviseHikeFinished should store all required data', () {
      final startPosition = createPosition();
      final endPosition = createPosition(latitude: 48.8600);
      final startTime = DateTime.now().subtract(const Duration(hours: 2));
      final endTime = DateTime.now();
      final segments = [
        [startPosition, endPosition],
      ];

      final state = ImproviseHikeFinished(
        startPoint: startPosition,
        endPoint: endPosition,
        startTime: startTime,
        endTime: endTime,
        segments: segments,
        distanceKm: 5.5,
        duration: const Duration(hours: 2),
      );

      expect(state, isA<ImproviseHikeState>());
      expect(state.startPoint, equals(startPosition));
      expect(state.endPoint, equals(endPosition));
      expect(state.startTime, equals(startTime));
      expect(state.endTime, equals(endTime));
      expect(state.segments, equals(segments));
      expect(state.distanceKm, equals(5.5));
    });

    test('ImproviseHikeFinished duration should return correct duration', () {
      final position = createPosition();
      final startTime = DateTime.now().subtract(const Duration(hours: 2));
      final endTime = DateTime.now();

      final state = ImproviseHikeFinished(
        startPoint: position,
        startTime: startTime,
        endTime: endTime,
        segments: [],
        distanceKm: 0.0,
        duration: const Duration(hours: 2),
      );

      expect(state.duration.inMinutes, greaterThanOrEqualTo(119));
    });

    test('ImproviseHikeFinished should allow null endPoint', () {
      final position = createPosition();
      final now = DateTime.now();

      final state = ImproviseHikeFinished(
        startPoint: position,
        startTime: now,
        endTime: now,
        segments: [],
        distanceKm: 0.0,
        duration: Duration.zero,
      );

      expect(state.endPoint, isNull);
    });

    test('ImproviseHikeError should store message and reasons', () {
      const state = ImproviseHikeError(
        message: 'GPS unavailable',
        reasons: ['Location services disabled', 'Permission denied'],
      );

      expect(state, isA<ImproviseHikeState>());
      expect(state.message, equals('GPS unavailable'));
      expect(state.reasons.length, equals(2));
      expect(state.reasons[0], equals('Location services disabled'));
      expect(state.reasons[1], equals('Permission denied'));
    });

    test('ImproviseHikeError should default to empty reasons', () {
      const state = ImproviseHikeError(message: 'Error occurred');

      expect(state.reasons, isEmpty);
    });
  });
}
