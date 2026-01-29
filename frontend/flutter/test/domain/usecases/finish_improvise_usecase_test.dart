import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/core/services/statistics/statistics_service.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/improvise_hike.dart';
import 'package:naavi/data/models/user_poi.dart';
import 'package:naavi/domain/usecases/finishImproviseUseCase.dart';

// Mocks
class MockStatisticsService extends Mock implements StatisticsService {}

class MockPoiService extends Mock implements PoiService {}

void main() {
  group('FinishImproviseUseCase', () {
    late FinishImproviseUseCase useCase;
    late MockStatisticsService mockStatisticsService;
    late MockPoiService mockPoiService;

    setUp(() {
      mockStatisticsService = MockStatisticsService();
      mockPoiService = MockPoiService();
      useCase = FinishImproviseUseCase(
        statisticsService: mockStatisticsService,
        poiService: mockPoiService,
      );
    });

    group('buildFinalHike', () {
      test('should build final hike with all statistics and POIs', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2194,
              longitude: -1.5526,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 110.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.5,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        final expectedFinalTime = Duration(hours: 1, minutes: 30);
        final expectedDistance = 5.25;
        final expectedElevationData = {
          'positive': 150.0,
          'negative': 50.0,
        };

        final expectedPois = [
          UserPOI(
            id: 'poi1',
            name: 'Test Parking',
            type: PoiType.parking,
            latitude: 47.2184,
            longitude: -1.5536,
            description: 'Test parking description',
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi2',
            name: 'Test Water',
            type: PoiType.water,
            latitude: 47.2194,
            longitude: -1.5526,
            description: 'Test water source',
            createdAt: DateTime.now(),
          ),
        ];

        final expectedPoiTypes = [PoiType.parking, PoiType.water];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(expectedFinalTime);
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(expectedDistance);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn(expectedElevationData);
        when(() => mockPoiService.getPoiTypesImproviseHike())
            .thenReturn(expectedPoiTypes);
        when(() => mockPoiService.getHikePois()).thenReturn(expectedPois);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result, isA<ImproviseHike>());
        expect(result.distance, expectedDistance.toString());
        expect(result.finalTime, expectedFinalTime);
        expect(result.elevationGainPositive, expectedElevationData['positive']);
        expect(result.elevationGainNegative, expectedElevationData['negative']);
        expect(result.poiTypes, expectedPoiTypes);
        expect(result.pois, expectedPois);

        // Verify all services were called
        verify(() => mockStatisticsService.getFinalTime()).called(1);
        verify(() => mockStatisticsService.calculateTotalDistance(segments))
            .called(1);
        verify(() => mockStatisticsService.calculateElevationGain(segments))
            .called(1);
        verify(() => mockPoiService.getPoiTypesImproviseHike()).called(1);
        verify(() => mockPoiService.getHikePois()).called(1);
      });

      test('should handle null final time with Duration.zero', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime()).thenReturn(null);
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(0.0);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 0.0, 'negative': 0.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.finalTime, Duration.zero);
      });

      test('should handle empty segments', () {
        // Arrange
        final emptySegments = <List<gl.Position>>[];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(minutes: 30));
        when(() => mockStatisticsService.calculateTotalDistance(emptySegments))
            .thenReturn(0.0);
        when(() => mockStatisticsService.calculateElevationGain(emptySegments))
            .thenReturn({'positive': 0.0, 'negative': 0.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(emptySegments);

        // Assert
        expect(result.distance, '0.0');
        expect(result.elevationGainPositive, 0.0);
        expect(result.elevationGainNegative, 0.0);
        expect(result.poiTypes, isEmpty);
        expect(result.pois, isEmpty);
      });

      test('should handle empty POI list', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(minutes: 10));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(1.5);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 10.0, 'negative': 5.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.poiTypes, isEmpty);
        expect(result.pois, isEmpty);
      });

      test('should handle multiple segments with varying positions', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2194,
              longitude: -1.5526,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 120.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.5,
              speedAccuracy: 1.0,
            ),
          ],
          [
            gl.Position(
              latitude: 47.2204,
              longitude: -1.5516,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 110.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.2,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2214,
              longitude: -1.5506,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 130.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.8,
              speedAccuracy: 1.0,
            ),
          ],
        ];

        final expectedDistance = 8.75;
        final expectedElevationData = {
          'positive': 180.0,
          'negative': 60.0,
        };

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(hours: 2, minutes: 15));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(expectedDistance);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn(expectedElevationData);
        when(() => mockPoiService.getPoiTypesImproviseHike())
            .thenReturn([PoiType.hazard]);
        when(() => mockPoiService.getHikePois()).thenReturn([
          UserPOI(
            id: 'poi1',
            name: 'Danger Zone',
            type: PoiType.hazard,
            latitude: 47.2200,
            longitude: -1.5520,
            createdAt: DateTime.now(),
          ),
        ]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.distance, expectedDistance.toString());
        expect(result.elevationGainPositive, 180.0);
        expect(result.elevationGainNegative, 60.0);
        expect(result.poiTypes.length, 1);
        expect(result.pois.length, 1);
      });

      test('should handle all POI types', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        final allPoiTypes = [
          PoiType.parking,
          PoiType.hazard,
          PoiType.toilets,
          PoiType.water,
          PoiType.camping,
          PoiType.animals,
        ];

        final allPois = [
          UserPOI(
            id: 'poi1',
            name: 'Parking',
            type: PoiType.parking,
            latitude: 47.2184,
            longitude: -1.5536,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi2',
            name: 'Danger',
            type: PoiType.hazard,
            latitude: 47.2185,
            longitude: -1.5537,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi3',
            name: 'Toilets',
            type: PoiType.toilets,
            latitude: 47.2186,
            longitude: -1.5538,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi4',
            name: 'Water',
            type: PoiType.water,
            latitude: 47.2187,
            longitude: -1.5539,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi5',
            name: 'Camping',
            type: PoiType.camping,
            latitude: 47.2188,
            longitude: -1.5540,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi6',
            name: 'Animals',
            type: PoiType.animals,
            latitude: 47.2189,
            longitude: -1.5541,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(hours: 3));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(10.0);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 200.0, 'negative': 100.0});
        when(() => mockPoiService.getPoiTypesImproviseHike())
            .thenReturn(allPoiTypes);
        when(() => mockPoiService.getHikePois()).thenReturn(allPois);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.poiTypes.length, 6);
        expect(result.pois.length, 6);
        expect(result.poiTypes, containsAll(allPoiTypes));
      });

      test('should handle zero elevation gain', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2194,
              longitude: -1.5526,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.5,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(minutes: 45));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(3.2);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 0.0, 'negative': 0.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.elevationGainPositive, 0.0);
        expect(result.elevationGainNegative, 0.0);
      });

      test('should handle negative elevation (descent only)', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 200.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2194,
              longitude: -1.5526,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 150.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.5,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(minutes: 20));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(2.1);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 0.0, 'negative': 50.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.elevationGainPositive, 0.0);
        expect(result.elevationGainNegative, 50.0);
      });

      test('should handle large distance values', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(hours: 8, minutes: 45));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(42.5);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 1500.0, 'negative': 1200.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.distance, '42.5');
        expect(result.finalTime, Duration(hours: 8, minutes: 45));
        expect(result.elevationGainPositive, 1500.0);
        expect(result.elevationGainNegative, 1200.0);
      });

      test('should handle very short hike', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2185,
              longitude: -1.5537,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 101.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.5,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(minutes: 2));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(0.15);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 1.0, 'negative': 0.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.distance, '0.15');
        expect(result.finalTime, Duration(minutes: 2));
        expect(result.elevationGainPositive, 1.0);
      });

      test('should handle segment with single position', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(seconds: 30));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(0.0);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 0.0, 'negative': 0.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.distance, '0.0');
        expect(result.finalTime, Duration(seconds: 30));
      });

      test('should preserve POI data integrity', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        final testPoi = UserPOI(
          id: 'test-poi-123',
          name: 'Test Water Source',
          type: PoiType.water,
          latitude: 47.2184,
          longitude: -1.5536,
          description: 'Clean mountain spring',
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(hours: 1));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(5.0);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 100.0, 'negative': 50.0});
        when(() => mockPoiService.getPoiTypesImproviseHike())
            .thenReturn([PoiType.water]);
        when(() => mockPoiService.getHikePois()).thenReturn([testPoi]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.pois.length, 1);
        final poi = result.pois.first;
        expect(poi.id, 'test-poi-123');
        expect(poi.name, 'Test Water Source');
        expect(poi.type, PoiType.water);
        expect(poi.latitude, 47.2184);
        expect(poi.longitude, -1.5536);
        expect(poi.description, 'Clean mountain spring');
        expect(poi.createdAt, DateTime(2024, 1, 15, 10, 30));
      });
    });

    group('Integration Scenarios', () {
      test('should handle complete hike with multiple POIs and complex path',
          () {
        // Arrange
        final complexSegments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2194,
              longitude: -1.5526,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 120.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.5,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2204,
              longitude: -1.5516,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 115.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.3,
              speedAccuracy: 1.0,
            ),
          ],
          [
            gl.Position(
              latitude: 47.2214,
              longitude: -1.5506,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 130.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.8,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2224,
              longitude: -1.5496,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 125.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.6,
              speedAccuracy: 1.0,
            ),
          ],
        ];

        final pois = [
          UserPOI(
            id: 'poi1',
            name: 'Trailhead Parking',
            type: PoiType.parking,
            latitude: 47.2184,
            longitude: -1.5536,
            description: 'Start point parking',
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi2',
            name: 'Mountain Spring',
            type: PoiType.water,
            latitude: 47.2194,
            longitude: -1.5526,
            description: 'Fresh water source',
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi3',
            name: 'Wildlife Crossing',
            type: PoiType.animals,
            latitude: 47.2214,
            longitude: -1.5506,
            description: 'Deer crossing area',
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(hours: 2, minutes: 30, seconds: 15));
        when(() =>
                mockStatisticsService.calculateTotalDistance(complexSegments))
            .thenReturn(12.75);
        when(() =>
                mockStatisticsService.calculateElevationGain(complexSegments))
            .thenReturn({'positive': 250.0, 'negative': 180.0});
        when(() => mockPoiService.getPoiTypesImproviseHike())
            .thenReturn([PoiType.parking, PoiType.water, PoiType.animals]);
        when(() => mockPoiService.getHikePois()).thenReturn(pois);

        // Act
        final result = useCase.buildFinalHike(complexSegments);

        // Assert
        expect(result.distance, '12.75');
        expect(result.finalTime, Duration(hours: 2, minutes: 30, seconds: 15));
        expect(result.elevationGainPositive, 250.0);
        expect(result.elevationGainNegative, 180.0);
        expect(result.poiTypes.length, 3);
        expect(result.pois.length, 3);

        // Verify service call order doesn't matter
        verify(() => mockStatisticsService.getFinalTime()).called(1);
        verify(() =>
            mockStatisticsService.calculateTotalDistance(complexSegments))
            .called(1);
        verify(() =>
            mockStatisticsService.calculateElevationGain(complexSegments))
            .called(1);
        verify(() => mockPoiService.getPoiTypesImproviseHike()).called(1);
        verify(() => mockPoiService.getHikePois()).called(1);
      });

      test('should handle hike with no time recorded but has distance', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2194,
              longitude: -1.5526,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 110.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.5,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime()).thenReturn(null);
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(5.5);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 75.0, 'negative': 25.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.finalTime, Duration.zero);
        expect(result.distance, '5.5');
        expect(result.elevationGainPositive, 75.0);
      });

      test('should handle hike with POIs but no elevation change', () {
        // Arrange
        final flatSegments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
            gl.Position(
              latitude: 47.2194,
              longitude: -1.5526,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 1.5,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        final flatHikePois = [
          UserPOI(
            id: 'poi1',
            name: 'Beach Parking',
            type: PoiType.parking,
            latitude: 47.2184,
            longitude: -1.5536,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi2',
            name: 'Restroom',
            type: PoiType.toilets,
            latitude: 47.2194,
            longitude: -1.5526,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(minutes: 45));
        when(() => mockStatisticsService.calculateTotalDistance(flatSegments))
            .thenReturn(3.2);
        when(() => mockStatisticsService.calculateElevationGain(flatSegments))
            .thenReturn({'positive': 0.0, 'negative': 0.0});
        when(() => mockPoiService.getPoiTypesImproviseHike())
            .thenReturn([PoiType.parking, PoiType.toilets]);
        when(() => mockPoiService.getHikePois()).thenReturn(flatHikePois);

        // Act
        final result = useCase.buildFinalHike(flatSegments);

        // Assert
        expect(result.elevationGainPositive, 0.0);
        expect(result.elevationGainNegative, 0.0);
        expect(result.pois.length, 2);
        expect(result.distance, '3.2');
      });
    });

    group('Edge Cases', () {
      test('should handle very long duration', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        final veryLongDuration = Duration(hours: 24, minutes: 30);

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(veryLongDuration);
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(15.0);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 100.0, 'negative': 50.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.finalTime, veryLongDuration);
      });

      test('should handle very high elevation gains', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(hours: 10));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(25.0);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 3000.0, 'negative': 2500.0});
        when(() => mockPoiService.getPoiTypesImproviseHike()).thenReturn([]);
        when(() => mockPoiService.getHikePois()).thenReturn([]);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.elevationGainPositive, 3000.0);
        expect(result.elevationGainNegative, 2500.0);
      });

      test('should handle duplicate POI types', () {
        // Arrange
        final segments = [
          [
            gl.Position(
              latitude: 47.2184,
              longitude: -1.5536,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 100.0,
              altitudeAccuracy: 5.0,
              heading: 0.0,
              headingAccuracy: 5.0,
              speed: 0.0,
              speedAccuracy: 1.0,
            ),
          ]
        ];

        final poisWithDuplicateTypes = [
          UserPOI(
            id: 'poi1',
            name: 'Water Source 1',
            type: PoiType.water,
            latitude: 47.2184,
            longitude: -1.5536,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi2',
            name: 'Water Source 2',
            type: PoiType.water,
            latitude: 47.2194,
            longitude: -1.5526,
            createdAt: DateTime.now(),
          ),
          UserPOI(
            id: 'poi3',
            name: 'Water Source 3',
            type: PoiType.water,
            latitude: 47.2204,
            longitude: -1.5516,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockStatisticsService.getFinalTime())
            .thenReturn(Duration(hours: 1));
        when(() => mockStatisticsService.calculateTotalDistance(segments))
            .thenReturn(5.0);
        when(() => mockStatisticsService.calculateElevationGain(segments))
            .thenReturn({'positive': 50.0, 'negative': 30.0});
        when(() => mockPoiService.getPoiTypesImproviseHike())
            .thenReturn([PoiType.water]);
        when(() => mockPoiService.getHikePois())
            .thenReturn(poisWithDuplicateTypes);

        // Act
        final result = useCase.buildFinalHike(segments);

        // Assert
        expect(result.poiTypes.length, 1);
        expect(result.poiTypes.first, PoiType.water);
        expect(result.pois.length, 3);
      });
    });
  });
}
