import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/services/map/global_route_service.dart';
import 'package:naavi/core/services/map/route_management_service.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockRouteManagementService extends Mock implements RouteManagementService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlobalRouteService', () {
    late GlobalRouteService globalRouteService;
    late MockRouteManagementService mockRouteService;

    setUp(() {
      // Get the singleton instance
      globalRouteService = GlobalRouteService();
      mockRouteService = MockRouteManagementService();
    });

    tearDown(() {
      // Unregister any service after each test to prevent test pollution
      globalRouteService.unregisterRouteService();
    });

    group('Singleton Pattern', () {
      test('should return the same instance on multiple calls', () {
        final instance1 = GlobalRouteService();
        final instance2 = GlobalRouteService();

        expect(identical(instance1, instance2), isTrue);
        expect(instance1, same(instance2));
      });

      test('should maintain state across multiple getInstance calls', () {
        final instance1 = GlobalRouteService();
        instance1.registerRouteService(mockRouteService);

        final instance2 = GlobalRouteService();

        // Both instances should share the same state
        expect(instance1, same(instance2));
      });
    });

    group('registerRouteService', () {
      test('should register a route service successfully', () {
        // Act
        globalRouteService.registerRouteService(mockRouteService);

        // Assert - verify by trying to hide current route
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        globalRouteService.hideCurrentRoute();

        // Verify the service was registered and used
        verify(() => mockRouteService.hideCurrentRoute()).called(1);
      });

      test('should replace previously registered service', () {
        final firstService = MockRouteManagementService();
        final secondService = MockRouteManagementService();

        when(() => firstService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());
        when(() => secondService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        // Register first service
        globalRouteService.registerRouteService(firstService);

        // Replace with second service
        globalRouteService.registerRouteService(secondService);

        // Call hideCurrentRoute
        globalRouteService.hideCurrentRoute();

        // Only second service should be called
        verifyNever(() => firstService.hideCurrentRoute());
        verify(() => secondService.hideCurrentRoute()).called(1);
      });

      test('should allow multiple registrations', () {
        globalRouteService.registerRouteService(mockRouteService);
        globalRouteService.registerRouteService(mockRouteService);
        globalRouteService.registerRouteService(mockRouteService);

        // Should not throw any errors
        expect(() => globalRouteService.registerRouteService(mockRouteService),
            returnsNormally);
      });
    });

    group('unregisterRouteService', () {
      test('should unregister the current route service', () {
        // Arrange
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        globalRouteService.registerRouteService(mockRouteService);

        // Act
        globalRouteService.unregisterRouteService();

        // Assert - hideCurrentRoute should not be called after unregistering
        globalRouteService.hideCurrentRoute();

        verifyNever(() => mockRouteService.hideCurrentRoute());
      });

      test('should handle unregister when no service is registered', () {
        // Should not throw any errors
        expect(() => globalRouteService.unregisterRouteService(), returnsNormally);
      });

      test('should allow re-registration after unregister', () {
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        // Register, unregister, then register again
        globalRouteService.registerRouteService(mockRouteService);
        globalRouteService.unregisterRouteService();
        globalRouteService.registerRouteService(mockRouteService);

        globalRouteService.hideCurrentRoute();

        verify(() => mockRouteService.hideCurrentRoute()).called(1);
      });

      test('should set service to null', () async {
        globalRouteService.registerRouteService(mockRouteService);
        globalRouteService.unregisterRouteService();

        // Calling hideCurrentRoute should complete without error
        await expectLater(
          globalRouteService.hideCurrentRoute(),
          completes,
        );
      });
    });

    group('hideCurrentRoute', () {
      test('should call hideCurrentRoute on registered service', () async {
        // Arrange
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        globalRouteService.registerRouteService(mockRouteService);

        // Act
        await globalRouteService.hideCurrentRoute();

        // Assert
        verify(() => mockRouteService.hideCurrentRoute()).called(1);
      });

      test('should complete successfully when no service is registered', () async {
        // No service registered

        // Should complete without error
        await expectLater(
          globalRouteService.hideCurrentRoute(),
          completes,
        );
      });

      test('should not throw when service is null', () async {
        globalRouteService.unregisterRouteService();

        // Should complete without error
        await expectLater(
          globalRouteService.hideCurrentRoute(),
          completes,
        );
      });

      test('should propagate errors from route service', () async {
        when(() => mockRouteService.hideCurrentRoute())
            .thenThrow(Exception('Failed to hide route'));

        globalRouteService.registerRouteService(mockRouteService);

        // Should propagate the exception
        await expectLater(
          globalRouteService.hideCurrentRoute(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle async errors from route service', () async {
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => throw Exception('Async error'));

        globalRouteService.registerRouteService(mockRouteService);

        await expectLater(
          globalRouteService.hideCurrentRoute(),
          throwsA(isA<Exception>()),
        );
      });

      test('should be callable multiple times', () async {
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        globalRouteService.registerRouteService(mockRouteService);

        await globalRouteService.hideCurrentRoute();
        await globalRouteService.hideCurrentRoute();
        await globalRouteService.hideCurrentRoute();

        verify(() => mockRouteService.hideCurrentRoute()).called(3);
      });
    });

    group('Integration Scenarios', () {
      test('should handle register, hide, unregister workflow', () async {
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        // Register
        globalRouteService.registerRouteService(mockRouteService);

        // Hide route
        await globalRouteService.hideCurrentRoute();

        // Unregister
        globalRouteService.unregisterRouteService();

        // Try to hide again (should do nothing)
        await globalRouteService.hideCurrentRoute();

        // Verify only called once (during the first hide, not after unregister)
        verify(() => mockRouteService.hideCurrentRoute()).called(1);
      });

      test('should handle service replacement during operation', () async {
        final service1 = MockRouteManagementService();
        final service2 = MockRouteManagementService();

        when(() => service1.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());
        when(() => service2.hideCurrentRoute())
            .thenAnswer((_) async => Future.value());

        // Register first service and use it
        globalRouteService.registerRouteService(service1);
        await globalRouteService.hideCurrentRoute();

        // Replace with second service
        globalRouteService.registerRouteService(service2);
        await globalRouteService.hideCurrentRoute();

        // Verify each service was called once
        verify(() => service1.hideCurrentRoute()).called(1);
        verify(() => service2.hideCurrentRoute()).called(1);
      });

      test('should maintain singleton across async operations', () async {
        when(() => mockRouteService.hideCurrentRoute())
            .thenAnswer((_) async => Future.delayed(Duration(milliseconds: 10)));

        final instance1 = GlobalRouteService();
        instance1.registerRouteService(mockRouteService);

        // Start async operation
        final future1 = instance1.hideCurrentRoute();

        // Get another instance during async operation
        final instance2 = GlobalRouteService();

        // Both should be the same
        expect(instance1, same(instance2));

        await future1;
        verify(() => mockRouteService.hideCurrentRoute()).called(1);
      });
    });
  });
}
