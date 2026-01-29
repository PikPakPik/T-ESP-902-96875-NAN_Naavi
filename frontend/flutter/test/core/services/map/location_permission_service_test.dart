import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/services/map/location_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationPermissionService', () {
    group('LocationServiceDisabledException', () {
      test('should create exception with message', () {
        final exception = LocationServiceDisabledException('GPS is off');

        expect(exception, isA<Exception>());
        expect(exception.message, equals('GPS is off'));
      });

      test('should have proper toString format', () {
        final exception = LocationServiceDisabledException('Location service disabled');

        expect(
          exception.toString(),
          equals('LocationServiceDisabledException: Location service disabled'),
        );
      });

      test('should handle empty message', () {
        final exception = LocationServiceDisabledException('');

        expect(exception.message, isEmpty);
        expect(exception.toString(), equals('LocationServiceDisabledException: '));
      });

      test('should handle special characters in message', () {
        final exception = LocationServiceDisabledException('Error: \$special chars!');

        expect(exception.message, equals('Error: \$special chars!'));
        expect(exception.toString(), contains('Error: \$special chars!'));
      });

      test('should be throwable and catchable', () {
        expect(
          () => throw LocationServiceDisabledException('Test error'),
          throwsA(isA<LocationServiceDisabledException>()),
        );
      });

      test('should preserve message when thrown and caught', () {
        const testMessage = 'Service disabled for testing';

        try {
          throw LocationServiceDisabledException(testMessage);
        } catch (e) {
          expect(e, isA<LocationServiceDisabledException>());
          expect((e as LocationServiceDisabledException).message, equals(testMessage));
        }
      });
    });

    group('LocationPermissionDeniedException', () {
      test('should create exception with message', () {
        final exception = LocationPermissionDeniedException('Permission denied by user');

        expect(exception, isA<Exception>());
        expect(exception.message, equals('Permission denied by user'));
      });

      test('should have proper toString format', () {
        final exception = LocationPermissionDeniedException('Permission de localisation refusée');

        expect(
          exception.toString(),
          equals('LocationPermissionDeniedException: Permission de localisation refusée'),
        );
      });

      test('should handle empty message', () {
        final exception = LocationPermissionDeniedException('');

        expect(exception.message, isEmpty);
        expect(exception.toString(), equals('LocationPermissionDeniedException: '));
      });

      test('should handle unicode characters', () {
        final exception = LocationPermissionDeniedException('拒绝访问位置');

        expect(exception.message, equals('拒绝访问位置'));
        expect(exception.toString(), contains('拒绝访问位置'));
      });

      test('should be throwable and catchable', () {
        expect(
          () => throw LocationPermissionDeniedException('Test denied'),
          throwsA(isA<LocationPermissionDeniedException>()),
        );
      });

      test('should preserve message when thrown and caught', () {
        const testMessage = 'User denied permission';

        try {
          throw LocationPermissionDeniedException(testMessage);
        } catch (e) {
          expect(e, isA<LocationPermissionDeniedException>());
          expect((e as LocationPermissionDeniedException).message, equals(testMessage));
        }
      });

      test('should be different from other exception types', () {
        final exception = LocationPermissionDeniedException('Test');

        expect(exception, isNot(isA<LocationServiceDisabledException>()));
        expect(exception, isNot(isA<LocationPermissionDeniedForeverException>()));
      });
    });

    group('LocationPermissionDeniedForeverException', () {
      test('should create exception with message', () {
        final exception = LocationPermissionDeniedForeverException(
          'Permission permanently denied',
        );

        expect(exception, isA<Exception>());
        expect(exception.message, equals('Permission permanently denied'));
      });

      test('should have proper toString format', () {
        final exception = LocationPermissionDeniedForeverException(
          'Permission de localisation refusée définitivement',
        );

        expect(
          exception.toString(),
          equals('LocationPermissionDeniedForeverException: Permission de localisation refusée définitivement'),
        );
      });

      test('should handle empty message', () {
        final exception = LocationPermissionDeniedForeverException('');

        expect(exception.message, isEmpty);
        expect(exception.toString(), equals('LocationPermissionDeniedForeverException: '));
      });

      test('should handle long messages', () {
        final longMessage = 'This is a very long error message ' * 10;
        final exception = LocationPermissionDeniedForeverException(longMessage);

        expect(exception.message, equals(longMessage));
        expect(exception.toString(), contains(longMessage));
      });

      test('should be throwable and catchable', () {
        expect(
          () => throw LocationPermissionDeniedForeverException('Forever denied'),
          throwsA(isA<LocationPermissionDeniedForeverException>()),
        );
      });

      test('should preserve message when thrown and caught', () {
        const testMessage = 'Permanently denied by user';

        try {
          throw LocationPermissionDeniedForeverException(testMessage);
        } catch (e) {
          expect(e, isA<LocationPermissionDeniedForeverException>());
          expect((e as LocationPermissionDeniedForeverException).message, equals(testMessage));
        }
      });

      test('should be different from other exception types', () {
        final exception = LocationPermissionDeniedForeverException('Test');

        expect(exception, isNot(isA<LocationServiceDisabledException>()));
        expect(exception, isNot(isA<LocationPermissionDeniedException>()));
      });
    });

    group('Exception Type Differentiation', () {
      test('should distinguish between all three exception types', () {
        final serviceException = LocationServiceDisabledException('Service');
        final deniedExceptionException = LocationPermissionDeniedException('Denied');
        final foreverException = LocationPermissionDeniedForeverException('Forever');

        // Each should have unique toString
        expect(serviceException.toString(), isNot(equals(deniedExceptionException.toString())));
        expect(serviceException.toString(), isNot(equals(foreverException.toString())));
        expect(deniedExceptionException.toString(), isNot(equals(foreverException.toString())));

        // Each should be catchable by its specific type
        try {
          throw serviceException;
        } catch (e) {
          expect(e, isA<LocationServiceDisabledException>());
          expect(e, isNot(isA<LocationPermissionDeniedException>()));
          expect(e, isNot(isA<LocationPermissionDeniedForeverException>()));
        }
      });

      test('should all implement Exception interface', () {
        final serviceException = LocationServiceDisabledException('Test');
        final deniedException = LocationPermissionDeniedException('Test');
        final foreverException = LocationPermissionDeniedForeverException('Test');

        expect(serviceException, isA<Exception>());
        expect(deniedException, isA<Exception>());
        expect(foreverException, isA<Exception>());
      });
    });

    group('Static Methods - Integration Notes', () {
      // Note: checkAndRequestPermissions, hasPermissions, and isServiceEnabled
      // are static methods that depend on the native Geolocator plugin.
      // These cannot be easily unit tested without mocking the platform channel.
      //
      // Coverage Strategy:
      // - Exception classes: 100% covered (tested above)
      // - Static methods: Tested via integration tests where Geolocator plugin is available
      //
      // For comprehensive testing of static methods, use:
      // 1. Integration tests on real devices/emulators
      // 2. Widget tests with mocked platform channels
      // 3. Manual testing with different permission states

      test('service class should exist and be accessible', () {
        // Verify the class can be referenced (acts as a namespace for static methods)
        expect(LocationPermissionService, isNotNull);
      });
    });
  });
}
