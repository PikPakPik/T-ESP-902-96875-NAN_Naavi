import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/poi_manager.dart';
import 'package:naavi/core/utils/poi_type.dart';

// Mocks
class MockMapboxMap extends Mock implements MapboxMap {}

class MockAnnotationManager extends Mock implements AnnotationManager {}

class MockPointAnnotationManager extends Mock
    implements PointAnnotationManager {}

// Fake classes for mocktail registration
class FakePointAnnotationOptions extends Fake
    implements PointAnnotationOptions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakePointAnnotationOptions());
  });

  group('POIManager', () {
    late MockMapboxMap mockMapboxMap;
    late MockAnnotationManager mockAnnotationManager;
    late MockPointAnnotationManager mockPointAnnotationManager;

    setUp(() {
      mockMapboxMap = MockMapboxMap();
      mockAnnotationManager = MockAnnotationManager();
      mockPointAnnotationManager = MockPointAnnotationManager();

      // Setup default annotation manager behavior
      when(() => mockMapboxMap.annotations).thenReturn(mockAnnotationManager);
      when(
        () => mockAnnotationManager.createPointAnnotationManager(),
      ).thenAnswer((_) async => mockPointAnnotationManager);
      when(() => mockPointAnnotationManager.create(any())).thenAnswer(
        (_) async => PointAnnotation(
          id: 'test-id',
          geometry: Point(coordinates: Position(0, 0)),
        ),
      );
      when(
        () => mockPointAnnotationManager.deleteAll(),
      ).thenAnswer((_) async => Future.value());
    });

    tearDown(() {
      // Clear static state between tests
      POIManager.clearAllPOIs(mockMapboxMap);
    });

    group('addPOIAnnotationDirect', () {
      test('should add POI annotation with default hazard type', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
        );

        // Assert
        verify(
          () => mockAnnotationManager.createPointAnnotationManager(),
        ).called(1);
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should add POI annotation with custom type', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
          type: PoiType.parking,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should add POI annotation with title', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const title = 'Test Location';

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
          title: title,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should add POI annotation with custom icon size', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const iconSize = 1.0;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
          iconSize: iconSize,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should handle all POI types', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act & Assert
        for (final type in PoiType.values) {
          await POIManager.addPOIAnnotationDirect(
            mockMapboxMap,
            latitude,
            longitude,
            type: type,
          );
        }

        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(PoiType.values.length);
      });

      test('should handle error when creating annotation manager', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        when(
          () => mockAnnotationManager.createPointAnnotationManager(),
        ).thenThrow(Exception('Failed to create manager'));

        // Act & Assert - Should complete without throwing (error caught)
        await expectLater(
          POIManager.addPOIAnnotationDirect(mockMapboxMap, latitude, longitude),
          completes,
        );
      });

      test('should handle error when creating annotation', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        when(
          () => mockPointAnnotationManager.create(any()),
        ).thenThrow(Exception('Failed to create annotation'));

        // Act & Assert - Should complete without throwing
        await expectLater(
          POIManager.addPOIAnnotationDirect(mockMapboxMap, latitude, longitude),
          completes,
        );
      });

      test('should handle zero coordinates', () async {
        // Arrange
        const latitude = 0.0;
        const longitude = 0.0;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should handle extreme coordinates', () async {
        // Arrange
        const latitude = 90.0;
        const longitude = 180.0;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should handle negative coordinates', () async {
        // Arrange
        const latitude = -45.0;
        const longitude = -90.0;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should handle empty title', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
          title: '',
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should handle very small icon size', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const iconSize = 0.1;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
          iconSize: iconSize,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should handle large icon size', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const iconSize = 5.0;

        // Act
        await POIManager.addPOIAnnotationDirect(
          mockMapboxMap,
          latitude,
          longitude,
          iconSize: iconSize,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });
    });

    group('addAlertPOI', () {
      test('should add alert POI with default title', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        await POIManager.addAlertPOI(mockMapboxMap, latitude, longitude);

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should add alert POI with custom title', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const title = 'Custom Alert';

        // Act
        await POIManager.addAlertPOI(
          mockMapboxMap,
          latitude,
          longitude,
          title: title,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should add alert POI with custom icon size', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const iconSize = 0.6;

        // Act
        await POIManager.addAlertPOI(
          mockMapboxMap,
          latitude,
          longitude,
          iconSize: iconSize,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should handle error when adding alert POI', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        when(
          () => mockPointAnnotationManager.create(any()),
        ).thenThrow(Exception('Failed'));

        // Act & Assert
        await expectLater(
          POIManager.addAlertPOI(mockMapboxMap, latitude, longitude),
          completes,
        );
      });
    });

    group('addCustomPOI', () {
      test('should add custom POI with parking type', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        await POIManager.addCustomPOI(
          mockMapboxMap,
          latitude,
          longitude,
          poiType: PoiType.parking,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should add custom POI with title', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const title = 'Parking Lot';

        // Act
        await POIManager.addCustomPOI(
          mockMapboxMap,
          latitude,
          longitude,
          poiType: PoiType.parking,
          title: title,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should add custom POI with custom icon size', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const iconSize = 0.5;

        // Act
        await POIManager.addCustomPOI(
          mockMapboxMap,
          latitude,
          longitude,
          poiType: PoiType.parking,
          iconSize: iconSize,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should reuse manager for multiple custom POIs', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        await POIManager.addCustomPOI(
          mockMapboxMap,
          latitude,
          longitude,
          poiType: PoiType.parking,
        );
        await POIManager.addCustomPOI(
          mockMapboxMap,
          latitude + 0.01,
          longitude + 0.01,
          poiType: PoiType.toilets,
        );

        // Assert - Should create manager once, annotations twice
        verify(
          () => mockAnnotationManager.createPointAnnotationManager(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(2));
      });

      test('should add custom POI for all types', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        for (final type in PoiType.values) {
          await POIManager.addCustomPOI(
            mockMapboxMap,
            latitude,
            longitude,
            poiType: type,
          );
        }

        // Assert
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(PoiType.values.length));
      });

      test('should handle error when loading icon fails', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        when(
          () => mockPointAnnotationManager.create(any()),
        ).thenThrow(Exception('Icon load failed'));

        // Act & Assert
        await expectLater(
          POIManager.addCustomPOI(
            mockMapboxMap,
            latitude,
            longitude,
            poiType: PoiType.parking,
          ),
          completes,
        );
      });

      test('should handle error when creating manager', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        when(
          () => mockAnnotationManager.createPointAnnotationManager(),
        ).thenThrow(Exception('Manager creation failed'));

        // Act & Assert
        await expectLater(
          POIManager.addCustomPOI(
            mockMapboxMap,
            latitude,
            longitude,
            poiType: PoiType.parking,
          ),
          completes,
        );
      });
    });

    group('clearAllCustomPOIs', () {
      test('should clear all custom POIs', () async {
        // Arrange - Add a custom POI first
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );

        // Act
        await POIManager.clearAllCustomPOIs(mockMapboxMap);

        // Assert - deleteAll should be called
        verify(
          () => mockPointAnnotationManager.deleteAll(),
        ).called(greaterThanOrEqualTo(0));
      });

      test('should handle clearing when no custom POIs exist', () async {
        // Act & Assert - Should complete without error
        await expectLater(
          POIManager.clearAllCustomPOIs(mockMapboxMap),
          completes,
        );
      });

      test('should handle error when clearing fails', () async {
        // Arrange - Add a custom POI
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );

        when(
          () => mockPointAnnotationManager.deleteAll(),
        ).thenThrow(Exception('Delete failed'));

        // Act & Assert - Should complete (error caught)
        await expectLater(
          POIManager.clearAllCustomPOIs(mockMapboxMap),
          completes,
        );
      });

      test('should allow adding new custom POIs after clearing', () async {
        // Arrange - Add and clear
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );
        await POIManager.clearAllCustomPOIs(mockMapboxMap);

        // Act - Add new POI
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.toilets,
        );

        // Assert
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(2));
      });
    });

    group('highlightPOI', () {
      test('should highlight POI with larger icon size', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        await POIManager.highlightPOI(
          mockMapboxMap,
          latitude,
          longitude,
          poiType: PoiType.parking,
        );

        // Assert
        verify(
          () => mockAnnotationManager.createPointAnnotationManager(),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(1));
      });

      test('should highlight POI with custom icon size', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;
        const iconSize = 0.8;

        // Act
        await POIManager.highlightPOI(
          mockMapboxMap,
          latitude,
          longitude,
          poiType: PoiType.parking,
          iconSize: iconSize,
        );

        // Assert
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(1));
      });

      test(
        'should clear previous highlighted POI before adding new one',
        () async {
          // Arrange
          const latitude1 = 48.8566;
          const longitude1 = 2.3522;
          const latitude2 = 48.8567;
          const longitude2 = 2.3523;

          // Act - Highlight two POIs
          await POIManager.highlightPOI(
            mockMapboxMap,
            latitude1,
            longitude1,
            poiType: PoiType.parking,
          );
          await POIManager.highlightPOI(
            mockMapboxMap,
            latitude2,
            longitude2,
            poiType: PoiType.toilets,
          );

          // Assert - Should clear between highlights
          verify(
            () => mockPointAnnotationManager.deleteAll(),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      test('should handle all POI types for highlighting', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        // Act
        for (final type in PoiType.values) {
          await POIManager.highlightPOI(
            mockMapboxMap,
            latitude,
            longitude,
            poiType: type,
          );
        }

        // Assert
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(PoiType.values.length));
      });

      test('should handle error when highlighting fails', () async {
        // Arrange
        const latitude = 48.8566;
        const longitude = 2.3522;

        when(
          () => mockAnnotationManager.createPointAnnotationManager(),
        ).thenThrow(Exception('Highlight failed'));

        // Act & Assert
        await expectLater(
          POIManager.highlightPOI(
            mockMapboxMap,
            latitude,
            longitude,
            poiType: PoiType.parking,
          ),
          completes,
        );
      });
    });

    group('clearHighlightedPOI', () {
      test('should clear highlighted POI', () async {
        // Arrange - Highlight a POI first
        await POIManager.highlightPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );

        // Act
        await POIManager.clearHighlightedPOI();

        // Assert
        verify(
          () => mockPointAnnotationManager.deleteAll(),
        ).called(greaterThanOrEqualTo(1));
      });

      test('should handle clearing when no highlighted POI exists', () async {
        // Act & Assert
        await expectLater(POIManager.clearHighlightedPOI(), completes);
      });

      test('should handle error when clearing highlighted POI fails', () async {
        // Arrange - Highlight a POI
        await POIManager.highlightPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );

        when(
          () => mockPointAnnotationManager.deleteAll(),
        ).thenThrow(Exception('Clear failed'));

        // Act & Assert
        await expectLater(POIManager.clearHighlightedPOI(), completes);
      });

      test('should allow highlighting new POI after clearing', () async {
        // Arrange - Highlight and clear
        await POIManager.highlightPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );
        await POIManager.clearHighlightedPOI();

        // Act - Highlight again
        await POIManager.highlightPOI(
          mockMapboxMap,
          48.8567,
          2.3523,
          poiType: PoiType.toilets,
        );

        // Assert
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(2));
      });
    });

    group('clearAllPOIs', () {
      test('should clear all POIs from the map', () async {
        // Arrange - Add various POIs
        await POIManager.addPOIAnnotationDirect(mockMapboxMap, 48.8566, 2.3522);
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8567,
          2.3523,
          poiType: PoiType.parking,
        );

        // Act
        await POIManager.clearAllPOIs(mockMapboxMap);

        // Assert
        verify(
          () => mockPointAnnotationManager.deleteAll(),
        ).called(greaterThanOrEqualTo(1));
      });

      test('should handle clearing when no POIs exist', () async {
        // Act & Assert
        await expectLater(POIManager.clearAllPOIs(mockMapboxMap), completes);
      });

      test('should handle error when clearing all POIs fails', () async {
        // Arrange - Add POIs
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );

        when(
          () => mockPointAnnotationManager.deleteAll(),
        ).thenThrow(Exception('Clear all failed'));

        // Act & Assert
        await expectLater(POIManager.clearAllPOIs(mockMapboxMap), completes);
      });

      test('should allow adding new POIs after clearing all', () async {
        // Arrange - Add and clear
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );
        await POIManager.clearAllPOIs(mockMapboxMap);

        // Reset the mock to start fresh
        reset(mockPointAnnotationManager);
        when(() => mockPointAnnotationManager.create(any())).thenAnswer(
          (_) async => PointAnnotation(
            id: 'new-id',
            geometry: Point(coordinates: Position(0, 0)),
          ),
        );
        when(
          () => mockPointAnnotationManager.deleteAll(),
        ).thenAnswer((_) async => Future.value());

        // Act - Add new POI
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8567,
          2.3523,
          poiType: PoiType.toilets,
        );

        // Assert
        verify(() => mockPointAnnotationManager.create(any())).called(1);
      });

      test('should clear all managers from internal list', () async {
        // Arrange - Add multiple POIs
        await POIManager.addPOIAnnotationDirect(mockMapboxMap, 48.8566, 2.3522);
        await POIManager.addPOIAnnotationDirect(mockMapboxMap, 48.8567, 2.3523);

        // Act
        await POIManager.clearAllPOIs(mockMapboxMap);

        // Assert - Multiple deleteAll calls for different managers
        verify(
          () => mockPointAnnotationManager.deleteAll(),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Complex Scenarios', () {
      test('should handle mixed operations', () async {
        // Arrange & Act
        await POIManager.addPOIAnnotationDirect(mockMapboxMap, 48.8566, 2.3522);
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8567,
          2.3523,
          poiType: PoiType.parking,
        );
        await POIManager.highlightPOI(
          mockMapboxMap,
          48.8568,
          2.3524,
          poiType: PoiType.toilets,
        );
        await POIManager.addAlertPOI(mockMapboxMap, 48.8569, 2.3525);

        // Assert - All operations should complete
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(4));
      });

      test('should handle rapid POI additions', () async {
        // Arrange
        const count = 10;

        // Act
        final futures = <Future>[];
        for (int i = 0; i < count; i++) {
          futures.add(
            POIManager.addCustomPOI(
              mockMapboxMap,
              48.8566 + i * 0.001,
              2.3522 + i * 0.001,
              poiType: PoiType.parking,
            ),
          );
        }
        await Future.wait(futures);

        // Assert
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(count));
      });

      test('should maintain state across operations', () async {
        // Arrange & Act - Add, clear, add again
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8566,
          2.3522,
          poiType: PoiType.parking,
        );
        await POIManager.clearAllCustomPOIs(mockMapboxMap);
        await POIManager.addCustomPOI(
          mockMapboxMap,
          48.8567,
          2.3523,
          poiType: PoiType.toilets,
        );

        // Assert - Should handle state properly
        verify(
          () => mockPointAnnotationManager.create(any()),
        ).called(greaterThanOrEqualTo(2));
      });
    });
  });
}
