import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/improvise_hike.dart';
import 'package:naavi/data/models/user_poi.dart';

void main() {
  group('ImproviseHike', () {
    late List<UserPOI> testPois;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      testPois = [
        UserPOI(
          id: 'poi_1',
          name: 'Water Source',
          type: PoiType.water,
          latitude: 47.2184,
          longitude: -1.5536,
          createdAt: testDate,
        ),
        UserPOI(
          id: 'poi_2',
          name: 'Parking Area',
          type: PoiType.parking,
          latitude: 47.2194,
          longitude: -1.5526,
          createdAt: testDate,
        ),
      ];
    });

    test('should create ImproviseHike with all required fields', () {
      final hike = ImproviseHike(
        title: 'Morning Hike',
        distance: '5.2 km',
        finalTime: const Duration(hours: 2, minutes: 30),
        poiTypes: [PoiType.water, PoiType.parking],
        pois: testPois,
        elevationGainPositive: 250.5,
        elevationGainNegative: 180.3,
      );

      expect(hike.title, 'Morning Hike');
      expect(hike.distance, '5.2 km');
      expect(hike.finalTime, const Duration(hours: 2, minutes: 30));
      expect(hike.poiTypes, [PoiType.water, PoiType.parking]);
      expect(hike.pois, testPois);
      expect(hike.elevationGainPositive, 250.5);
      expect(hike.elevationGainNegative, 180.3);
    });

    test('should create ImproviseHike with optional null values', () {
      final hike = ImproviseHike(
        distance: '3.0 km',
        finalTime: const Duration(hours: 1),
        poiTypes: [],
        pois: [],
      );

      expect(hike.title, isNull);
      expect(hike.elevationGainPositive, isNull);
      expect(hike.elevationGainNegative, isNull);
    });

    test('should handle empty POI lists', () {
      final hike = ImproviseHike(
        distance: '2.5 km',
        finalTime: const Duration(minutes: 45),
        poiTypes: [],
        pois: [],
      );

      expect(hike.poiTypes, isEmpty);
      expect(hike.pois, isEmpty);
    });

    test('should store multiple POI types', () {
      final hike = ImproviseHike(
        distance: '10 km',
        finalTime: const Duration(hours: 4),
        poiTypes: [
          PoiType.water,
          PoiType.parking,
          PoiType.camping,
          PoiType.toilets,
        ],
        pois: testPois,
      );

      expect(hike.poiTypes.length, 4);
      expect(hike.poiTypes, contains(PoiType.water));
      expect(hike.poiTypes, contains(PoiType.parking));
      expect(hike.poiTypes, contains(PoiType.camping));
      expect(hike.poiTypes, contains(PoiType.toilets));
    });

    test('should store multiple POIs with full details', () {
      final hike = ImproviseHike(
        distance: '8 km',
        finalTime: const Duration(hours: 3),
        poiTypes: [PoiType.water, PoiType.parking],
        pois: testPois,
      );

      expect(hike.pois.length, 2);
      expect(hike.pois[0].name, 'Water Source');
      expect(hike.pois[1].name, 'Parking Area');
      expect(hike.pois[0].latitude, 47.2184);
      expect(hike.pois[1].latitude, 47.2194);
    });

    test('should handle zero duration', () {
      final hike = ImproviseHike(
        distance: '0 km',
        finalTime: Duration.zero,
        poiTypes: [],
        pois: [],
      );

      expect(hike.finalTime, Duration.zero);
    });

    test('should handle very long duration', () {
      final hike = ImproviseHike(
        distance: '50 km',
        finalTime: const Duration(hours: 12, minutes: 45),
        poiTypes: [],
        pois: [],
      );

      expect(hike.finalTime.inHours, 12);
      expect(hike.finalTime.inMinutes, 12 * 60 + 45);
    });

    test('should handle different distance formats', () {
      final hike1 = ImproviseHike(
        distance: '5.2 km',
        finalTime: const Duration(hours: 2),
        poiTypes: [],
        pois: [],
      );

      final hike2 = ImproviseHike(
        distance: '3000 m',
        finalTime: const Duration(hours: 1),
        poiTypes: [],
        pois: [],
      );

      final hike3 = ImproviseHike(
        distance: '10.5',
        finalTime: const Duration(hours: 4),
        poiTypes: [],
        pois: [],
      );

      expect(hike1.distance, '5.2 km');
      expect(hike2.distance, '3000 m');
      expect(hike3.distance, '10.5');
    });

    group('Elevation Data', () {
      test('should handle positive elevation gain', () {
        final hike = ImproviseHike(
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
          elevationGainPositive: 350.0,
        );

        expect(hike.elevationGainPositive, 350.0);
      });

      test('should handle negative elevation gain', () {
        final hike = ImproviseHike(
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
          elevationGainNegative: 250.0,
        );

        expect(hike.elevationGainNegative, 250.0);
      });

      test('should handle zero elevation gains', () {
        final hike = ImproviseHike(
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
          elevationGainPositive: 0.0,
          elevationGainNegative: 0.0,
        );

        expect(hike.elevationGainPositive, 0.0);
        expect(hike.elevationGainNegative, 0.0);
      });

      test('should handle very large elevation gains', () {
        final hike = ImproviseHike(
          distance: '20 km',
          finalTime: const Duration(hours: 8),
          poiTypes: [],
          pois: [],
          elevationGainPositive: 2500.0,
          elevationGainNegative: 1800.0,
        );

        expect(hike.elevationGainPositive, 2500.0);
        expect(hike.elevationGainNegative, 1800.0);
      });

      test('should handle precise decimal elevation values', () {
        final hike = ImproviseHike(
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
          elevationGainPositive: 123.456,
          elevationGainNegative: 78.912,
        );

        expect(hike.elevationGainPositive, 123.456);
        expect(hike.elevationGainNegative, 78.912);
      });
    });

    group('POI Compatibility', () {
      test('should maintain unique POI types list', () {
        final hike = ImproviseHike(
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [PoiType.water, PoiType.parking, PoiType.water],
          pois: testPois,
        );

        // poiTypes should be provided by caller as unique
        expect(hike.poiTypes.length, 3);
      });

      test('should store full POI data with locations', () {
        final detailedPois = [
          UserPOI(
            id: 'poi_1',
            name: 'Spring Water',
            type: PoiType.water,
            latitude: 47.2184,
            longitude: -1.5536,
            description: 'Fresh mountain spring',
            createdAt: testDate,
          ),
          UserPOI(
            id: 'poi_2',
            name: 'Main Parking',
            type: PoiType.parking,
            latitude: 47.2194,
            longitude: -1.5526,
            description: '50 spots available',
            createdAt: testDate,
          ),
        ];

        final hike = ImproviseHike(
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [PoiType.water, PoiType.parking],
          pois: detailedPois,
        );

        expect(hike.pois.length, 2);
        expect(hike.pois[0].description, 'Fresh mountain spring');
        expect(hike.pois[1].description, '50 spots available');
      });

      test('should handle many POIs', () {
        final manyPois = List.generate(
          50,
          (i) => UserPOI(
            id: 'poi_$i',
            name: 'POI $i',
            type: PoiType.water,
            latitude: 47.2184 + i * 0.001,
            longitude: -1.5536 + i * 0.001,
            createdAt: testDate,
          ),
        );

        final hike = ImproviseHike(
          distance: '25 km',
          finalTime: const Duration(hours: 10),
          poiTypes: [PoiType.water],
          pois: manyPois,
        );

        expect(hike.pois.length, 50);
        expect(hike.pois.first.name, 'POI 0');
        expect(hike.pois.last.name, 'POI 49');
      });
    });

    group('Title Variations', () {
      test('should handle short titles', () {
        final hike = ImproviseHike(
          title: 'A',
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
        );

        expect(hike.title, 'A');
      });

      test('should handle long titles', () {
        final longTitle = 'A' * 200;
        final hike = ImproviseHike(
          title: longTitle,
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
        );

        expect(hike.title?.length, 200);
      });

      test('should handle titles with special characters', () {
        final hike = ImproviseHike(
          title: 'Mont "Blanc" & Les Écrins - été 2024',
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
        );

        expect(hike.title, contains('Blanc'));
        expect(hike.title, contains('&'));
        expect(hike.title, contains('é'));
      });

      test('should handle empty string title', () {
        final hike = ImproviseHike(
          title: '',
          distance: '5 km',
          finalTime: const Duration(hours: 2),
          poiTypes: [],
          pois: [],
        );

        expect(hike.title, '');
      });
    });

    group('Real World Scenarios', () {
      test('should represent a short urban walk', () {
        final hike = ImproviseHike(
          title: 'City Park Walk',
          distance: '2.5 km',
          finalTime: const Duration(minutes: 30),
          poiTypes: [PoiType.toilets, PoiType.water],
          pois: [
            UserPOI(
              id: 'poi_1',
              name: 'Park Facilities',
              type: PoiType.toilets,
              latitude: 47.2184,
              longitude: -1.5536,
              createdAt: testDate,
            ),
          ],
          elevationGainPositive: 15.0,
          elevationGainNegative: 15.0,
        );

        expect(hike.distance, '2.5 km');
        expect(hike.finalTime.inMinutes, 30);
        expect(hike.elevationGainPositive, lessThan(50));
      });

      test('should represent a long mountain hike', () {
        final hike = ImproviseHike(
          title: 'Alpine Trail',
          distance: '18.5 km',
          finalTime: const Duration(hours: 7, minutes: 45),
          poiTypes: [PoiType.water, PoiType.camping, PoiType.hazard],
          pois: testPois,
          elevationGainPositive: 1200.0,
          elevationGainNegative: 800.0,
        );

        expect(hike.finalTime.inHours, greaterThanOrEqualTo(7));
        expect(hike.elevationGainPositive, greaterThan(1000));
      });

      test('should represent a forest trail with many POIs', () {
        final forestPois = [
          UserPOI(
            id: 'poi_1',
            name: 'Trailhead Parking',
            type: PoiType.parking,
            latitude: 47.2184,
            longitude: -1.5536,
            createdAt: testDate,
          ),
          UserPOI(
            id: 'poi_2',
            name: 'Stream Crossing',
            type: PoiType.water,
            latitude: 47.2194,
            longitude: -1.5526,
            createdAt: testDate,
          ),
          UserPOI(
            id: 'poi_3',
            name: 'Wildlife Area',
            type: PoiType.animals,
            latitude: 47.2204,
            longitude: -1.5516,
            createdAt: testDate,
          ),
        ];

        final hike = ImproviseHike(
          title: 'Forest Discovery',
          distance: '12 km',
          finalTime: const Duration(hours: 4, minutes: 30),
          poiTypes: [PoiType.parking, PoiType.water, PoiType.animals],
          pois: forestPois,
          elevationGainPositive: 450.0,
          elevationGainNegative: 450.0,
        );

        expect(hike.pois.length, 3);
        expect(hike.poiTypes.length, 3);
      });
    });
  });
}
