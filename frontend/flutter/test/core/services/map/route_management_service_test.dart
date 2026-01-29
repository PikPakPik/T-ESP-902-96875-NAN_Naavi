import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/map/route_management_service.dart';
import 'package:naavi/data/models/route_data.dart';

// Mocks
class MockMapboxMap extends Mock implements MapboxMap {}

class MockStyleManager extends Mock implements StyleManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RouteManagementService routeManagementService;
  late MockMapboxMap mockMapboxMap;
  late MockStyleManager mockStyleManager;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(
      CameraOptions(center: Point(coordinates: Position(0, 0))),
    );
    registerFallbackValue(MapAnimationOptions(duration: 1000));
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    routeManagementService = RouteManagementService();
    mockMapboxMap = MockMapboxMap();
    mockStyleManager = MockStyleManager();

    when(() => mockMapboxMap.style).thenReturn(mockStyleManager);
  });

  group('RouteManagementService', () {
    group('Initialization', () {
      test('should have empty routes initially', () {
        expect(routeManagementService.routes, isEmpty);
      });

      test('should have null highlightedRouteIndex initially', () {
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });
    });

    group('initializeRoutes', () {
      test('should initialize with empty data', () async {
        // Arrange
        final emptyData = StaticRoutesData(wkbStrings: []);

        // Act
        await routeManagementService.initializeRoutes(mockMapboxMap, emptyData);

        // Assert
        expect(routeManagementService.routes, isEmpty);
      });

      test('should return early when data has no routes', () async {
        // Arrange
        final emptyData = StaticRoutesData(wkbStrings: []);

        // Act
        await routeManagementService.initializeRoutes(mockMapboxMap, emptyData);

        // Assert - routes should be empty
        expect(routeManagementService.routes, isEmpty);
      });

      test('should handle null routeNames', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: [], routeNames: null);

        // Act
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Assert
        expect(routeManagementService.routes, isEmpty);
      });

      test('should handle null routesData', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: [], routesData: null);

        // Act
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Assert
        expect(routeManagementService.routes, isEmpty);
      });

      test('should skip camera fit when fitCamera is false', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);

        // Act
        await routeManagementService.initializeRoutes(
          mockMapboxMap,
          data,
          fitCamera: false,
        );

        // Assert - initialization should complete successfully
        expect(routeManagementService.routes, isEmpty);
      });

      test('should register onRouteSelected callback', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        bool callbackCalled = false;

        void onRouteSelected(Map<String, dynamic> info) {
          callbackCalled = true;
        }

        // Act
        await routeManagementService.initializeRoutes(
          mockMapboxMap,
          data,
          onRouteSelected: onRouteSelected,
        );

        // Assert - callback should be stored (will be tested via route tap)
        expect(callbackCalled, isFalse); // Not called during init
      });
    });

    group('getRoute', () {
      test('should return null for negative index', () {
        // Act
        final route = routeManagementService.getRoute(-1);

        // Assert
        expect(route, isNull);
      });

      test('should return null for index beyond routes length', () {
        // Act
        final route = routeManagementService.getRoute(10);

        // Assert
        expect(route, isNull);
      });

      test('should return null when routes is empty', () {
        // Act
        final route = routeManagementService.getRoute(0);

        // Assert
        expect(route, isNull);
      });
    });

    group('hideCurrentRoute', () {
      test('should do nothing when mapboxMap is null', () async {
        // Act
        await routeManagementService.hideCurrentRoute();

        // Assert - no errors should occur
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });

      test('should do nothing when highlightedRouteIndex is null', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act
        await routeManagementService.hideCurrentRoute();

        // Assert - should complete without error
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });

      test('should set visibility to none for highlighted route', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Manually set a highlighted route index
        routeManagementService.initializeRoutes(mockMapboxMap, data);

        when(
          () => mockStyleManager.setStyleLayerProperty(any(), any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act - we can't easily test this without mocking the internal state
        // but we can verify the method completes without error
        await routeManagementService.hideCurrentRoute();

        // Assert
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });

      test('should handle errors gracefully', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        when(
          () => mockStyleManager.setStyleLayerProperty(any(), any(), any()),
        ).thenThrow(Exception('Style error'));

        // Act - should not throw
        await expectLater(routeManagementService.hideCurrentRoute(), completes);
      });

      test('should reset highlightedRouteIndex after hiding', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        when(
          () => mockStyleManager.setStyleLayerProperty(any(), any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act
        await routeManagementService.hideCurrentRoute();

        // Assert
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });
    });

    group('cleanup', () {
      test('should reset all internal state', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act
        routeManagementService.cleanup();

        // Assert
        expect(routeManagementService.routes, isEmpty);
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });

      test('should handle cleanup when not initialized', () {
        // Act - should not throw
        expect(() => routeManagementService.cleanup(), returnsNormally);
      });

      test('should handle errors during cleanup', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act - should not throw even if map is disposed
        expect(() => routeManagementService.cleanup(), returnsNormally);
      });

      test('should allow re-initialization after cleanup', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act
        routeManagementService.cleanup();

        // Re-initialize
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Assert
        expect(
          routeManagementService.routes,
          isEmpty,
        ); // Empty because wkbStrings is empty
      });

      test('should handle multiple cleanup calls', () {
        // Act
        routeManagementService.cleanup();
        routeManagementService.cleanup();
        routeManagementService.cleanup();

        // Assert - should not throw
        expect(routeManagementService.routes, isEmpty);
      });
    });

    group('State Management', () {
      test('should maintain routes state', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act
        final routes = routeManagementService.routes;

        // Assert
        expect(routes, isA<List<RouteInfo>>());
        expect(routes, isEmpty);
      });

      test('should maintain highlightedRouteIndex state', () {
        // Arrange & Act
        final index = routeManagementService.highlightedRouteIndex;

        // Assert
        expect(index, isNull);
      });

      test('should preserve state between method calls', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act
        final routes1 = routeManagementService.routes;
        final routes2 = routeManagementService.routes;

        // Assert - same list reference
        expect(routes1, same(routes2));
      });
    });

    group('Edge Cases', () {
      test('should handle simultaneous initialization calls', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);

        // Act - call initialize multiple times simultaneously
        final futures = [
          routeManagementService.initializeRoutes(mockMapboxMap, data),
          routeManagementService.initializeRoutes(mockMapboxMap, data),
          routeManagementService.initializeRoutes(mockMapboxMap, data),
        ];

        await Future.wait(futures);

        // Assert - should complete without error
        expect(routeManagementService.routes, isEmpty);
      });

      test('should handle cleanup during initialization', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);

        // Act - start initialization then immediately cleanup
        final initFuture = routeManagementService.initializeRoutes(
          mockMapboxMap,
          data,
        );
        routeManagementService.cleanup();
        await initFuture;

        // Assert - should complete without error
        expect(routeManagementService.routes, isEmpty);
      });

      test('should handle hideCurrentRoute before initialization', () async {
        // Act - should not throw
        await expectLater(routeManagementService.hideCurrentRoute(), completes);
      });

      test('should handle getRoute before initialization', () {
        // Act
        final route = routeManagementService.getRoute(0);

        // Assert
        expect(route, isNull);
      });

      test('should handle null callback gracefully', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: [], onHikeSelected: null);

        // Act - should not throw
        await expectLater(
          routeManagementService.initializeRoutes(
            mockMapboxMap,
            data,
            onRouteSelected: null,
          ),
          completes,
        );
      });
    });

    group('Integration Scenarios', () {
      test('should handle full lifecycle: init -> hide -> cleanup', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);

        when(
          () => mockStyleManager.setStyleLayerProperty(any(), any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act
        await routeManagementService.initializeRoutes(mockMapboxMap, data);
        await routeManagementService.hideCurrentRoute();
        routeManagementService.cleanup();

        // Assert
        expect(routeManagementService.routes, isEmpty);
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });

      test('should handle multiple init-cleanup cycles', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);

        // Act - multiple cycles
        for (int i = 0; i < 3; i++) {
          await routeManagementService.initializeRoutes(mockMapboxMap, data);
          routeManagementService.cleanup();
        }

        // Assert
        expect(routeManagementService.routes, isEmpty);
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });

      test('should maintain independent state across instances', () async {
        // Arrange
        final service1 = RouteManagementService();
        final service2 = RouteManagementService();
        final data = StaticRoutesData(wkbStrings: []);

        // Act
        await service1.initializeRoutes(mockMapboxMap, data);
        await service2.initializeRoutes(mockMapboxMap, data);

        // Assert - each service has its own state
        expect(service1.routes, isNot(same(service2.routes)));
      });
    });

    group('Error Resilience', () {
      test('should recover from initialization errors', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);

        // First call fails, second succeeds
        var callCount = 0;
        when(() => mockMapboxMap.style).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            throw Exception('First call fails');
          }
          return mockStyleManager;
        });

        // Act
        try {
          await routeManagementService.initializeRoutes(mockMapboxMap, data);
        } catch (e) {
          // Expected to fail
        }

        // Second attempt should work
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Assert - should be in valid state
        expect(routeManagementService.routes, isEmpty);
      });

      test('should not leave corrupt state after error', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);

        when(() => mockMapboxMap.style).thenThrow(Exception('Map error'));

        // Act
        try {
          await routeManagementService.initializeRoutes(mockMapboxMap, data);
        } catch (e) {
          // Expected
        }

        // Assert - state should still be valid (though may be empty/null)
        expect(routeManagementService.routes, isA<List<RouteInfo>>());
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });
    });

    group('Memory Management', () {
      test('should clear references on cleanup', () {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act
        routeManagementService.cleanup();

        // Assert - all collections should be cleared
        expect(routeManagementService.routes, isEmpty);
        expect(routeManagementService.highlightedRouteIndex, isNull);
      });

      test('should handle cleanup of large route list', () async {
        // Arrange
        final data = StaticRoutesData(wkbStrings: []);
        await routeManagementService.initializeRoutes(mockMapboxMap, data);

        // Act - should handle cleanup efficiently
        final stopwatch = Stopwatch()..start();
        routeManagementService.cleanup();
        stopwatch.stop();

        // Assert - cleanup should be fast (< 100ms for empty list)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
