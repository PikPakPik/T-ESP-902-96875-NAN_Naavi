import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/user_poi.dart';

void main() {
  group('PoiService', () {
    late PoiService poiService;

    setUp(() {
      poiService = PoiService();
    });

    test('should start with empty hikePois list', () {
      expect(poiService.getHikePois(), isEmpty);
    });

    test('should add POI to hikePois', () {
      final poi = UserPOI(
        id: '1',
        name: 'Test Water Point',
        type: PoiType.water,
        latitude: 48.8566,
        longitude: 2.3522,
        createdAt: DateTime.now(),
      );

      poiService.addHikePoi(poi);

      expect(poiService.getHikePois(), hasLength(1));
      expect(poiService.getHikePois().first, equals(poi));
    });

    test('should add multiple POIs', () {
      final poi1 = UserPOI(
        id: '1',
        name: 'Test Water Point',
        type: PoiType.water,
        latitude: 48.8566,
        longitude: 2.3522,
        createdAt: DateTime.now(),
      );
      final poi2 = UserPOI(
        id: '2',
        name: 'Test Hazard',
        type: PoiType.hazard,
        latitude: 48.8567,
        longitude: 2.3523,
        createdAt: DateTime.now(),
      );

      poiService.addHikePoi(poi1);
      poiService.addHikePoi(poi2);

      expect(poiService.getHikePois(), hasLength(2));
    });

    test('should clear all hikePois', () {
      final poi = UserPOI(
        id: '1',
        name: 'Test POI',
        type: PoiType.water,
        latitude: 48.8566,
        longitude: 2.3522,
        createdAt: DateTime.now(),
      );

      poiService.addHikePoi(poi);
      expect(poiService.getHikePois(), hasLength(1));

      poiService.clearHikePois();
      expect(poiService.getHikePois(), isEmpty);
    });

    test('should return unique POI types', () {
      final poi1 = UserPOI(
        id: '1',
        name: 'Water 1',
        type: PoiType.water,
        latitude: 48.8566,
        longitude: 2.3522,
        createdAt: DateTime.now(),
      );
      final poi2 = UserPOI(
        id: '2',
        name: 'Water 2',
        type: PoiType.water,
        latitude: 48.8567,
        longitude: 2.3523,
        createdAt: DateTime.now(),
      );
      final poi3 = UserPOI(
        id: '3',
        name: 'Hazard',
        type: PoiType.hazard,
        latitude: 48.8568,
        longitude: 2.3524,
        createdAt: DateTime.now(),
      );

      poiService.addHikePoi(poi1);
      poiService.addHikePoi(poi2);
      poiService.addHikePoi(poi3);

      final types = poiService.getPoiTypesImproviseHike();
      expect(types, hasLength(2));
      expect(types, contains(PoiType.water));
      expect(types, contains(PoiType.hazard));
    });

    test('should return empty list when no POIs', () {
      final types = poiService.getPoiTypesImproviseHike();
      expect(types, isEmpty);
    });

    test('setPoiTypesImproviseHike should not throw', () {
      expect(() => poiService.setPoiTypesImproviseHike(), returnsNormally);
    });
  });
}
