import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/services/map/hike_selection_service.dart';

// Mocks
class MockMapboxMap extends Mock implements MapboxMap {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMapboxMap mockMapboxMap;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(
      CameraOptions(center: Point(coordinates: Position(0, 0))),
    );
    registerFallbackValue(MapAnimationOptions(duration: 1000));
    registerFallbackValue(
      CoordinateBounds(
        southwest: Point(coordinates: Position(0, 0)),
        northeast: Point(coordinates: Position(1, 1)),
        infiniteBounds: false,
      ),
    );
    registerFallbackValue(MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0));
  });

  setUp(() {
    mockMapboxMap = MockMapboxMap();

    // Mock setCamera for padding reset (called at the start of fitCameraToHike)
    when(() => mockMapboxMap.setCamera(any()))
        .thenAnswer((_) async => Future.value());
  });

  group('HikeSelectionService', () {
    group('fitCameraToHike', () {
      test('should handle empty coordinates', () async {
        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          [],
        );

        // Assert - should return early without calling map methods
        verifyNever(() => mockMapboxMap.setCamera(any()));
        verifyNever(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            ));
        verifyNever(() => mockMapboxMap.easeTo(any(), any()));
      });

      test('should calculate bounds and fit camera for single point', () async {
        // Arrange
        final coordinates = [
          [2.3522, 48.8566], // Paris
        ];

        final cameraOptions = CameraOptions(
          center: Point(coordinates: Position(2.3522, 48.8566)),
          zoom: 15.0,
        );

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => cameraOptions);

        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
        );

        // Assert
        // Verify that padding is reset to 0 before calculating bounds
        verify(() => mockMapboxMap.setCamera(
              any(
                that: predicate<CameraOptions>((options) {
                  final padding = options.padding;
                  return padding?.top == 0 &&
                      padding?.left == 0 &&
                      padding?.bottom == 0 &&
                      padding?.right == 0;
                }),
              ),
            )).called(1);
        verify(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).called(1);
        verify(() => mockMapboxMap.easeTo(cameraOptions, any())).called(1);
      });

      test('should calculate bounds correctly for multiple points', () async {
        // Arrange
        final coordinates = [
          [-1.5534, 47.2173], // Nantes
          [2.3522, 48.8566], // Paris
          [5.3698, 43.2965], // Marseille
        ];

        final cameraOptions = CameraOptions(
          center: Point(coordinates: Position(2.0, 46.0)),
          zoom: 12.0,
        );

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => cameraOptions);

        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
        );

        // Assert - verify bounds were calculated with correct min/max
        verify(() => mockMapboxMap.cameraForCoordinateBounds(
              any(
                that: predicate<CoordinateBounds>((bounds) {
                  final sw = bounds.southwest.coordinates;
                  final ne = bounds.northeast.coordinates;
                  // Min lng: -1.5534, Max lng: 5.3698
                  // Min lat: 43.2965, Max lat: 48.8566
                  return sw.lng == -1.5534 &&
                      sw.lat == 43.2965 &&
                      ne.lng == 5.3698 &&
                      ne.lat == 48.8566;
                }),
              ),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).called(1);
      });

      test('should use default padding values', () async {
        // Arrange
        final coordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        final cameraOptions = CameraOptions(
          center: Point(coordinates: Position(-1.5517, 47.21865)),
          zoom: 14.0,
        );

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => cameraOptions);

        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
        );

        // Assert - check default padding
        verify(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(
                that: predicate<MbxEdgeInsets>((padding) {
                  return padding.top == 100 &&
                      padding.bottom == 450 &&
                      padding.left == 50 &&
                      padding.right == 50;
                }),
              ),
              any(),
              any(),
              any(),
              any(),
            )).called(1);
      });

      test('should use custom padding values', () async {
        // Arrange
        final coordinates = [
          [-1.5534, 47.2173],
        ];

        final cameraOptions = CameraOptions(
          center: Point(coordinates: Position(-1.5534, 47.2173)),
          zoom: 15.0,
        );

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => cameraOptions);

        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
          bottomPadding: 500,
          topPadding: 150,
          horizontalPadding: 75,
        );

        // Assert
        verify(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(
                that: predicate<MbxEdgeInsets>((padding) {
                  return padding.top == 150 &&
                      padding.bottom == 500 &&
                      padding.left == 75 &&
                      padding.right == 75;
                }),
              ),
              any(),
              any(),
              any(),
              any(),
            )).called(1);
      });

      test('should force bearing to 0 (north orientation)', () async {
        // Arrange
        final coordinates = [
          [-1.5534, 47.2173],
        ];

        final cameraOptions = CameraOptions(
          center: Point(coordinates: Position(-1.5534, 47.2173)),
          zoom: 15.0,
        );

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => cameraOptions);

        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
        );

        // Assert - bearing should be 0.0
        verify(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              0.0, // bearing
              any(),
              any(),
              any(),
            )).called(1);
      });

      test('should force pitch to 0 (top-down view)', () async {
        // Arrange
        final coordinates = [
          [-1.5534, 47.2173],
        ];

        final cameraOptions = CameraOptions(
          center: Point(coordinates: Position(-1.5534, 47.2173)),
          zoom: 15.0,
        );

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => cameraOptions);

        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
        );

        // Assert - pitch should be 0.0
        verify(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              0.0, // pitch
              any(),
              any(),
            )).called(1);
      });

      test('should use custom animation duration', () async {
        // Arrange
        final coordinates = [
          [-1.5534, 47.2173],
        ];

        final cameraOptions = CameraOptions(
          center: Point(coordinates: Position(-1.5534, 47.2173)),
          zoom: 15.0,
        );

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => cameraOptions);

        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
          animationDuration: 2000,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(
              any(),
              any(
                that: predicate<MapAnimationOptions>(
                  (options) => options.duration == 2000,
                ),
              ),
            )).called(1);
      });

      test('should handle errors gracefully', () async {
        // Arrange
        final coordinates = [
          [-1.5534, 47.2173],
        ];

        when(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenThrow(Exception('Camera calculation error'));

        // Act - should not throw
        await HikeSelectionService.fitCameraToHike(
          mockMapboxMap,
          coordinates,
        );

        // Assert - should have attempted the operation
        verify(() => mockMapboxMap.cameraForCoordinateBounds(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
            )).called(1);
      });
    });

    group('centerOnPoint', () {
      test('should center camera on specified point', () async {
        // Arrange
        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.centerOnPoint(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(
              any(
                that: predicate<CameraOptions>((options) {
                  final point = options.center as Point;
                  final pos = point.coordinates;
                  return pos.lat == 48.8566 && pos.lng == 2.3522;
                }),
              ),
              any(),
            )).called(1);
      });

      test('should use default zoom level of 15.0', () async {
        // Arrange
        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.centerOnPoint(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(
              any(
                that: predicate<CameraOptions>((options) => options.zoom == 15.0),
              ),
              any(),
            )).called(1);
      });

      test('should use custom zoom level', () async {
        // Arrange
        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.centerOnPoint(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          zoom: 18.0,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(
              any(
                that: predicate<CameraOptions>((options) => options.zoom == 18.0),
              ),
              any(),
            )).called(1);
      });

      test('should set bearing to 0 (north)', () async {
        // Arrange
        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.centerOnPoint(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(
              any(
                that: predicate<CameraOptions>((options) => options.bearing == 0.0),
              ),
              any(),
            )).called(1);
      });

      test('should set pitch to 0 (top-down)', () async {
        // Arrange
        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.centerOnPoint(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(
              any(
                that: predicate<CameraOptions>((options) => options.pitch == 0.0),
              ),
              any(),
            )).called(1);
      });

      test('should use custom animation duration', () async {
        // Arrange
        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await HikeSelectionService.centerOnPoint(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          animationDuration: 500,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(
              any(),
              any(
                that: predicate<MapAnimationOptions>(
                  (options) => options.duration == 500,
                ),
              ),
            )).called(1);
      });

      test('should handle errors gracefully', () async {
        // Arrange
        when(() => mockMapboxMap.easeTo(any(), any()))
            .thenThrow(Exception('Camera error'));

        // Act - should not throw
        await HikeSelectionService.centerOnPoint(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(any(), any())).called(1);
      });
    });

    group('calculateDistanceToHikeStart', () {
      gl.Position createPosition(double lat, double lon) {
        return gl.Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      test('should return null when currentPosition is null', () {
        // Arrange
        final hikeInfo = {
          'start_point': {'latitude': 48.8566, 'longitude': 2.3522}
        };

        // Act
        final distance = HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: null,
          hikeInfo: hikeInfo,
        );

        // Assert
        expect(distance, isNull);
      });

      test('should return null when hikeInfo is null', () {
        // Arrange
        final position = createPosition(48.8566, 2.3522);

        // Act
        final distance = HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: position,
          hikeInfo: null,
        );

        // Assert
        expect(distance, isNull);
      });

      test('should return null when start_point is missing', () {
        // Arrange
        final position = createPosition(48.8566, 2.3522);
        final hikeInfo = <String, dynamic>{};

        // Act
        final distance = HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: position,
          hikeInfo: hikeInfo,
        );

        // Assert
        expect(distance, isNull);
      });

      test('should return null when start_point latitude is missing', () {
        // Arrange
        final position = createPosition(48.8566, 2.3522);
        final hikeInfo = {
          'start_point': {'longitude': 2.3522}
        };

        // Act
        final distance = HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: position,
          hikeInfo: hikeInfo,
        );

        // Assert
        expect(distance, isNull);
      });

      test('should return null when start_point longitude is missing', () {
        // Arrange
        final position = createPosition(48.8566, 2.3522);
        final hikeInfo = {
          'start_point': {'latitude': 48.8566}
        };

        // Act
        final distance = HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: position,
          hikeInfo: hikeInfo,
        );

        // Assert
        expect(distance, isNull);
      });

      test('should calculate distance when at same location', () {
        // Arrange
        final position = createPosition(48.8566, 2.3522);
        final hikeInfo = {
          'start_point': {'latitude': 48.8566, 'longitude': 2.3522}
        };

        // Act
        final distance = HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: position,
          hikeInfo: hikeInfo,
        );

        // Assert
        expect(distance, isNotNull);
        expect(distance, lessThan(0.001)); // Very close to 0 km
      });

      test('should calculate distance for different locations', () {
        // Arrange
        final position = createPosition(48.8566, 2.3522); // Paris
        final hikeInfo = {
          'start_point': {'latitude': 47.2173, 'longitude': -1.5534} // Nantes
        };

        // Act
        final distance = HikeSelectionService.calculateDistanceToHikeStart(
          currentPosition: position,
          hikeInfo: hikeInfo,
        );

        // Assert
        expect(distance, isNotNull);
        expect(distance!, greaterThan(300)); // ~340 km between Paris and Nantes
        expect(distance, lessThan(400));
      });
    });

    group('extractStartPoint', () {
      test('should extract start point successfully', () {
        // Arrange
        final hikeInfo = {
          'start_point': {'latitude': 48.8566, 'longitude': 2.3522}
        };

        // Act
        final startPoint = HikeSelectionService.extractStartPoint(hikeInfo);

        // Assert
        expect(startPoint, isNotNull);
        expect(startPoint!.lat, equals(48.8566));
        expect(startPoint.lon, equals(2.3522));
      });

      test('should return null when start_point is missing', () {
        // Arrange
        final hikeInfo = <String, dynamic>{};

        // Act
        final startPoint = HikeSelectionService.extractStartPoint(hikeInfo);

        // Assert
        expect(startPoint, isNull);
      });

      test('should return null when latitude is missing', () {
        // Arrange
        final hikeInfo = {
          'start_point': {'longitude': 2.3522}
        };

        // Act
        final startPoint = HikeSelectionService.extractStartPoint(hikeInfo);

        // Assert
        expect(startPoint, isNull);
      });

      test('should return null when longitude is missing', () {
        // Arrange
        final hikeInfo = {
          'start_point': {'latitude': 48.8566}
        };

        // Act
        final startPoint = HikeSelectionService.extractStartPoint(hikeInfo);

        // Assert
        expect(startPoint, isNull);
      });

      test('should return null when start_point is null', () {
        // Arrange
        final hikeInfo = {'start_point': null};

        // Act
        final startPoint = HikeSelectionService.extractStartPoint(hikeInfo);

        // Assert
        expect(startPoint, isNull);
      });

      test('should handle negative coordinates', () {
        // Arrange
        final hikeInfo = {
          'start_point': {'latitude': -33.8688, 'longitude': 151.2093} // Sydney
        };

        // Act
        final startPoint = HikeSelectionService.extractStartPoint(hikeInfo);

        // Assert
        expect(startPoint, isNotNull);
        expect(startPoint!.lat, equals(-33.8688));
        expect(startPoint.lon, equals(151.2093));
      });
    });

    group('extractRouteCoordinates', () {
      test('should extract coordinates from allRoutes using hikeIndex', () {
        // Arrange
        final hikeInfo = {'hikeIndex': 1};
        final allRoutes = [
          {
            'coordinates': [
              [2.3522, 48.8566],
              [2.3500, 48.8570]
            ]
          },
          {
            'coordinates': [
              [-1.5534, 47.2173],
              [-1.5500, 47.2200]
            ]
          },
        ];

        // Act
        final coords = HikeSelectionService.extractRouteCoordinates(
          hikeInfo: hikeInfo,
          allRoutes: allRoutes,
        );

        // Assert
        expect(coords, isNotNull);
        expect(coords!.length, equals(2));
        expect(coords[0], equals([-1.5534, 47.2173]));
        expect(coords[1], equals([-1.5500, 47.2200]));
      });

      test('should extract coordinates from allRoutes using routeIndex', () {
        // Arrange
        final hikeInfo = {'routeIndex': 0};
        final allRoutes = [
          {
            'coordinates': [
              [2.3522, 48.8566]
            ]
          },
        ];

        // Act
        final coords = HikeSelectionService.extractRouteCoordinates(
          hikeInfo: hikeInfo,
          allRoutes: allRoutes,
        );

        // Assert
        expect(coords, isNotNull);
        expect(coords!.length, equals(1));
        expect(coords[0], equals([2.3522, 48.8566]));
      });

      test('should fall back to hikeInfo coordinates when allRoutes unavailable', () {
        // Arrange
        final hikeInfo = {
          'coordinates': [
            [2.3522, 48.8566],
            [2.3500, 48.8570]
          ]
        };

        // Act
        final coords = HikeSelectionService.extractRouteCoordinates(
          hikeInfo: hikeInfo,
          allRoutes: null,
        );

        // Assert
        expect(coords, isNotNull);
        expect(coords!.length, equals(2));
        expect(coords[0], equals([2.3522, 48.8566]));
      });

      test('should fall back to hikeInfo when index is out of bounds', () {
        // Arrange
        final hikeInfo = {
          'hikeIndex': 5,
          'coordinates': [
            [2.3522, 48.8566]
          ]
        };
        final allRoutes = [
          {
            'coordinates': [
              [-1.5534, 47.2173]
            ]
          },
        ];

        // Act
        final coords = HikeSelectionService.extractRouteCoordinates(
          hikeInfo: hikeInfo,
          allRoutes: allRoutes,
        );

        // Assert
        expect(coords, isNotNull);
        expect(coords![0], equals([2.3522, 48.8566]));
      });

      test('should return null when no coordinates available', () {
        // Arrange
        final hikeInfo = <String, dynamic>{};

        // Act
        final coords = HikeSelectionService.extractRouteCoordinates(
          hikeInfo: hikeInfo,
          allRoutes: null,
        );

        // Assert
        expect(coords, isNull);
      });

      test('should return null when coordinates are empty', () {
        // Arrange
        final hikeInfo = {'coordinates': []};

        // Act
        final coords = HikeSelectionService.extractRouteCoordinates(
          hikeInfo: hikeInfo,
          allRoutes: null,
        );

        // Assert
        expect(coords, isNull);
      });

      test('should convert numeric types to double', () {
        // Arrange - Using int instead of double
        final hikeInfo = {
          'coordinates': [
            [2, 48],
            [3, 49]
          ]
        };

        // Act
        final coords = HikeSelectionService.extractRouteCoordinates(
          hikeInfo: hikeInfo,
          allRoutes: null,
        );

        // Assert
        expect(coords, isNotNull);
        expect(coords![0], equals([2.0, 48.0]));
        expect(coords[0][0], isA<double>());
        expect(coords[0][1], isA<double>());
      });
    });

    group('isNearStartPoint', () {
      gl.Position createPosition(double lat, double lon) {
        return gl.Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      test('should return true when at exact same position', () {
        // Arrange
        final position = createPosition(48.8566, 2.3522);

        // Act
        final isNear = HikeSelectionService.isNearStartPoint(
          currentPosition: position,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        // Assert
        expect(isNear, isTrue);
      });

      test('should return true when within threshold (10m)', () {
        // Arrange - ~10 meters away
        final position = createPosition(48.85669, 2.35220);

        // Act
        final isNear = HikeSelectionService.isNearStartPoint(
          currentPosition: position,
          startLat: 48.8566,
          startLon: 2.3522,
          thresholdMeters: 20.0,
        );

        // Assert
        expect(isNear, isTrue);
      });

      test('should return false when outside threshold', () {
        // Arrange - ~1km away
        final position = createPosition(48.8666, 2.3522);

        // Act
        final isNear = HikeSelectionService.isNearStartPoint(
          currentPosition: position,
          startLat: 48.8566,
          startLon: 2.3522,
          thresholdMeters: 20.0,
        );

        // Assert
        expect(isNear, isFalse);
      });

      test('should use default threshold of 20 meters', () {
        // Arrange - exactly at start
        final position = createPosition(48.8566, 2.3522);

        // Act
        final isNear = HikeSelectionService.isNearStartPoint(
          currentPosition: position,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        // Assert
        expect(isNear, isTrue);
      });

      test('should use custom threshold', () {
        // Arrange - ~50 meters away
        final position = createPosition(48.85705, 2.3522);

        // Act - with 100m threshold
        final isNear = HikeSelectionService.isNearStartPoint(
          currentPosition: position,
          startLat: 48.8566,
          startLon: 2.3522,
          thresholdMeters: 100.0,
        );

        // Assert
        expect(isNear, isTrue);
      });

      test('should handle negative coordinates', () {
        // Arrange
        final position = createPosition(-33.8688, 151.2093);

        // Act
        final isNear = HikeSelectionService.isNearStartPoint(
          currentPosition: position,
          startLat: -33.8688,
          startLon: 151.2093,
          thresholdMeters: 20.0,
        );

        // Assert
        expect(isNear, isTrue);
      });

      test('should return false for very far distance', () {
        // Arrange - Paris vs Nantes (~340km)
        final position = createPosition(48.8566, 2.3522);

        // Act
        final isNear = HikeSelectionService.isNearStartPoint(
          currentPosition: position,
          startLat: 47.2173,
          startLon: -1.5534,
          thresholdMeters: 20.0,
        );

        // Assert
        expect(isNear, isFalse);
      });
    });
  });
}
