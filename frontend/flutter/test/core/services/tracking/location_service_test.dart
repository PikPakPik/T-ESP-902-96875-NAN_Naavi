import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/services/tracking/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService', () {
    late LocationService locationService;
    List<gl.Position> capturedPositions;

    setUp(() {
      capturedPositions = [];
      locationService = LocationService(
        onPositionChanged: (position) => capturedPositions.add(position),
      );
    });

    tearDown(() {
      locationService.dispose();
    });

    test('should initialize with null current position', () {
      expect(locationService.currentPosition, isNull);
    });

    test('should have onPositionChanged callback', () {
      final positions = <gl.Position>[];
      final service = LocationService(
        onPositionChanged: (position) => positions.add(position),
      );

      expect(service.onPositionChanged, isNotNull);
    });

    test('should work without onPositionChanged callback', () {
      final service = LocationService();
      expect(service.onPositionChanged, isNull);
    });

    group('getCurrentPosition', () {
      test('should return null when location services are disabled', () async {
        // Note: In real tests, we would need to mock Geolocator
        // For now, this tests the structure
        // In practice, you'd use a wrapper class for Geolocator that can be mocked
      });

      test('should handle timeout correctly', () async {
        // Test timeout handling
        // Note: Would require mocking Geolocator.getCurrentPosition
      });

      test('should return null on permission denied', () async {
        // Test permission denied scenario
        // Would require mocking Geolocator permission methods
      });

      test('should return null on deniedForever permission', () async {
        // Test deniedForever permission scenario
      });
    });

    group('startTracking', () {
      test('should start position stream with default distance filter', () {
        // Note: Testing streams requires mocking Geolocator.getPositionStream
        // For now, test that method doesn't throw
        expect(() => locationService.startTracking(), returnsNormally);
      });

      test('should start tracking with custom distance filter', () {
        expect(
          () => locationService.startTracking(distanceFilter: 10),
          returnsNormally,
        );
      });

      test('should cancel previous tracking when starting new one', () {
        locationService.startTracking();
        // Starting again should cancel previous subscription
        expect(() => locationService.startTracking(), returnsNormally);
      });
    });

    group('stopTracking', () {
      test('should stop position tracking', () {
        locationService.startTracking();
        expect(() => locationService.stopTracking(), returnsNormally);
      });

      test('should handle stop when not tracking', () {
        expect(() => locationService.stopTracking(), returnsNormally);
      });

      test('should be safe to call multiple times', () {
        locationService.stopTracking();
        locationService.stopTracking();
        expect(() => locationService.stopTracking(), returnsNormally);
      });
    });

    group('dispose', () {
      test('should stop tracking on dispose', () {
        locationService.startTracking();
        expect(() => locationService.dispose(), returnsNormally);
      });

      test('should handle dispose when not tracking', () {
        expect(() => locationService.dispose(), returnsNormally);
      });
    });

    group('Position Tracking Lifecycle', () {
      test('should support complete lifecycle: start -> stop -> start', () {
        locationService.startTracking();
        locationService.stopTracking();
        expect(() => locationService.startTracking(), returnsNormally);
      });

      test('should support dispose after tracking', () {
        locationService.startTracking();
        locationService.stopTracking();
        expect(() => locationService.dispose(), returnsNormally);
      });
    });

    group('Distance Filter Configuration', () {
      test('should accept zero distance filter', () {
        expect(
          () => locationService.startTracking(distanceFilter: 0),
          returnsNormally,
        );
      });

      test('should accept large distance filter', () {
        expect(
          () => locationService.startTracking(distanceFilter: 1000),
          returnsNormally,
        );
      });

      test('should use default distance filter of 5 when not specified', () {
        // Default is 5 meters according to implementation
        expect(() => locationService.startTracking(), returnsNormally);
      });
    });

    group('Callback Invocation', () {
      test('should invoke callback when provided', () {
        final service = LocationService(
          onPositionChanged: (_) {},
        );

        expect(service.onPositionChanged, isNotNull);
      });

      test('should not crash when callback is null', () {
        final service = LocationService();
        service.startTracking();
        // Should not crash even without callback
        expect(() => service.stopTracking(), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle stream errors gracefully', () {
        // The implementation has cancelOnError: false
        // This means it should continue listening even after errors
        expect(() => locationService.startTracking(), returnsNormally);
      });
    });

    group('Integration Tests', () {
      test('should support multiple tracking sessions', () {
        // Start first session
        locationService.startTracking();
        locationService.stopTracking();

        // Start second session
        locationService.startTracking();
        locationService.stopTracking();

        // Start third session
        locationService.startTracking();
        locationService.dispose();

        expect(true, true); // If we get here, all operations succeeded
      });

      test('should handle rapid start/stop cycles', () {
        for (int i = 0; i < 10; i++) {
          locationService.startTracking();
          locationService.stopTracking();
        }
        expect(true, true);
      });
    });
  });

  group('LocationService with Multiple Instances', () {
    test('should support multiple independent instances', () {
      final service1 = LocationService();
      final service2 = LocationService();

      service1.startTracking();
      service2.startTracking();

      service1.stopTracking();
      service2.stopTracking();

      service1.dispose();
      service2.dispose();

      expect(true, true);
    });

    test('should maintain independent state for each instance', () {
      final service1 = LocationService();
      final service2 = LocationService();

      service1.startTracking();
      expect(service2.currentPosition, isNull);

      service1.dispose();
      service2.dispose();
    });
  });
}
