import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:geobase/geobase.dart' as geobase;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/route_service.dart';
import 'package:naavi/data/models/route_data.dart';

// Mock classes
class MockMapboxMap extends Mock implements MapboxMap {}

class MockStyleManager extends Mock implements StyleManager {}

class MockRouteInfo extends Mock implements RouteInfo {}

// Fake classes for mocktail
class FakeGeoJsonSource extends Fake implements GeoJsonSource {}

class FakeLineLayer extends Fake implements LineLayer {}

class FakeSymbolLayer extends Fake implements SymbolLayer {}

class FakeCameraOptions extends Fake implements CameraOptions {}

class FakeMapAnimationOptions extends Fake implements MapAnimationOptions {}

class FakeCoordinateBounds extends Fake implements CoordinateBounds {}

class FakeMbxEdgeInsets extends Fake implements MbxEdgeInsets {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeGeoJsonSource());
    registerFallbackValue(FakeLineLayer());
    registerFallbackValue(FakeSymbolLayer());
    registerFallbackValue(FakeCameraOptions());
    registerFallbackValue(FakeMapAnimationOptions());
    registerFallbackValue(FakeCoordinateBounds());
    registerFallbackValue(FakeMbxEdgeInsets());
  });

  group('RouteService', () {
    late RouteService routeService;

    setUp(() {
      routeService = RouteService();
    });

    group('initializeRoutes', () {
      test('should initialize routes from WKB strings with default names', () {
        // Simple LineString WKB: one line with 2 points
        // Format: byte order (01) + type (02000000) + numPoints (02000000) + points
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';

        final wkbStrings = [wkbHex];

        final routes = routeService.initializeRoutes(wkbStrings, null, null);

        expect(routes.length, 1);
        expect(routes[0].id, 'route_0');
        expect(routes[0].name, 'Route 1');
        expect(routes[0].lineString, isA<geobase.LineString>());
        expect(routes[0].color, const Color.fromRGBO(50, 73, 67, 1));
      });

      test('should initialize routes with custom names', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final wkbStrings = [wkbHex];
        final routeNames = ['Mountain Trail'];

        final routes = routeService.initializeRoutes(
          wkbStrings,
          routeNames,
          null,
        );

        expect(routes.length, 1);
        expect(routes[0].name, 'Mountain Trail');
      });

      test('should initialize multiple routes', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final wkbStrings = [wkbHex, wkbHex, wkbHex];

        final routes = routeService.initializeRoutes(wkbStrings, null, null);

        expect(routes.length, 3);
        expect(routes[0].name, 'Route 1');
        expect(routes[1].name, 'Route 2');
        expect(routes[2].name, 'Route 3');
      });

      test('should initialize routes with full route data', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final wkbStrings = [wkbHex];
        final routesData = [
          {
            'wkb': wkbHex,
            'name': 'Trail A',
            'distance': '5.2',
            'difficulty': 'moderate',
          },
        ];

        final routes = routeService.initializeRoutes(
          wkbStrings,
          null,
          routesData,
        );

        expect(routes.length, 1);
        expect(routes[0].hikeLine.info['name'], 'Trail A');
        expect(routes[0].hikeLine.info['distance'], '5.2');
      });

      test('should handle empty WKB list', () {
        final routes = routeService.initializeRoutes([], null, null);

        expect(routes, isEmpty);
      });

      test('should handle mismatched names length', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final wkbStrings = [wkbHex, wkbHex, wkbHex];
        final routeNames = ['Trail 1']; // Only one name for three routes

        final routes = routeService.initializeRoutes(
          wkbStrings,
          routeNames,
          null,
        );

        expect(routes.length, 3);
        expect(routes[0].name, 'Trail 1');
        expect(routes[1].name, 'Route 2'); // Falls back to default
        expect(routes[2].name, 'Route 3');
      });
    });

    // Note: addRouteToMap tests skipped due to complex Mapbox API mocking challenges
    // These methods are integration-tested through widget tests instead

    // Note: showAndHighlightRoute tests skipped due to complex Mapbox API mocking challenges
    // These methods are integration-tested through widget tests instead

    group('fitCameraToSingleRoute', () {
      late MockMapboxMap mockMapboxMap;

      setUp(() {
        mockMapboxMap = MockMapboxMap();
        when(
          () => mockMapboxMap.cameraForCoordinateBounds(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => CameraOptions());
        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => {});
      });

      test('should fit camera to route bounds', () async {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes([wkbHex], null, null);

        await routeService.fitCameraToSingleRoute(mockMapboxMap, routes[0]);

        verify(
          () => mockMapboxMap.cameraForCoordinateBounds(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).called(1);
        verify(() => mockMapboxMap.easeTo(any(), any())).called(1);
      });

      test('should handle errors gracefully', () async {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes([wkbHex], null, null);

        when(
          () => mockMapboxMap.cameraForCoordinateBounds(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenThrow(Exception('Camera error'));

        // Should not throw
        await expectLater(
          routeService.fitCameraToSingleRoute(mockMapboxMap, routes[0]),
          completes,
        );
      });
    });

    group('calculateBounds', () {
      test('should calculate bounds for single route', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes([wkbHex], null, null);

        final bounds = routeService.calculateBounds(routes);

        expect(bounds.minLat, closeTo(0.0, 0.01));
        expect(bounds.maxLat, closeTo(10.0, 0.01));
        expect(bounds.minLon, closeTo(0.0, 0.01));
        expect(bounds.maxLon, closeTo(10.0, 0.01));
      });

      test('should calculate bounds for multiple routes', () {
        final wkbHex1 =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final wkbHex2 =
            '010200000002000000000000000000344000000000000034400000000000003e400000000000003e40';

        final routes = routeService.initializeRoutes(
          [wkbHex1, wkbHex2],
          null,
          null,
        );

        final bounds = routeService.calculateBounds(routes);

        expect(bounds.minLat, lessThanOrEqualTo(bounds.maxLat));
        expect(bounds.minLon, lessThanOrEqualTo(bounds.maxLon));
      });

      test('should throw error when no valid coordinates found', () {
        // Empty route
        final routes = <RouteInfo>[];

        expect(() => routeService.calculateBounds(routes), throwsException);
      });

      test('should calculate correct spans', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes([wkbHex], null, null);

        final bounds = routeService.calculateBounds(routes);

        expect(bounds.latSpan, greaterThan(0));
        expect(bounds.lonSpan, greaterThan(0));
        expect(bounds.maxSpan, greaterThan(0));
      });

      test('should calculate correct center position', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes([wkbHex], null, null);

        final bounds = routeService.calculateBounds(routes);
        final center = bounds.center;

        expect(center.latitude, closeTo(5.0, 0.5));
        expect(center.longitude, closeTo(5.0, 0.5));
      });
    });

    group('fitCameraToRoutes', () {
      late MockMapboxMap mockMapboxMap;

      setUp(() {
        mockMapboxMap = MockMapboxMap();
        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => {});
      });

      test('should fit camera to multiple routes', () async {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes(
          [wkbHex, wkbHex],
          null,
          null,
        );

        await routeService.fitCameraToRoutes(mockMapboxMap, routes);

        verify(() => mockMapboxMap.easeTo(any(), any())).called(1);
      });

      test('should not fit camera for empty routes', () async {
        await routeService.fitCameraToRoutes(mockMapboxMap, []);

        verifyNever(() => mockMapboxMap.easeTo(any(), any()));
      });

      test('should handle errors gracefully', () async {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes([wkbHex], null, null);

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenThrow(Exception('Camera error'));

        // Should not throw
        await expectLater(
          routeService.fitCameraToRoutes(mockMapboxMap, routes),
          completes,
        );
      });
    });

    group('setupRouteInteractions', () {
      late MockMapboxMap mockMapboxMap;

      setUp(() {
        mockMapboxMap = MockMapboxMap();
      });

      test('should setup interactions for all routes', () async {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes(
          [wkbHex, wkbHex, wkbHex],
          null,
          null,
        );

        // Act - Just verify the method completes without error
        await expectLater(
          routeService.setupRouteInteractions(
            mockMapboxMap,
            routes,
            (index) {},
          ),
          completes,
        );
      });

      test('should setup interactions for empty routes list', () async {
        // Act - Just verify the method completes without error
        await expectLater(
          routeService.setupRouteInteractions(mockMapboxMap, [], (index) {}),
          completes,
        );
      });
    });

    group('cleanupRouteInteractions', () {
      late MockMapboxMap mockMapboxMap;

      setUp(() {
        mockMapboxMap = MockMapboxMap();
        when(() => mockMapboxMap.removeInteraction(any())).thenAnswer((_) {});
      });

      test('should cleanup interactions for all routes', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes(
          [wkbHex, wkbHex],
          null,
          null,
        );

        routeService.cleanupRouteInteractions(mockMapboxMap, routes);

        verify(
          () => mockMapboxMap.removeInteraction('point-interaction-0'),
        ).called(1);
        verify(
          () => mockMapboxMap.removeInteraction('point-interaction-1'),
        ).called(1);
      });

      test('should handle cleanup errors gracefully', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final routes = routeService.initializeRoutes([wkbHex], null, null);

        when(
          () => mockMapboxMap.removeInteraction(any()),
        ).thenThrow(Exception('Remove error'));

        // Should not throw
        expect(
          () => routeService.cleanupRouteInteractions(mockMapboxMap, routes),
          returnsNormally,
        );
      });

      test('should cleanup empty routes list', () {
        routeService.cleanupRouteInteractions(mockMapboxMap, []);

        verifyNever(() => mockMapboxMap.removeInteraction(any()));
      });
    });

    group('Edge Cases', () {
      test('should handle very large coordinate values', () {
        // LineString with large coordinates
        final wkbHex =
            '010200000002000000'
            '713d0ad7a3704640'
            '6666666666e64140' // Large coords
            '295c8fc2f5a84640'
            '9a9999999989c140';

        final routes = routeService.initializeRoutes([wkbHex], null, null);

        expect(routes.length, 1);
        expect(routes[0].lineString.chain.positionCount, greaterThan(0));
      });

      test('should handle routes with single point', () {
        // LineString with 1 point
        final wkbHex =
            '010200000001000000'
            '0000000000000000'
            '0000000000000000';

        final routes = routeService.initializeRoutes([wkbHex], null, null);

        expect(routes.length, 1);
      });

      test('should handle null route names gracefully', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final wkbStrings = [wkbHex];

        final routes = routeService.initializeRoutes(wkbStrings, null, null);

        expect(routes[0].name, isNotEmpty);
      });

      test('should handle empty routesData list', () {
        final wkbHex =
            '0102000000020000000000000000000000000000000000000000000000000024400000000000002440';
        final wkbStrings = [wkbHex];

        final routes = routeService.initializeRoutes(wkbStrings, null, []);

        expect(routes.length, 1);
      });
    });
  });
}
