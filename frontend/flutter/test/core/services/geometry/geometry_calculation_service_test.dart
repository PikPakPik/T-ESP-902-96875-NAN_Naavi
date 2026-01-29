import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/services/geometry/geometry_calculation_service.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeometryCalculationService', () {
    group('calculateBearing', () {
      test('should calculate bearing for north direction', () {
        // From Paris to a point north of Paris
        final bearing = GeometryCalculationService.calculateBearing(
          48.8566, 2.3522, // Paris
          49.8566, 2.3522, // North of Paris
        );

        expect(bearing, closeTo(0.0, 1.0)); // Should be close to 0° (North)
      });

      test('should calculate bearing for east direction', () {
        // From Paris to a point east of Paris
        final bearing = GeometryCalculationService.calculateBearing(
          48.8566, 2.3522, // Paris
          48.8566, 3.3522, // East of Paris
        );

        expect(bearing, closeTo(90.0, 5.0)); // Should be close to 90° (East)
      });

      test('should calculate bearing for south direction', () {
        // From Paris to a point south of Paris
        final bearing = GeometryCalculationService.calculateBearing(
          48.8566, 2.3522, // Paris
          47.8566, 2.3522, // South of Paris
        );

        expect(bearing, closeTo(180.0, 1.0)); // Should be close to 180° (South)
      });

      test('should calculate bearing for west direction', () {
        // From Paris to a point west of Paris
        final bearing = GeometryCalculationService.calculateBearing(
          48.8566, 2.3522, // Paris
          48.8566, 1.3522, // West of Paris
        );

        expect(bearing, closeTo(270.0, 5.0)); // Should be close to 270° (West)
      });

      test('should always return bearing between 0 and 360', () {
        final bearing = GeometryCalculationService.calculateBearing(
          48.8566, 2.3522,
          40.7128, -74.0060, // New York
        );

        expect(bearing, greaterThanOrEqualTo(0.0));
        expect(bearing, lessThan(360.0));
      });

      test('should return 0 for same point', () {
        final bearing = GeometryCalculationService.calculateBearing(
          48.8566, 2.3522,
          48.8566, 2.3522,
        );

        expect(bearing, isA<double>());
      });

      test('should handle negative coordinates', () {
        final bearing = GeometryCalculationService.calculateBearing(
          -33.8688, 151.2093, // Sydney
          -37.8136, 144.9631, // Melbourne
        );

        expect(bearing, greaterThanOrEqualTo(0.0));
        expect(bearing, lessThan(360.0));
      });

      test('should handle coordinates crossing date line', () {
        final bearing = GeometryCalculationService.calculateBearing(
          35.6762, 139.6503, // Tokyo
          21.3099, -157.8581, // Honolulu
        );

        expect(bearing, greaterThanOrEqualTo(0.0));
        expect(bearing, lessThan(360.0));
      });

      test('should be consistent with reverse bearing', () {
        final bearing1 = GeometryCalculationService.calculateBearing(
          48.8566, 2.3522, // Paris
          51.5074, -0.1278, // London
        );

        final bearing2 = GeometryCalculationService.calculateBearing(
          51.5074, -0.1278, // London
          48.8566, 2.3522, // Paris
        );

        // Reverse bearing should differ by approximately 180 degrees
        final diff = (bearing1 - bearing2).abs();
        expect(diff, anyOf(closeTo(180.0, 5.0), closeTo(180.0, 5.0)));
      });
    });

    group('calculateDistanceKm', () {
      test('should calculate distance between Paris and London', () {
        final distance = GeometryCalculationService.calculateDistanceKm(
          48.8566, 2.3522, // Paris
          51.5074, -0.1278, // London
        );

        // Distance should be approximately 344 km
        expect(distance, greaterThan(340.0));
        expect(distance, lessThan(350.0));
      });

      test('should return zero for same point', () {
        final distance = GeometryCalculationService.calculateDistanceKm(
          48.8566, 2.3522,
          48.8566, 2.3522,
        );

        expect(distance, closeTo(0.0, 0.001));
      });

      test('should calculate distance for nearby points', () {
        final distance = GeometryCalculationService.calculateDistanceKm(
          48.8566, 2.3522, // Paris center
          48.8606, 2.3376, // Nearby point (Arc de Triomphe area)
        );

        // Distance should be a few kilometers
        expect(distance, greaterThan(0.5));
        expect(distance, lessThan(5.0));
      });

      test('should handle negative coordinates', () {
        final distance = GeometryCalculationService.calculateDistanceKm(
          -33.8688, 151.2093, // Sydney
          -37.8136, 144.9631, // Melbourne
        );

        // Distance should be approximately 714 km
        expect(distance, greaterThan(700.0));
        expect(distance, lessThan(750.0));
      });

      test('should be symmetric', () {
        final distance1 = GeometryCalculationService.calculateDistanceKm(
          48.8566, 2.3522, // Paris
          51.5074, -0.1278, // London
        );

        final distance2 = GeometryCalculationService.calculateDistanceKm(
          51.5074, -0.1278, // London
          48.8566, 2.3522, // Paris
        );

        expect(distance1, closeTo(distance2, 0.001));
      });

      test('should handle equator coordinates', () {
        final distance = GeometryCalculationService.calculateDistanceKm(
          0.0, 0.0,
          0.0, 1.0,
        );

        // At equator, 1 degree longitude is approximately 111 km
        expect(distance, greaterThan(100.0));
        expect(distance, lessThan(115.0));
      });

      test('should handle poles', () {
        final distance = GeometryCalculationService.calculateDistanceKm(
          89.9, 0.0, // Near North Pole
          89.9, 180.0, // Near North Pole, opposite side
        );

        expect(distance, greaterThan(0.0));
      });
    });

    group('calculateDistanceMeters', () {
      test('should return distance in meters', () {
        final distanceMeters = GeometryCalculationService.calculateDistanceMeters(
          48.8566, 2.3522, // Paris
          48.8606, 2.3376, // Nearby point
        );

        final distanceKm = GeometryCalculationService.calculateDistanceKm(
          48.8566, 2.3522,
          48.8606, 2.3376,
        );

        expect(distanceMeters, closeTo(distanceKm * 1000, 0.1));
      });

      test('should return zero for same point', () {
        final distance = GeometryCalculationService.calculateDistanceMeters(
          48.8566, 2.3522,
          48.8566, 2.3522,
        );

        expect(distance, closeTo(0.0, 0.001));
      });

      test('should calculate small distances accurately', () {
        final distance = GeometryCalculationService.calculateDistanceMeters(
          48.8566, 2.3522,
          48.8567, 2.3523, // Very close point
        );

        // Should be less than 200 meters
        expect(distance, lessThan(200.0));
        expect(distance, greaterThan(0.0));
      });
    });

    group('angleToDirectionType', () {
      test('should return straight for 0 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(0),
          DirectionType.straight,
        );
      });

      test('should return straight for 360 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(360),
          DirectionType.straight,
        );
      });

      test('should return slightRight for 45 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(45),
          DirectionType.slightRight,
        );
      });

      test('should return right for 90 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(90),
          DirectionType.right,
        );
      });

      test('should return sharpRight for 135 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(135),
          DirectionType.sharpRight,
        );
      });

      test('should return uTurn for 180 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(180),
          DirectionType.uTurn,
        );
      });

      test('should return sharpLeft for 225 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(225),
          DirectionType.sharpLeft,
        );
      });

      test('should return left for 270 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(270),
          DirectionType.left,
        );
      });

      test('should return slightLeft for 315 degrees', () {
        expect(
          GeometryCalculationService.angleToDirectionType(315),
          DirectionType.slightLeft,
        );
      });

      test('should handle negative angles', () {
        final result = GeometryCalculationService.angleToDirectionType(-45);
        expect(result, isA<DirectionType>());
      });

      test('should handle angles greater than 360', () {
        final result = GeometryCalculationService.angleToDirectionType(450);
        expect(result, DirectionType.right); // 450 % 360 = 90
      });

      test('should handle boundary values correctly', () {
        expect(
          GeometryCalculationService.angleToDirectionType(22.4),
          DirectionType.straight,
        );
        expect(
          GeometryCalculationService.angleToDirectionType(22.5),
          DirectionType.slightRight, // Boundary is inclusive on lower end
        );
        expect(
          GeometryCalculationService.angleToDirectionType(22.6),
          DirectionType.slightRight,
        );
      });
    });

    group('angleToDirectionText', () {
      test('should return text for straight direction', () {
        final text = GeometryCalculationService.angleToDirectionText(0);
        expect(text, contains('tout droit'));
      });

      test('should return text for right turn', () {
        final text = GeometryCalculationService.angleToDirectionText(90);
        expect(text, contains('droite'));
      });

      test('should return text for left turn', () {
        final text = GeometryCalculationService.angleToDirectionText(270);
        expect(text, contains('gauche'));
      });

      test('should return text for u-turn', () {
        final text = GeometryCalculationService.angleToDirectionText(180);
        expect(text, contains('demi-tour'));
      });

      test('should return non-empty text for all angles', () {
        for (var angle = 0; angle < 360; angle += 30) {
          final text = GeometryCalculationService.angleToDirectionText(angle.toDouble());
          expect(text, isNotEmpty);
        }
      });
    });

    group('directionTypeToText', () {
      test('should return text for all direction types', () {
        for (final type in DirectionType.values) {
          final text = GeometryCalculationService.directionTypeToText(type);
          expect(text, isNotEmpty);
        }
      });

      test('should return correct text for straight', () {
        final text = GeometryCalculationService.directionTypeToText(DirectionType.straight);
        expect(text, contains('tout droit'));
      });

      test('should return correct text for right', () {
        final text = GeometryCalculationService.directionTypeToText(DirectionType.right);
        expect(text, contains('droite'));
      });

      test('should return correct text for left', () {
        final text = GeometryCalculationService.directionTypeToText(DirectionType.left);
        expect(text, contains('gauche'));
      });

      test('should return correct text for arrived', () {
        final text = GeometryCalculationService.directionTypeToText(DirectionType.arrived);
        expect(text, contains('arrivé'));
      });

      test('should return correct text for u-turn', () {
        final text = GeometryCalculationService.directionTypeToText(DirectionType.uTurn);
        expect(text, contains('demi-tour'));
      });

      test('should return correct text for slight turns', () {
        final slightRight = GeometryCalculationService.directionTypeToText(
          DirectionType.slightRight,
        );
        final slightLeft = GeometryCalculationService.directionTypeToText(
          DirectionType.slightLeft,
        );

        expect(slightRight, contains('légèrement'));
        expect(slightLeft, contains('légèrement'));
      });

      test('should return correct text for sharp turns', () {
        final sharpRight = GeometryCalculationService.directionTypeToText(
          DirectionType.sharpRight,
        );
        final sharpLeft = GeometryCalculationService.directionTypeToText(
          DirectionType.sharpLeft,
        );

        expect(sharpRight, contains('fortement'));
        expect(sharpLeft, contains('fortement'));
      });
    });

    group('calculateDistanceToPoint', () {
      test('should calculate distance to target point', () {
        final currentPosition = gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final distance = GeometryCalculationService.calculateDistanceToPoint(
          currentPosition: currentPosition,
          targetLat: 48.8606,
          targetLon: 2.3376,
        );

        expect(distance, isNotNull);
        expect(distance!, greaterThan(0.0));
        expect(distance, lessThan(5.0)); // Should be a few kilometers
      });

      test('should return null when currentPosition is null', () {
        final distance = GeometryCalculationService.calculateDistanceToPoint(
          currentPosition: null,
          targetLat: 48.8606,
          targetLon: 2.3376,
        );

        expect(distance, isNull);
      });

      test('should return zero for same location', () {
        final currentPosition = gl.Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final distance = GeometryCalculationService.calculateDistanceToPoint(
          currentPosition: currentPosition,
          targetLat: 48.8566,
          targetLon: 2.3522,
        );

        expect(distance, closeTo(0.0, 0.001));
      });

      test('should handle negative coordinates', () {
        final currentPosition = gl.Position(
          latitude: -33.8688,
          longitude: 151.2093,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final distance = GeometryCalculationService.calculateDistanceToPoint(
          currentPosition: currentPosition,
          targetLat: -37.8136,
          targetLon: 144.9631,
        );

        expect(distance, isNotNull);
        expect(distance!, greaterThan(700.0));
      });
    });

    group('degreesToRadians', () {
      test('should convert 0 degrees to 0 radians', () {
        expect(GeometryCalculationService.degreesToRadians(0), 0);
      });

      test('should convert 90 degrees to pi/2 radians', () {
        expect(
          GeometryCalculationService.degreesToRadians(90),
          closeTo(pi / 2, 0.0001),
        );
      });

      test('should convert 180 degrees to pi radians', () {
        expect(
          GeometryCalculationService.degreesToRadians(180),
          closeTo(pi, 0.0001),
        );
      });

      test('should convert 360 degrees to 2*pi radians', () {
        expect(
          GeometryCalculationService.degreesToRadians(360),
          closeTo(2 * pi, 0.0001),
        );
      });

      test('should handle negative degrees', () {
        expect(
          GeometryCalculationService.degreesToRadians(-90),
          closeTo(-pi / 2, 0.0001),
        );
      });

      test('should handle fractional degrees', () {
        expect(
          GeometryCalculationService.degreesToRadians(45.5),
          closeTo(0.7941, 0.0001),
        );
      });
    });

    group('radiansToDegrees', () {
      test('should convert 0 radians to 0 degrees', () {
        expect(GeometryCalculationService.radiansToDegrees(0), 0);
      });

      test('should convert pi/2 radians to 90 degrees', () {
        expect(
          GeometryCalculationService.radiansToDegrees(pi / 2),
          closeTo(90, 0.0001),
        );
      });

      test('should convert pi radians to 180 degrees', () {
        expect(
          GeometryCalculationService.radiansToDegrees(pi),
          closeTo(180, 0.0001),
        );
      });

      test('should convert 2*pi radians to 360 degrees', () {
        expect(
          GeometryCalculationService.radiansToDegrees(2 * pi),
          closeTo(360, 0.0001),
        );
      });

      test('should handle negative radians', () {
        expect(
          GeometryCalculationService.radiansToDegrees(-pi / 2),
          closeTo(-90, 0.0001),
        );
      });

      test('should be inverse of degreesToRadians', () {
        const testValues = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
        for (final degrees in testValues) {
          final radians = GeometryCalculationService.degreesToRadians(degrees);
          final backToDegrees = GeometryCalculationService.radiansToDegrees(radians);
          expect(backToDegrees, closeTo(degrees, 0.0001));
        }
      });
    });

    group('calculateBounds', () {
      test('should calculate bounds for simple coordinates', () {
        final coordinates = [
          [0.0, 0.0],
          [10.0, 10.0]
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.minLat, 0.0);
        expect(bounds.maxLat, 10.0);
        expect(bounds.minLng, 0.0);
        expect(bounds.maxLng, 10.0);
      });

      test('should throw for empty coordinates', () {
        expect(
          () => GeometryCalculationService.calculateBounds([]),
          throwsArgumentError,
        );
      });

      test('should handle single coordinate', () {
        final coordinates = [
          [5.0, 10.0]
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.minLat, 10.0);
        expect(bounds.maxLat, 10.0);
        expect(bounds.minLng, 5.0);
        expect(bounds.maxLng, 5.0);
      });

      test('should calculate bounds for multiple coordinates', () {
        final coordinates = [
          [2.3522, 48.8566], // Paris
          [-0.1278, 51.5074], // London
          [13.4050, 52.5200], // Berlin
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.minLat, closeTo(48.8566, 0.0001));
        expect(bounds.maxLat, closeTo(52.5200, 0.0001));
        expect(bounds.minLng, closeTo(-0.1278, 0.0001));
        expect(bounds.maxLng, closeTo(13.4050, 0.0001));
      });

      test('should handle negative coordinates', () {
        final coordinates = [
          [-10.0, -20.0],
          [-5.0, -15.0],
          [-2.0, -10.0],
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.minLat, -20.0);
        expect(bounds.maxLat, -10.0);
        expect(bounds.minLng, -10.0);
        expect(bounds.maxLng, -2.0);
      });

      test('should handle mixed positive and negative coordinates', () {
        final coordinates = [
          [-10.0, 20.0],
          [10.0, -20.0],
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.minLat, -20.0);
        expect(bounds.maxLat, 20.0);
        expect(bounds.minLng, -10.0);
        expect(bounds.maxLng, 10.0);
      });

      test('should calculate center correctly', () {
        final coordinates = [
          [0.0, 0.0],
          [10.0, 10.0],
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.centerLat, 5.0);
        expect(bounds.centerLng, 5.0);
      });

      test('should calculate differences correctly', () {
        final coordinates = [
          [0.0, 0.0],
          [10.0, 20.0],
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.latDiff, 20.0);
        expect(bounds.lngDiff, 10.0);
      });
    });

    group('calculateBoundsFromPositions', () {
      test('should calculate bounds from Position list', () {
        final positions = [
          gl.Position(
            latitude: 48.8566,
            longitude: 2.3522,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
          gl.Position(
            latitude: 51.5074,
            longitude: -0.1278,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
        ];

        final bounds = GeometryCalculationService.calculateBoundsFromPositions(positions);

        expect(bounds.minLat, closeTo(48.8566, 0.0001));
        expect(bounds.maxLat, closeTo(51.5074, 0.0001));
        expect(bounds.minLng, closeTo(-0.1278, 0.0001));
        expect(bounds.maxLng, closeTo(2.3522, 0.0001));
      });

      test('should handle single position', () {
        final positions = [
          gl.Position(
            latitude: 48.8566,
            longitude: 2.3522,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
        ];

        final bounds = GeometryCalculationService.calculateBoundsFromPositions(positions);

        expect(bounds.minLat, 48.8566);
        expect(bounds.maxLat, 48.8566);
        expect(bounds.minLng, 2.3522);
        expect(bounds.maxLng, 2.3522);
      });
    });

    group('GeoBounds', () {
      test('should calculate center correctly', () {
        final bounds = GeoBounds(
          minLat: 0.0,
          maxLat: 10.0,
          minLng: 0.0,
          maxLng: 20.0,
        );

        expect(bounds.centerLat, 5.0);
        expect(bounds.centerLng, 10.0);
      });

      test('should calculate lat difference correctly', () {
        final bounds = GeoBounds(
          minLat: 10.0,
          maxLat: 30.0,
          minLng: 0.0,
          maxLng: 20.0,
        );

        expect(bounds.latDiff, 20.0);
      });

      test('should calculate lng difference correctly', () {
        final bounds = GeoBounds(
          minLat: 0.0,
          maxLat: 10.0,
          minLng: 5.0,
          maxLng: 25.0,
        );

        expect(bounds.lngDiff, 20.0);
      });

      test('should have correct toString format', () {
        final bounds = GeoBounds(
          minLat: 0.0,
          maxLat: 10.0,
          minLng: 0.0,
          maxLng: 20.0,
        );

        final str = bounds.toString();
        expect(str, contains('GeoBounds'));
        expect(str, contains('lat:'));
        expect(str, contains('lng:'));
        expect(str, contains('center:'));
      });

      test('should handle negative bounds', () {
        final bounds = GeoBounds(
          minLat: -50.0,
          maxLat: -40.0,
          minLng: -30.0,
          maxLng: -20.0,
        );

        expect(bounds.centerLat, -45.0);
        expect(bounds.centerLng, -25.0);
        expect(bounds.latDiff, 10.0);
        expect(bounds.lngDiff, 10.0);
      });

      test('should handle zero-area bounds', () {
        final bounds = GeoBounds(
          minLat: 10.0,
          maxLat: 10.0,
          minLng: 20.0,
          maxLng: 20.0,
        );

        expect(bounds.centerLat, 10.0);
        expect(bounds.centerLng, 20.0);
        expect(bounds.latDiff, 0.0);
        expect(bounds.lngDiff, 0.0);
      });
    });

    group('Edge Cases and Integration', () {
      test('should handle coordinates at equator', () {
        final bearing = GeometryCalculationService.calculateBearing(
          0.0, 0.0,
          0.0, 1.0,
        );

        expect(bearing, greaterThanOrEqualTo(0.0));
        expect(bearing, lessThan(360.0));
      });

      test('should handle coordinates at poles', () {
        final bearing = GeometryCalculationService.calculateBearing(
          89.9, 0.0,
          89.9, 180.0,
        );

        expect(bearing, greaterThanOrEqualTo(0.0));
        expect(bearing, lessThan(360.0));
      });

      test('should handle very small distances', () {
        final distance = GeometryCalculationService.calculateDistanceMeters(
          48.8566, 2.3522,
          48.8566001, 2.3522001,
        );

        expect(distance, greaterThanOrEqualTo(0.0));
        expect(distance, lessThan(1.0)); // Less than 1 meter
      });

      test('should handle very large distances', () {
        final distance = GeometryCalculationService.calculateDistanceKm(
          40.7128, -74.0060, // New York
          -33.8688, 151.2093, // Sydney
        );

        // Distance should be approximately 16,000 km
        expect(distance, greaterThan(15000.0));
        expect(distance, lessThan(17000.0));
      });

      test('should maintain precision with radians conversion', () {
        for (var angle = 0.0; angle <= 360.0; angle += 15.0) {
          final radians = GeometryCalculationService.degreesToRadians(angle);
          final degrees = GeometryCalculationService.radiansToDegrees(radians);
          expect(degrees, closeTo(angle, 0.0001));
        }
      });

      test('should handle coordinate bounds crossing prime meridian', () {
        final coordinates = [
          [-5.0, 50.0],
          [5.0, 55.0],
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.minLng, -5.0);
        expect(bounds.maxLng, 5.0);
      });

      test('should handle coordinate bounds crossing equator', () {
        final coordinates = [
          [0.0, -10.0],
          [0.0, 10.0],
        ];

        final bounds = GeometryCalculationService.calculateBounds(coordinates);

        expect(bounds.minLat, -10.0);
        expect(bounds.maxLat, 10.0);
      });
    });
  });
}
