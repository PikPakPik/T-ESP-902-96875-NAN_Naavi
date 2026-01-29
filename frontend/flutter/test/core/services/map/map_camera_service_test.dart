import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/services/map/map_camera_service.dart';

class MockMapboxMap extends Mock implements MapboxMap {}

void main() {
  late MockMapboxMap mockMapboxMap;

  setUpAll(() {
    registerFallbackValue(
      CameraOptions(center: Point(coordinates: Position(0, 0))),
    );
    registerFallbackValue(MapAnimationOptions(duration: 1000));
    registerFallbackValue(MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0));
  });

  setUp(() {
    mockMapboxMap = MockMapboxMap();
    when(() => mockMapboxMap.flyTo(any(), any())).thenAnswer((_) async {});
  });

  group('MapCameraService', () {
    group('moveToPosition', () {
      test('should call flyTo with correct parameters', () async {
        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 47.2173,
          longitude: -1.5534,
          zoom: 15.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final point = options.center as Point;
                final pos = point.coordinates;
                return pos.lng == -1.5534 &&
                    pos.lat == 47.2173 &&
                    options.zoom == 15.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should use custom zoom level', () async {
        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          zoom: 12.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.zoom == 12.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should apply custom padding', () async {
        final customPadding = MbxEdgeInsets(
          top: 100,
          left: 50,
          bottom: 200,
          right: 50,
        );

        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 47.2173,
          longitude: -1.5534,
          padding: customPadding,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.padding == customPadding;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should apply pitch and bearing', () async {
        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 47.2173,
          longitude: -1.5534,
          pitch: 45.0,
          bearing: 90.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.pitch == 45.0 && options.bearing == 90.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should handle errors gracefully', () async {
        when(
          () => mockMapboxMap.flyTo(any(), any()),
        ).thenThrow(Exception('Camera error'));

        // Act - should not throw
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 47.2173,
          longitude: -1.5534,
        );

        // Assert - verify it tried to call
        verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
      });
    });

    group('moveToGeoPosition', () {
      test(
        'should convert geolocator position and call moveToPosition',
        () async {
          final position = gl.Position(
            latitude: 47.2173,
            longitude: -1.5534,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 50.0,
            altitudeAccuracy: 5.0,
            heading: 0.0,
            headingAccuracy: 5.0,
            speed: 0.0,
            speedAccuracy: 1.0,
          );

          // Act
          await MapCameraService.moveToGeoPosition(
            mockMapboxMap,
            position: position,
            zoom: 16.0,
          );

          // Assert
          verify(
            () => mockMapboxMap.flyTo(
              any(
                that: predicate<CameraOptions>((options) {
                  final point = options.center as Point;
                  final pos = point.coordinates;
                  return pos.lng == -1.5534 &&
                      pos.lat == 47.2173 &&
                      options.zoom == 16.0;
                }),
              ),
              any(),
            ),
          ).called(1);
        },
      );
    });

    group('fitToBounds', () {
      test('should handle empty coordinates', () async {
        // Act
        await MapCameraService.fitToBounds(mockMapboxMap, coordinates: []);

        // Assert
        verifyNever(() => mockMapboxMap.flyTo(any(), any()));
      });

      test('should calculate bounds and fit camera', () async {
        final coordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
          [-1.5600, 47.2150],
        ];

        // Act
        await MapCameraService.fitToBounds(
          mockMapboxMap,
          coordinates: coordinates,
        );

        // Assert
        verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
      });

      test('should apply custom padding', () async {
        final coordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];
        final customPadding = MbxEdgeInsets(
          top: 50,
          left: 25,
          bottom: 300,
          right: 25,
        );

        // Act
        await MapCameraService.fitToBounds(
          mockMapboxMap,
          coordinates: coordinates,
          padding: customPadding,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.padding == customPadding;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should apply pitch and bearing', () async {
        final coordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        // Act
        await MapCameraService.fitToBounds(
          mockMapboxMap,
          coordinates: coordinates,
          pitch: 60.0,
          bearing: 180.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.pitch == 60.0 && options.bearing == 180.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should handle errors gracefully', () async {
        when(
          () => mockMapboxMap.flyTo(any(), any()),
        ).thenThrow(Exception('Bounds error'));

        final coordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        // Act - should not throw
        await MapCameraService.fitToBounds(
          mockMapboxMap,
          coordinates: coordinates,
        );

        // Assert
        verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
      });
    });

    group('fitToRoute', () {
      gl.Position createPosition(double lat, double lon, double alt) {
        return gl.Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: alt,
          altitudeAccuracy: 5.0,
          heading: 0.0,
          headingAccuracy: 5.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        );
      }

      test('should handle empty segments', () async {
        // Act
        await MapCameraService.fitToRoute(mockMapboxMap, segments: []);

        // Assert
        verifyNever(() => mockMapboxMap.flyTo(any(), any()));
      });

      test('should handle segments with no points', () async {
        // Act
        await MapCameraService.fitToRoute(mockMapboxMap, segments: [[]]);

        // Assert
        verifyNever(() => mockMapboxMap.flyTo(any(), any()));
      });

      test('should fit camera to route segments', () async {
        final segments = [
          [
            createPosition(47.2173, -1.5534, 50),
            createPosition(47.2200, -1.5500, 55),
          ],
          [
            createPosition(47.2150, -1.5600, 45),
            createPosition(47.2180, -1.5550, 48),
          ],
        ];

        // Act
        await MapCameraService.fitToRoute(mockMapboxMap, segments: segments);

        // Assert
        verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
      });

      test('should apply custom padding for route', () async {
        final segments = [
          [
            createPosition(47.2173, -1.5534, 50),
            createPosition(47.2200, -1.5500, 55),
          ],
        ];
        final customPadding = MbxEdgeInsets(
          top: 150,
          left: 75,
          bottom: 500,
          right: 75,
        );

        // Act
        await MapCameraService.fitToRoute(
          mockMapboxMap,
          segments: segments,
          padding: customPadding,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.padding == customPadding;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should use default bottom padding for bottom sheet', () async {
        final segments = [
          [
            createPosition(47.2173, -1.5534, 50),
            createPosition(47.2200, -1.5500, 55),
          ],
        ];

        // Act
        await MapCameraService.fitToRoute(mockMapboxMap, segments: segments);

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final padding = options.padding;
                return padding?.bottom ==
                    400; // Default padding for bottom sheet
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should handle single segment with multiple points', () async {
        final segments = [
          [
            createPosition(47.2173, -1.5534, 50),
            createPosition(47.2200, -1.5500, 55),
            createPosition(47.2180, -1.5550, 52),
          ],
        ];

        // Act
        await MapCameraService.fitToRoute(mockMapboxMap, segments: segments);

        // Assert
        verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
      });

      test('should handle multiple segments', () async {
        final segments = [
          [createPosition(47.2173, -1.5534, 50)],
          [createPosition(47.2200, -1.5500, 55)],
          [createPosition(47.2180, -1.5550, 52)],
        ];

        // Act
        await MapCameraService.fitToRoute(mockMapboxMap, segments: segments);

        // Assert
        verify(() => mockMapboxMap.flyTo(any(), any())).called(1);
      });
    });

    group('moveToPoi', () {
      test('should move camera to POI with default padding', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final point = options.center as Point;
                final pos = point.coordinates;
                return pos.lat == 48.8566 && pos.lng == 2.3522;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should use default bottom padding of 450', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final padding = options.padding;
                return padding?.bottom == 450.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should use custom bottom padding', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          bottomPadding: 600.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final padding = options.padding;
                return padding?.bottom == 600.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should use default zoom of 15', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.zoom == 15.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should use custom zoom', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          zoom: 18.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.zoom == 18.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should use default duration of 600ms', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(),
            any(
              that: predicate<MapAnimationOptions>((options) {
                return options.duration == 600;
              }),
            ),
          ),
        ).called(1);
      });

      test('should use custom duration', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          duration: 2000,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(),
            any(
              that: predicate<MapAnimationOptions>((options) {
                return options.duration == 2000;
              }),
            ),
          ),
        ).called(1);
      });

      test('should set correct padding for modal visibility', () async {
        // Act
        await MapCameraService.moveToPoi(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
        );

        // Assert - verify top, left, right padding
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final padding = options.padding;
                return padding?.top == 100.0 &&
                    padding?.left == 20.0 &&
                    padding?.right == 20.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });
    });

    group('Error Handling', () {
      test('moveToPosition should catch and suppress errors', () async {
        when(
          () => mockMapboxMap.flyTo(any(), any()),
        ).thenThrow(Exception('Map error'));

        // Should not throw
        await expectLater(
          MapCameraService.moveToPosition(
            mockMapboxMap,
            latitude: 48.8566,
            longitude: 2.3522,
          ),
          completes,
        );
      });

      test('fitToBounds should catch and suppress errors', () async {
        when(
          () => mockMapboxMap.flyTo(any(), any()),
        ).thenThrow(Exception('Bounds error'));

        final coordinates = [
          [-1.5534, 47.2173],
          [-1.5500, 47.2200],
        ];

        // Should not throw
        await expectLater(
          MapCameraService.fitToBounds(mockMapboxMap, coordinates: coordinates),
          completes,
        );
      });

      test('fitToRoute should catch and suppress errors', () async {
        when(
          () => mockMapboxMap.flyTo(any(), any()),
        ).thenThrow(Exception('Route error'));

        final segments = [
          [
            gl.Position(
              latitude: 47.2173,
              longitude: -1.5534,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 50.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ],
        ];

        // Should not throw
        await expectLater(
          MapCameraService.fitToRoute(mockMapboxMap, segments: segments),
          completes,
        );
      });

      test('moveToPoi should catch and suppress errors', () async {
        when(
          () => mockMapboxMap.flyTo(any(), any()),
        ).thenThrow(Exception('POI error'));

        // Should not throw
        await expectLater(
          MapCameraService.moveToPoi(
            mockMapboxMap,
            latitude: 48.8566,
            longitude: 2.3522,
          ),
          completes,
        );
      });
    });

    group('Edge Cases', () {
      test('should handle zero coordinates', () async {
        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 0.0,
          longitude: 0.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final point = options.center as Point;
                final pos = point.coordinates;
                return pos.lat == 0.0 && pos.lng == 0.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should handle negative coordinates', () async {
        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: -33.8688,
          longitude: 151.2093,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                final point = options.center as Point;
                final pos = point.coordinates;
                return pos.lat == -33.8688 && pos.lng == 151.2093;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should handle extreme zoom levels', () async {
        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          zoom: 22.0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(
              that: predicate<CameraOptions>((options) {
                return options.zoom == 22.0;
              }),
            ),
            any(),
          ),
        ).called(1);
      });

      test('should handle zero duration', () async {
        // Act
        await MapCameraService.moveToPosition(
          mockMapboxMap,
          latitude: 48.8566,
          longitude: 2.3522,
          duration: 0,
        );

        // Assert
        verify(
          () => mockMapboxMap.flyTo(
            any(),
            any(
              that: predicate<MapAnimationOptions>((options) {
                return options.duration == 0;
              }),
            ),
          ),
        ).called(1);
      });
    });
  });
}
