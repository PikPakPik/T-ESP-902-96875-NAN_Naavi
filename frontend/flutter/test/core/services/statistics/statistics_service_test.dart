import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/services/statistics/statistics_service.dart';

// Helper pour créer des positions plus facilement
gl.Position createPosition(double lat, double lon, double alt) {
  return gl.Position(
    latitude: lat,
    longitude: lon,
    altitude: alt,
    timestamp: DateTime.now(),
    accuracy: 10.0,
    altitudeAccuracy: 5.0,
    heading: 0.0,
    headingAccuracy: 5.0,
    speed: 0.0,
    speedAccuracy: 1.0,
  );
}

void main() {
  group('StatisticsService', () {
    late StatisticsService service;

    setUp(() {
      service = StatisticsService();
    });

    group('Timer Management', () {
      test('should start timer', () {
        service.startTimer();
        expect(service.getFinalTime(), isNull);
      });

      test('should calculate final time when stopped', () async {
        service.startTimer();
        await Future.delayed(const Duration(milliseconds: 100));
        service.stopTimer();

        final finalTime = service.getFinalTime();
        expect(finalTime, isNotNull);
        expect(finalTime!.inMilliseconds, greaterThan(50));
      });

      test('should handle pause and resume', () async {
        service.startTimer();
        await Future.delayed(const Duration(milliseconds: 50));

        service.pauseTimer();
        await Future.delayed(const Duration(milliseconds: 100));

        service.resumeTimer();
        await Future.delayed(const Duration(milliseconds: 50));

        service.stopTimer();

        final finalTime = service.getFinalTime();
        expect(finalTime, isNotNull);
        expect(finalTime!.inMilliseconds, lessThan(150));
      });

      test('should not fail when stopping without starting', () {
        service.stopTimer();
        expect(service.getFinalTime(), isNull);
      });

      test('should reset paused duration on start', () async {
        service.startTimer();
        service.pauseTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.stopTimer();

        service.startTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.stopTimer();

        final finalTime = service.getFinalTime();
        expect(finalTime!.inMilliseconds, lessThan(100));
      });

      test('should handle multiple pause/resume cycles', () async {
        service.startTimer();

        await Future.delayed(const Duration(milliseconds: 20));
        service.pauseTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.resumeTimer();

        await Future.delayed(const Duration(milliseconds: 20));
        service.pauseTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.resumeTimer();

        await Future.delayed(const Duration(milliseconds: 20));
        service.stopTimer();

        final finalTime = service.getFinalTime();
        expect(finalTime, isNotNull);
        expect(finalTime!.inMilliseconds, lessThan(100));
      });

      test('setFinalTime should call stopTimer', () async {
        service.startTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.setFinalTime();

        expect(service.getFinalTime(), isNotNull);
      });
    });

    group('Distance Calculation', () {
      test('should calculate distance for single segment', () {
        final segments = [
          [
            createPosition(48.8566, 2.3522, 35.0),
            createPosition(48.8576, 2.3532, 35.0),
          ],
        ];

        final distance = service.calculateTotalDistance(segments);
        expect(distance, greaterThan(0));
        expect(distance, lessThan(1));
      });

      test('should handle multiple segments', () {
        final segments = [
          [
            createPosition(48.8566, 2.3522, 35.0),
            createPosition(48.8576, 2.3532, 35.0),
          ],
          [
            createPosition(48.8576, 2.3532, 35.0),
            createPosition(48.8586, 2.3542, 35.0),
          ],
        ];

        final distance = service.calculateTotalDistance(segments);
        expect(distance, greaterThan(0));
      });

      test('should handle elevation changes', () {
        final segments = [
          [
            createPosition(48.8566, 2.3522, 35.0),
            createPosition(48.8576, 2.3532, 100.0),
          ],
        ];

        final distanceWithElevation = service.calculateTotalDistance(segments);

        final segmentsFlat = [
          [
            createPosition(48.8566, 2.3522, 35.0),
            createPosition(48.8576, 2.3532, 35.0),
          ],
        ];
        final distanceFlat = service.calculateTotalDistance(segmentsFlat);

        expect(distanceWithElevation, greaterThan(distanceFlat));
      });

      test('should handle empty segments', () {
        final distance = service.calculateTotalDistance([]);
        expect(distance, equals(0.0));
      });

      test('should handle segments with less than 2 points', () {
        final segments = [
          [createPosition(48.8566, 2.3522, 35.0)],
        ];

        final distance = service.calculateTotalDistance(segments);
        expect(distance, equals(0.0));
      });

      test('should round distance to 2 decimal places', () {
        final segments = [
          [
            createPosition(48.8566, 2.3522, 35.0),
            createPosition(48.8576, 2.3532, 35.0),
          ],
        ];

        final distance = service.calculateTotalDistance(segments);
        final decimalPlaces = distance.toString().split('.').length > 1
            ? distance.toString().split('.')[1].length
            : 0;
        expect(decimalPlaces, lessThanOrEqualTo(2));
      });

      test('setFinalDistance should store distance', () {
        service.setFinalDistance(5.25);
        expect(service.finalDistance, equals(5.25));
      });
    });

    group('calculateElevationGain', () {
      test('should calculate positive and negative elevation gain', () {
        final segments = [
          [
            createPosition(47.2173, -1.5534, 50),
            createPosition(47.2174, -1.5535, 60),
            createPosition(47.2175, -1.5536, 55),
            createPosition(47.2176, -1.5537, 65),
          ],
        ];

        final elevation = service.calculateElevationGain(segments);

        expect(elevation['positive'], equals(20.0));
        expect(elevation['negative'], equals(5.0));
      });

      test('should handle descending routes', () {
        final segments = [
          [
            createPosition(47.2173, -1.5534, 100),
            createPosition(47.2174, -1.5535, 80),
            createPosition(47.2175, -1.5536, 60),
          ],
        ];

        final elevation = service.calculateElevationGain(segments);

        expect(elevation['positive'], equals(0.0));
        expect(elevation['negative'], equals(40.0));
      });

      test('should handle empty segments', () {
        final elevation = service.calculateElevationGain([]);

        expect(elevation['positive'], equals(0.0));
        expect(elevation['negative'], equals(0.0));
      });

      test('should handle single point segments', () {
        final segments = [
          [createPosition(47.2173, -1.5534, 50)],
        ];

        final elevation = service.calculateElevationGain(segments);

        expect(elevation['positive'], equals(0.0));
        expect(elevation['negative'], equals(0.0));
      });

      test('should handle multiple segments', () {
        final segments = [
          [
            createPosition(47.2173, -1.5534, 50),
            createPosition(47.2174, -1.5535, 70),
          ],
          [
            createPosition(47.2175, -1.5536, 60),
            createPosition(47.2176, -1.5537, 80),
          ],
        ];

        final elevation = service.calculateElevationGain(segments);

        expect(elevation['positive'], equals(40.0));
        expect(elevation['negative'], equals(0.0));
      });
    });

    group('reset', () {
      test('should reset all timer values', () async {
        service.startTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.stopTimer();
        service.setFinalDistance(10.5);

        expect(service.getFinalTime(), isNotNull);
        expect(service.finalDistance, equals(10.5));

        service.reset();

        expect(service.getFinalTime(), equals(Duration.zero));
        expect(service.finalDistance, equals(0.0));
      });

      test('should allow starting timer after reset', () async {
        service.startTimer();
        service.stopTimer();
        service.reset();

        service.startTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.stopTimer();

        final finalTime = service.getFinalTime();
        expect(finalTime, isNotNull);
        expect(finalTime!.inMilliseconds, greaterThan(0));
      });
    });

    group('setFinalDistance', () {
      test('should set final distance', () {
        service.setFinalDistance(15.75);
        expect(service.finalDistance, equals(15.75));
      });
    });

    group('setFinalTime', () {
      test('should set final time by stopping timer', () async {
        service.startTimer();
        await Future.delayed(const Duration(milliseconds: 50));
        service.setFinalTime();

        final finalTime = service.getFinalTime();
        expect(finalTime, isNotNull);
        expect(finalTime!.inMilliseconds, greaterThan(0));
      });
    });
  });
}
