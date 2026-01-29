import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/tracking/location_state_notifier.dart';
import 'package:naavi/core/models/location_state.dart';

// Mock classes for Geolocator
class MockGeolocatorPlatform extends Mock implements gl.GeolocatorPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationStateNotifier - Initialization', () {
    test('should initialize with default empty state', () {
      // Arrange & Act
      final notifier = LocationStateNotifier();

      // Assert
      expect(notifier.state.currentPosition, isNull);
      expect(notifier.state.isTracking, isFalse);
      expect(notifier.state.hasPermission, isFalse);
      expect(notifier.state.error, isNull);

      notifier.dispose();
    });

    test('should start with LocationState having default values', () {
      // Arrange & Act
      final notifier = LocationStateNotifier();
      final state = notifier.state;

      // Assert
      expect(state, isA<LocationState>());
      expect(state.isTracking, isFalse);
      expect(state.hasPermission, isFalse);

      notifier.dispose();
    });
  });

  group('LocationStateNotifier - State Management', () {
    test('should update state when position changes', () {
      // Arrange
      final notifier = LocationStateNotifier();
      final position = gl.Position(
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
      );

      // Act
      notifier.state = notifier.state.copyWith(currentPosition: position);

      // Assert
      expect(notifier.state.currentPosition, equals(position));
      expect(notifier.state.currentPosition?.latitude, equals(48.8566));
      expect(notifier.state.currentPosition?.longitude, equals(2.3522));

      notifier.dispose();
    });

    test('should update tracking state', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(isTracking: true);

      // Assert
      expect(notifier.state.isTracking, isTrue);

      notifier.dispose();
    });

    test('should update permission state', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(hasPermission: true);

      // Assert
      expect(notifier.state.hasPermission, isTrue);

      notifier.dispose();
    });

    test('should update error state', () {
      // Arrange
      final notifier = LocationStateNotifier();
      const errorMessage = 'Test error';

      // Act
      notifier.state = notifier.state.copyWith(error: errorMessage);

      // Assert
      expect(notifier.state.error, equals(errorMessage));

      notifier.dispose();
    });

    test('should keep error when updating other fields without clearing', () {
      // Arrange
      final notifier = LocationStateNotifier();
      notifier.state = notifier.state.copyWith(error: 'Initial error');

      // Act - copyWith with error: null keeps the existing error
      notifier.state = notifier.state.copyWith(hasPermission: true);

      // Assert - error is preserved because null means "keep existing"
      expect(notifier.state.error, equals('Initial error'));
      expect(notifier.state.hasPermission, isTrue);

      notifier.dispose();
    });
  });

  group('LocationStateNotifier - Lifecycle', () {
    test('should not be tracking initially', () {
      // Arrange & Act
      final notifier = LocationStateNotifier();

      // Assert
      expect(notifier.state.isTracking, isFalse);

      notifier.dispose();
    });

    test('should clean up on dispose', () {
      // Arrange
      final notifier = LocationStateNotifier();
      notifier.state = notifier.state.copyWith(isTracking: true);

      // Act & Assert - should not throw
      expect(() => notifier.dispose(), returnsNormally);
    });
  });

  group('LocationStateNotifier - Error Handling', () {
    test('should handle location service disabled error', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(
        error: 'Location services disabled',
      );

      // Assert
      expect(notifier.state.error, contains('disabled'));
      expect(notifier.state.hasPermission, isFalse);

      notifier.dispose();
    });

    test('should handle permission denied error', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(
        error: 'Location permissions denied',
      );

      // Assert
      expect(notifier.state.error, contains('denied'));

      notifier.dispose();
    });

    test('should handle permission denied forever error', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(
        error: 'Location permissions denied forever',
      );

      // Assert
      expect(notifier.state.error, contains('forever'));

      notifier.dispose();
    });

    test('should handle generic error', () {
      // Arrange
      final notifier = LocationStateNotifier();
      const genericError = 'Something went wrong';

      // Act
      notifier.state = notifier.state.copyWith(error: genericError);

      // Assert
      expect(notifier.state.error, equals(genericError));

      notifier.dispose();
    });
  });

  group('LocationStateNotifier - Position Updates', () {
    test('should update position multiple times', () {
      // Arrange
      final notifier = LocationStateNotifier();
      final positions = [
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
        gl.Position(
          latitude: 48.8567,
          longitude: 2.3523,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 5,
          heading: 0,
          headingAccuracy: 1,
          speed: 5,
          speedAccuracy: 1,
        ),
      ];

      // Act
      notifier.state = notifier.state.copyWith(currentPosition: positions[0]);
      expect(notifier.state.currentPosition, equals(positions[0]));

      notifier.state = notifier.state.copyWith(currentPosition: positions[1]);

      // Assert
      expect(notifier.state.currentPosition, equals(positions[1]));
      expect(notifier.state.currentPosition?.latitude, equals(48.8567));

      notifier.dispose();
    });

    test('should handle position with null values', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(currentPosition: null);

      // Assert
      expect(notifier.state.currentPosition, isNull);

      notifier.dispose();
    });

    test('should handle position with extreme coordinates', () {
      // Arrange
      final notifier = LocationStateNotifier();
      final extremePosition = gl.Position(
        latitude: 90.0, // North Pole
        longitude: 180.0, // Date line
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      // Act
      notifier.state = notifier.state.copyWith(
        currentPosition: extremePosition,
      );

      // Assert
      expect(notifier.state.currentPosition?.latitude, equals(90.0));
      expect(notifier.state.currentPosition?.longitude, equals(180.0));

      notifier.dispose();
    });

    test('should handle position with negative coordinates', () {
      // Arrange
      final notifier = LocationStateNotifier();
      final negativePosition = gl.Position(
        latitude: -45.0,
        longitude: -120.0,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      // Act
      notifier.state = notifier.state.copyWith(
        currentPosition: negativePosition,
      );

      // Assert
      expect(notifier.state.currentPosition?.latitude, equals(-45.0));
      expect(notifier.state.currentPosition?.longitude, equals(-120.0));

      notifier.dispose();
    });
  });

  group('LocationStateNotifier - State Transitions', () {
    test('should transition from idle to tracking', () {
      // Arrange
      final notifier = LocationStateNotifier();
      expect(notifier.state.isTracking, isFalse);

      // Act
      notifier.state = notifier.state.copyWith(isTracking: true);

      // Assert
      expect(notifier.state.isTracking, isTrue);

      notifier.dispose();
    });

    test('should transition from tracking to stopped', () {
      // Arrange
      final notifier = LocationStateNotifier();
      notifier.state = notifier.state.copyWith(isTracking: true);

      // Act
      notifier.state = notifier.state.copyWith(isTracking: false);

      // Assert
      expect(notifier.state.isTracking, isFalse);

      notifier.dispose();
    });

    test('should handle permission granted flow', () {
      // Arrange
      final notifier = LocationStateNotifier();
      expect(notifier.state.hasPermission, isFalse);

      // Act
      notifier.state = notifier.state.copyWith(
        hasPermission: true,
        error: null,
      );

      // Assert
      expect(notifier.state.hasPermission, isTrue);
      expect(notifier.state.error, isNull);

      notifier.dispose();
    });

    test('should handle permission denied flow', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(
        hasPermission: false,
        error: 'Permission denied',
      );

      // Assert
      expect(notifier.state.hasPermission, isFalse);
      expect(notifier.state.error, isNotNull);

      notifier.dispose();
    });
  });

  group('LocationStateNotifier - Complex Scenarios', () {
    test('should handle complete tracking session', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act - Start tracking
      notifier.state = notifier.state.copyWith(
        hasPermission: true,
        isTracking: true,
      );

      // Update position
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 5,
        speedAccuracy: 1,
      );
      notifier.state = notifier.state.copyWith(currentPosition: position);

      // Stop tracking
      notifier.state = notifier.state.copyWith(isTracking: false);

      // Assert
      expect(notifier.state.hasPermission, isTrue);
      expect(notifier.state.isTracking, isFalse);
      expect(notifier.state.currentPosition, isNotNull);

      notifier.dispose();
    });

    test('should handle error recovery by setting new error value', () {
      // Arrange
      final notifier = LocationStateNotifier();
      notifier.state = notifier.state.copyWith(error: 'Initial error');

      // Act - To clear error, we need to create a new state
      notifier.state = LocationState(
        hasPermission: true,
        isTracking: notifier.state.isTracking,
        currentPosition: notifier.state.currentPosition,
        error: null,
      );

      // Assert
      expect(notifier.state.error, isNull);
      expect(notifier.state.hasPermission, isTrue);

      notifier.dispose();
    });

    test('should maintain position after tracking stops', () {
      // Arrange
      final notifier = LocationStateNotifier();
      final position = gl.Position(
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
      );

      // Act
      notifier.state = notifier.state.copyWith(
        isTracking: true,
        currentPosition: position,
      );
      notifier.state = notifier.state.copyWith(isTracking: false);

      // Assert
      expect(notifier.state.currentPosition, equals(position));
      expect(notifier.state.isTracking, isFalse);

      notifier.dispose();
    });

    test('should handle multiple start/stop cycles', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act - Multiple cycles
      for (int i = 0; i < 3; i++) {
        notifier.state = notifier.state.copyWith(isTracking: true);
        expect(notifier.state.isTracking, isTrue);

        notifier.state = notifier.state.copyWith(isTracking: false);
        expect(notifier.state.isTracking, isFalse);
      }

      // Assert
      expect(notifier.state.isTracking, isFalse);

      notifier.dispose();
    });
  });

  group('LocationStateNotifier - Edge Cases', () {
    test('should handle rapid state changes', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act - Rapid changes
      for (int i = 0; i < 10; i++) {
        notifier.state = notifier.state.copyWith(isTracking: i.isEven);
      }

      // Assert - should end with false (9 is odd)
      expect(notifier.state.isTracking, isFalse);

      notifier.dispose();
    });

    test('should handle setting same state multiple times', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(isTracking: true);
      notifier.state = notifier.state.copyWith(isTracking: true);
      notifier.state = notifier.state.copyWith(isTracking: true);

      // Assert
      expect(notifier.state.isTracking, isTrue);

      notifier.dispose();
    });

    test('should handle all fields updated at once', () {
      // Arrange
      final notifier = LocationStateNotifier();
      final position = gl.Position(
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
      );

      // Act
      notifier.state = notifier.state.copyWith(
        currentPosition: position,
        isTracking: true,
        hasPermission: true,
        error: null,
      );

      // Assert
      expect(notifier.state.currentPosition, equals(position));
      expect(notifier.state.isTracking, isTrue);
      expect(notifier.state.hasPermission, isTrue);
      expect(notifier.state.error, isNull);

      notifier.dispose();
    });

    test('should handle empty error string', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(error: '');

      // Assert
      expect(notifier.state.error, equals(''));

      notifier.dispose();
    });

    test('should handle very long error message', () {
      // Arrange
      final notifier = LocationStateNotifier();
      final longError = 'Error: ' * 100;

      // Act
      notifier.state = notifier.state.copyWith(error: longError);

      // Assert
      expect(notifier.state.error, equals(longError));
      expect(notifier.state.error!.length, greaterThan(100));

      notifier.dispose();
    });
  });

  group('LocationStateNotifier - Memory Management', () {
    test('should not leak memory on multiple position updates', () {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act - Create many positions
      for (int i = 0; i < 100; i++) {
        final position = gl.Position(
          latitude: 48.8566 + i * 0.0001,
          longitude: 2.3522 + i * 0.0001,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 5,
          heading: 0,
          headingAccuracy: 1,
          speed: i.toDouble(),
          speedAccuracy: 1,
        );
        notifier.state = notifier.state.copyWith(currentPosition: position);
      }

      // Assert - Only last position should be retained
      expect(notifier.state.currentPosition?.speed, equals(99.0));

      notifier.dispose();
    });

    test('should dispose without error', () {
      // Arrange
      final notifier = LocationStateNotifier();
      notifier.state = notifier.state.copyWith(
        isTracking: true,
        hasPermission: true,
      );

      // Act & Assert - dispose should not throw
      expect(() => notifier.dispose(), returnsNormally);
    });
  });

  group('LocationStateNotifier - Integration Tests', () {
    test('should handle realistic tracking scenario', () async {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act - Simulate realistic flow
      // 1. Request permission
      notifier.state = notifier.state.copyWith(hasPermission: true);
      await Future.delayed(const Duration(milliseconds: 10));

      // 2. Start tracking
      notifier.state = notifier.state.copyWith(isTracking: true);
      await Future.delayed(const Duration(milliseconds: 10));

      // 3. Receive positions
      for (int i = 0; i < 5; i++) {
        final position = gl.Position(
          latitude: 48.8566 + i * 0.001,
          longitude: 2.3522 + i * 0.001,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 5,
          heading: i * 10.0,
          headingAccuracy: 1,
          speed: i * 2.0,
          speedAccuracy: 1,
        );
        notifier.state = notifier.state.copyWith(currentPosition: position);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 4. Stop tracking
      notifier.state = notifier.state.copyWith(isTracking: false);

      // Assert
      expect(notifier.state.hasPermission, isTrue);
      expect(notifier.state.isTracking, isFalse);
      expect(notifier.state.currentPosition, isNotNull);
      expect(notifier.state.currentPosition?.speed, equals(8.0));

      notifier.dispose();
    });

    test('should handle error during tracking', () async {
      // Arrange
      final notifier = LocationStateNotifier();

      // Act
      notifier.state = notifier.state.copyWith(
        hasPermission: true,
        isTracking: true,
      );

      // Error occurs
      notifier.state = notifier.state.copyWith(error: 'GPS signal lost');

      // Recover by setting new state (copyWith null keeps existing value)
      notifier.state = LocationState(
        hasPermission: notifier.state.hasPermission,
        isTracking: notifier.state.isTracking,
        currentPosition: notifier.state.currentPosition,
        error: null,
      );

      // Assert
      expect(notifier.state.error, isNull);
      expect(notifier.state.isTracking, isTrue);

      notifier.dispose();
    });
  });
}
