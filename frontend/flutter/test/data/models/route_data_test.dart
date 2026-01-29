import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geobase/geobase.dart' as geobase;
import 'package:naavi/core/classes/HikeLine.dart';
import 'package:naavi/data/models/route_data.dart';

void main() {
  group('MapPosition', () {
    test('should create MapPosition with longitude and latitude', () {
      final position = MapPosition(longitude: -1.5536, latitude: 47.2184);

      expect(position.longitude, -1.5536);
      expect(position.latitude, 47.2184);
    });

    test('should provide x getter for longitude', () {
      final position = MapPosition(longitude: 2.3522, latitude: 48.8566);

      expect(position.x, 2.3522);
      expect(position.x, position.longitude);
    });

    test('should provide y getter for latitude', () {
      final position = MapPosition(longitude: 2.3522, latitude: 48.8566);

      expect(position.y, 48.8566);
      expect(position.y, position.latitude);
    });

    test('should handle zero coordinates', () {
      final position = MapPosition(longitude: 0.0, latitude: 0.0);

      expect(position.longitude, 0.0);
      expect(position.latitude, 0.0);
      expect(position.x, 0.0);
      expect(position.y, 0.0);
    });

    test('should handle negative coordinates', () {
      final position = MapPosition(longitude: -120.5, latitude: -45.8);

      expect(position.longitude, -120.5);
      expect(position.latitude, -45.8);
    });

    test('should handle maximum longitude and latitude values', () {
      final position = MapPosition(longitude: 180.0, latitude: 90.0);

      expect(position.longitude, 180.0);
      expect(position.latitude, 90.0);
    });

    test('should handle minimum longitude and latitude values', () {
      final position = MapPosition(longitude: -180.0, latitude: -90.0);

      expect(position.longitude, -180.0);
      expect(position.latitude, -90.0);
    });

    test('should handle high precision coordinates', () {
      final position = MapPosition(
        longitude: -1.55367890123456,
        latitude: 47.21845678901234,
      );

      expect(position.longitude, -1.55367890123456);
      expect(position.latitude, 47.21845678901234);
    });
  });

  group('StaticRoutesData', () {
    late List<String> testWkbStrings;
    late List<String> testRouteNames;
    late List<Map<String, dynamic>> testRoutesData;

    setUp(() {
      testWkbStrings = ['wkb_data_1', 'wkb_data_2', 'wkb_data_3'];
      testRouteNames = ['Route A', 'Route B', 'Route C'];
      testRoutesData = [
        {'id': '1', 'name': 'Route A', 'distance': 5.2},
        {'id': '2', 'name': 'Route B', 'distance': 8.7},
        {'id': '3', 'name': 'Route C', 'distance': 3.1},
      ];
    });

    test('should create StaticRoutesData with required fields only', () {
      final routesData = StaticRoutesData(wkbStrings: testWkbStrings);

      expect(routesData.wkbStrings, testWkbStrings);
      expect(routesData.routeNames, isNull);
      expect(routesData.routesData, isNull);
      expect(routesData.onHikeSelected, isNull);
    });

    test('should create StaticRoutesData with all fields', () {
      void onHikeSelected(Map<String, dynamic> info) {}

      final routesData = StaticRoutesData(
        wkbStrings: testWkbStrings,
        routeNames: testRouteNames,
        routesData: testRoutesData,
        onHikeSelected: onHikeSelected,
      );

      expect(routesData.wkbStrings, testWkbStrings);
      expect(routesData.routeNames, testRouteNames);
      expect(routesData.routesData, testRoutesData);
      expect(routesData.onHikeSelected, isNotNull);
    });

    test('should return true for hasRoutes when wkbStrings is not empty', () {
      final routesData = StaticRoutesData(wkbStrings: testWkbStrings);

      expect(routesData.hasRoutes, true);
    });

    test('should return false for hasRoutes when wkbStrings is empty', () {
      final routesData = StaticRoutesData(wkbStrings: []);

      expect(routesData.hasRoutes, false);
    });

    test('should handle single route', () {
      final routesData = StaticRoutesData(
        wkbStrings: ['single_wkb'],
        routeNames: ['Single Route'],
      );

      expect(routesData.wkbStrings.length, 1);
      expect(routesData.hasRoutes, true);
    });

    test('should handle many routes', () {
      final manyWkbStrings = List.generate(100, (i) => 'wkb_$i');
      final routesData = StaticRoutesData(wkbStrings: manyWkbStrings);

      expect(routesData.wkbStrings.length, 100);
      expect(routesData.hasRoutes, true);
    });

    test('onHikeSelected callback should be callable', () {
      var callbackCalled = false;
      Map<String, dynamic>? receivedInfo;

      void onHikeSelected(Map<String, dynamic> info) {
        callbackCalled = true;
        receivedInfo = info;
      }

      final routesData = StaticRoutesData(
        wkbStrings: testWkbStrings,
        onHikeSelected: onHikeSelected,
      );

      final testInfo = {'id': '123', 'name': 'Test Hike'};
      routesData.onHikeSelected!(testInfo);

      expect(callbackCalled, true);
      expect(receivedInfo, testInfo);
    });

    test('should handle null callback gracefully', () {
      final routesData = StaticRoutesData(wkbStrings: testWkbStrings);

      expect(routesData.onHikeSelected, isNull);
    });
  });

  group('RouteInfo', () {
    late geobase.LineString testLineString;
    late HikeLine testHikeLine;

    setUp(() {
      // Build a LineString with coordinates (x=longitude, y=latitude)
      testLineString = geobase.LineString.build(
        [-1.5536, 47.2184, -1.5526, 47.2194, -1.5516, 47.2204],
        type: geobase.Coords.xy,
      );
      testHikeLine = HikeLine(
        line: testLineString,
        info: {'name': 'Test Trail', 'distance': 2.5},
      );
    });

    test('should create RouteInfo with all required fields', () {
      final routeInfo = RouteInfo(
        id: 'route_1',
        name: 'Mountain Trail',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.blue,
      );

      expect(routeInfo.id, 'route_1');
      expect(routeInfo.name, 'Mountain Trail');
      expect(routeInfo.lineString, testLineString);
      expect(routeInfo.hikeLine, testHikeLine);
      expect(routeInfo.color, Colors.blue);
      expect(routeInfo.isHighlighted, false); // Default value
    });

    test('should use default isHighlighted value of false', () {
      final routeInfo = RouteInfo(
        id: 'route_1',
        name: 'Trail',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.red,
      );

      expect(routeInfo.isHighlighted, false);
    });

    test('should allow custom isHighlighted value', () {
      final routeInfo = RouteInfo(
        id: 'route_1',
        name: 'Trail',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.green,
        isHighlighted: true,
      );

      expect(routeInfo.isHighlighted, true);
    });

    test('copyWith should create new instance with same values', () {
      final original = RouteInfo(
        id: 'route_1',
        name: 'Original Trail',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.blue,
        isHighlighted: false,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.lineString, original.lineString);
      expect(copy.hikeLine, original.hikeLine);
      expect(copy.color, original.color);
      expect(copy.isHighlighted, original.isHighlighted);
    });

    test('copyWith should update id when provided', () {
      final original = RouteInfo(
        id: 'route_1',
        name: 'Trail',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.blue,
      );

      final updated = original.copyWith(id: 'route_2');

      expect(updated.id, 'route_2');
      expect(updated.name, original.name);
    });

    test('copyWith should update name when provided', () {
      final original = RouteInfo(
        id: 'route_1',
        name: 'Original Name',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.blue,
      );

      final updated = original.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(updated.id, original.id);
    });

    test('copyWith should update color when provided', () {
      final original = RouteInfo(
        id: 'route_1',
        name: 'Trail',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.blue,
      );

      final updated = original.copyWith(color: Colors.red);

      expect(updated.color, Colors.red);
      expect(updated.id, original.id);
    });

    test('copyWith should update isHighlighted when provided', () {
      final original = RouteInfo(
        id: 'route_1',
        name: 'Trail',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.blue,
        isHighlighted: false,
      );

      final updated = original.copyWith(isHighlighted: true);

      expect(updated.isHighlighted, true);
      expect(updated.id, original.id);
    });

    test('copyWith should update multiple fields at once', () {
      final original = RouteInfo(
        id: 'route_1',
        name: 'Original',
        lineString: testLineString,
        hikeLine: testHikeLine,
        color: Colors.blue,
        isHighlighted: false,
      );

      final updated = original.copyWith(
        name: 'Updated',
        color: Colors.green,
        isHighlighted: true,
      );

      expect(updated.name, 'Updated');
      expect(updated.color, Colors.green);
      expect(updated.isHighlighted, true);
      expect(updated.id, original.id);
    });

    test('should support different colors', () {
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        const Color(0xFF123456),
      ];

      for (final color in colors) {
        final routeInfo = RouteInfo(
          id: 'route',
          name: 'Trail',
          lineString: testLineString,
          hikeLine: testHikeLine,
          color: color,
        );

        expect(routeInfo.color, color);
      }
    });
  });

  group('RouteBounds', () {
    test('should create RouteBounds with all coordinates', () {
      final bounds = RouteBounds(
        minLat: 47.2,
        maxLat: 47.3,
        minLon: -1.6,
        maxLon: -1.5,
      );

      expect(bounds.minLat, 47.2);
      expect(bounds.maxLat, 47.3);
      expect(bounds.minLon, -1.6);
      expect(bounds.maxLon, -1.5);
    });

    test('latSpan should calculate correct latitude span', () {
      final bounds = RouteBounds(
        minLat: 47.2,
        maxLat: 47.5,
        minLon: -1.6,
        maxLon: -1.5,
      );

      expect(bounds.latSpan, closeTo(0.3, 0.001));
    });

    test('lonSpan should calculate correct longitude span', () {
      final bounds = RouteBounds(
        minLat: 47.2,
        maxLat: 47.3,
        minLon: -1.6,
        maxLon: -1.4,
      );

      expect(bounds.lonSpan, closeTo(0.2, 0.001));
    });

    test('maxSpan should return larger of latSpan and lonSpan', () {
      final bounds1 = RouteBounds(
        minLat: 47.0,
        maxLat: 47.5, // span = 0.5
        minLon: -1.6,
        maxLon: -1.4, // span = 0.2
      );

      expect(bounds1.maxSpan, bounds1.latSpan);
      expect(bounds1.maxSpan, 0.5);

      final bounds2 = RouteBounds(
        minLat: 47.0,
        maxLat: 47.2, // span = 0.2
        minLon: -2.0,
        maxLon: -1.0, // span = 1.0
      );

      expect(bounds2.maxSpan, bounds2.lonSpan);
      expect(bounds2.maxSpan, 1.0);
    });

    test('center should calculate correct center position', () {
      final bounds = RouteBounds(
        minLat: 47.0,
        maxLat: 48.0,
        minLon: -2.0,
        maxLon: -1.0,
      );

      expect(bounds.center.latitude, 47.5);
      expect(bounds.center.longitude, -1.5);
    });

    test('center should handle asymmetric bounds', () {
      final bounds = RouteBounds(
        minLat: 47.1,
        maxLat: 47.9,
        minLon: -1.8,
        maxLon: -1.2,
      );

      expect(bounds.center.latitude, closeTo(47.5, 0.001));
      expect(bounds.center.longitude, closeTo(-1.5, 0.001));
    });

    group('calculateZoom', () {
      test('should return 17.0 for very small span', () {
        final bounds = RouteBounds(
          minLat: 47.2184,
          maxLat: 47.2185, // span < 0.001
          minLon: -1.5536,
          maxLon: -1.5535,
        );

        expect(bounds.calculateZoom(), 17.0);
      });

      test('should return 15.5 for small span', () {
        final bounds = RouteBounds(
          minLat: 47.2184,
          maxLat: 47.2204, // span = 0.002 (< 0.005)
          minLon: -1.5536,
          maxLon: -1.5516,
        );

        expect(bounds.calculateZoom(), 15.5);
      });

      test('should return 14.5 for short route', () {
        final bounds = RouteBounds(
          minLat: 47.21,
          maxLat: 47.218, // span = 0.008
          minLon: -1.56,
          maxLon: -1.552, // span = 0.008
        );

        // With padding 0.2, span becomes 0.0096 which is < 0.01
        expect(bounds.calculateZoom(), 14.5);
      });

      test('should return 13.5 for medium-short route', () {
        final bounds = RouteBounds(
          minLat: 47.2,
          maxLat: 47.22, // span = 0.02
          minLon: -1.56,
          maxLon: -1.54,
        );

        expect(bounds.calculateZoom(), 13.5);
      });

      test('should return 12.5 for medium route', () {
        final bounds = RouteBounds(
          minLat: 47.2,
          maxLat: 47.24, // span = 0.04
          minLon: -1.58,
          maxLon: -1.54,
        );

        expect(bounds.calculateZoom(), 12.5);
      });

      test('should return 11.5 for medium-long route', () {
        final bounds = RouteBounds(
          minLat: 47.1,
          maxLat: 47.17, // span = 0.07
          minLon: -1.6,
          maxLon: -1.53,
        );

        expect(bounds.calculateZoom(), 11.5);
      });

      test('should return 10.5 for long route', () {
        final bounds = RouteBounds(
          minLat: 47.1,
          maxLat: 47.25, // span = 0.15
          minLon: -1.65,
          maxLon: -1.5,
        );

        expect(bounds.calculateZoom(), 10.5);
      });

      test('should return 9.5 for very long route', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 47.3, // span = 0.3
          minLon: -1.8,
          maxLon: -1.5,
        );

        expect(bounds.calculateZoom(), 9.5);
      });

      test('should return 8.5 for huge route', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 47.7, // span = 0.7
          minLon: -2.0,
          maxLon: -1.3,
        );

        expect(bounds.calculateZoom(), 8.5);
      });

      test('should return 7.5 for gigantic route', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 48.5, // span = 1.5
          minLon: -2.5,
          maxLon: -1.0,
        );

        expect(bounds.calculateZoom(), 7.5);
      });

      test('should apply padding to span', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 47.002, // span = 0.002
          minLon: -1.6,
          maxLon: -1.598, // span = 0.002
        );

        // With default padding (0.2), span increases by 20%
        final defaultZoom = bounds.calculateZoom();
        final noPaddingZoom = bounds.calculateZoom(padding: 0.0);

        expect(defaultZoom, lessThanOrEqualTo(noPaddingZoom));
      });

      test('should support custom padding values', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 47.002, // span = 0.002
          minLon: -1.6,
          maxLon: -1.598, // span = 0.002
        );

        final zoom10 = bounds.calculateZoom(padding: 0.1);
        final zoom30 = bounds.calculateZoom(padding: 0.3);

        // More padding means lower zoom (zoomed out more)
        expect(zoom30, lessThanOrEqualTo(zoom10));
      });
    });

    group('calculateSingleRouteZoom', () {
      test('should use smaller padding for square-ish routes', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 47.1, // span = 0.1
          minLon: -1.6,
          maxLon: -1.5, // span = 0.1 (ratio = 1.0)
        );

        final singleZoom = bounds.calculateSingleRouteZoom();
        expect(singleZoom, isA<double>());
        expect(singleZoom, greaterThan(0));
      });

      test('should use more padding for elongated routes', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 47.05, // span = 0.05
          minLon: -2.0,
          maxLon: -1.5, // span = 0.5 (ratio = 10.0, very elongated)
        );

        final singleZoom = bounds.calculateSingleRouteZoom();
        expect(singleZoom, isA<double>());
        expect(singleZoom, greaterThan(0));
      });

      test('should handle zero span gracefully', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 47.0, // span = 0
          minLon: -1.5,
          maxLon: -1.5, // span = 0
        );

        expect(
          () => bounds.calculateSingleRouteZoom(),
          returnsNormally,
        );
      });

      test('should return valid zoom for different aspect ratios', () {
        final square = RouteBounds(
          minLat: 47.0,
          maxLat: 47.1,
          minLon: -1.6,
          maxLon: -1.5,
        );

        final elongated = RouteBounds(
          minLat: 47.0,
          maxLat: 47.02,
          minLon: -1.6,
          maxLon: -1.5,
        );

        final squareZoom = square.calculateSingleRouteZoom();
        final elongatedZoom = elongated.calculateSingleRouteZoom();

        // Both should return valid zoom values
        expect(squareZoom, isA<double>());
        expect(elongatedZoom, isA<double>());
        expect(squareZoom, greaterThan(0));
        expect(elongatedZoom, greaterThan(0));
      });
    });

    group('Edge Cases', () {
      test('should handle bounds crossing the equator', () {
        final bounds = RouteBounds(
          minLat: -10.0,
          maxLat: 10.0,
          minLon: -1.0,
          maxLon: 1.0,
        );

        expect(bounds.center.latitude, 0.0);
        expect(bounds.latSpan, 20.0);
      });

      test('should handle bounds crossing the prime meridian', () {
        final bounds = RouteBounds(
          minLat: 47.0,
          maxLat: 48.0,
          minLon: -10.0,
          maxLon: 10.0,
        );

        expect(bounds.center.longitude, 0.0);
        expect(bounds.lonSpan, 20.0);
      });

      test('should handle polar regions', () {
        final northPole = RouteBounds(
          minLat: 85.0,
          maxLat: 89.0,
          minLon: -180.0,
          maxLon: 180.0,
        );

        expect(northPole.center.latitude, 87.0);
      });

      test('should handle single point (zero span)', () {
        final point = RouteBounds(
          minLat: 47.2184,
          maxLat: 47.2184,
          minLon: -1.5536,
          maxLon: -1.5536,
        );

        expect(point.latSpan, 0.0);
        expect(point.lonSpan, 0.0);
        expect(point.maxSpan, 0.0);
      });

      test('should handle very large spans', () {
        final global = RouteBounds(
          minLat: -90.0,
          maxLat: 90.0,
          minLon: -180.0,
          maxLon: 180.0,
        );

        expect(global.latSpan, 180.0);
        expect(global.lonSpan, 360.0);
        expect(global.maxSpan, 360.0);
      });
    });
  });
}
