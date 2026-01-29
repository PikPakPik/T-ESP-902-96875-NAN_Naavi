import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/user_poi.dart';

void main() {
  group('UserPOI', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    test('should create UserPOI with all required fields', () {
      final poi = UserPOI(
        id: 'poi_123',
        name: 'Test POI',
        type: PoiType.parking,
        latitude: 47.2184,
        longitude: -1.5536,
        description: 'A test POI',
        createdAt: testDate,
      );

      expect(poi.id, 'poi_123');
      expect(poi.name, 'Test POI');
      expect(poi.type, PoiType.parking);
      expect(poi.latitude, 47.2184);
      expect(poi.longitude, -1.5536);
      expect(poi.description, 'A test POI');
      expect(poi.createdAt, testDate);
    });

    test('should use empty string as default description', () {
      final poi = UserPOI(
        id: 'poi_123',
        name: 'Test POI',
        type: PoiType.water,
        latitude: 47.2184,
        longitude: -1.5536,
        createdAt: testDate,
      );

      expect(poi.description, '');
    });

    group('toMap', () {
      test('should convert UserPOI to Map correctly', () {
        final poi = UserPOI(
          id: 'poi_123',
          name: 'Mountain View',
          type: PoiType.hazard,
          latitude: 47.2184,
          longitude: -1.5536,
          description: 'Dangerous area',
          createdAt: testDate,
        );

        final map = poi.toMap();

        expect(map['id'], 'poi_123');
        expect(map['name'], 'Mountain View');
        expect(map['type'], 'hazard');
        expect(map['latitude'], 47.2184);
        expect(map['longitude'], -1.5536);
        expect(map['description'], 'Dangerous area');
        expect(map['createdAt'], testDate.toIso8601String());
      });

      test('should convert enum type to string', () {
        final poi = UserPOI(
          id: 'poi_1',
          name: 'Test',
          type: PoiType.toilets,
          latitude: 0,
          longitude: 0,
          createdAt: testDate,
        );

        final map = poi.toMap();

        expect(map['type'], isA<String>());
        expect(map['type'], 'toilets');
      });

      test('should convert DateTime to ISO8601 string', () {
        final poi = UserPOI(
          id: 'poi_1',
          name: 'Test',
          type: PoiType.water,
          latitude: 0,
          longitude: 0,
          createdAt: testDate,
        );

        final map = poi.toMap();

        expect(map['createdAt'], isA<String>());
        expect(map['createdAt'], testDate.toIso8601String());
      });
    });

    group('fromMap', () {
      test('should create UserPOI from Map', () {
        final map = {
          'id': 'poi_456',
          'name': 'Forest Trail',
          'type': 'camping',
          'latitude': 48.8566,
          'longitude': 2.3522,
          'description': 'Nice camping spot',
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);

        expect(poi.id, 'poi_456');
        expect(poi.name, 'Forest Trail');
        expect(poi.type, PoiType.camping);
        expect(poi.latitude, 48.8566);
        expect(poi.longitude, 2.3522);
        expect(poi.description, 'Nice camping spot');
        expect(poi.createdAt, testDate);
      });

      test('should handle missing description with empty string', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'parking',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);

        expect(poi.description, '');
      });

      test('should handle null description with empty string', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'parking',
          'latitude': 0.0,
          'longitude': 0.0,
          'description': null,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);

        expect(poi.description, '');
      });

      test('should parse integer coordinates as double', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'water',
          'latitude': 47,
          'longitude': -1,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);

        expect(poi.latitude, isA<double>());
        expect(poi.latitude, 47.0);
        expect(poi.longitude, isA<double>());
        expect(poi.longitude, -1.0);
      });
    });

    group('POI Type Parsing', () {
      test('should parse "parking" to PoiType.parking', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'parking',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.parking);
      });

      test('should parse "hazard" to PoiType.hazard', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'hazard',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.hazard);
      });

      test('should parse "danger" to PoiType.hazard', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'danger',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.hazard);
      });

      test('should parse "toilets" to PoiType.toilets', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'toilets',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.toilets);
      });

      test('should parse "toilettes" to PoiType.toilets', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'toilettes',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.toilets);
      });

      test('should parse "water" to PoiType.water', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'water',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.water);
      });

      test('should parse "eau" to PoiType.water', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'eau',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.water);
      });

      test('should parse "camping" to PoiType.camping', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'camping',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.camping);
      });

      test('should parse "animals" to PoiType.animals', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'animals',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.animals);
      });

      test('should parse "animaux" to PoiType.animals', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'animaux',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.animals);
      });

      test('should default to PoiType.hazard for unknown type', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'unknown_type',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.hazard);
      });

      test('should handle case-insensitive type parsing', () {
        final map = {
          'id': 'poi_1',
          'name': 'Test',
          'type': 'PARKING',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': testDate.toIso8601String(),
        };

        final poi = UserPOI.fromMap(map);
        expect(poi.type, PoiType.parking);
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON string', () {
        final poi = UserPOI(
          id: 'poi_789',
          name: 'River Crossing',
          type: PoiType.water,
          latitude: 45.5,
          longitude: -73.6,
          description: 'Water refill point',
          createdAt: testDate,
        );

        final jsonString = poi.toJsonString();

        expect(jsonString, isA<String>());
        expect(jsonString, contains('poi_789'));
        expect(jsonString, contains('River Crossing'));
        expect(jsonString, contains('water'));
      });

      test('should create from JSON string', () {
        final jsonString = '''
        {
          "id": "poi_999",
          "name": "Mountain Peak",
          "type": "hazard",
          "latitude": 47.5,
          "longitude": -1.2,
          "description": "Steep climb",
          "createdAt": "${testDate.toIso8601String()}"
        }
        ''';

        final poi = UserPOI.fromJsonString(jsonString);

        expect(poi.id, 'poi_999');
        expect(poi.name, 'Mountain Peak');
        expect(poi.type, PoiType.hazard);
        expect(poi.latitude, 47.5);
        expect(poi.longitude, -1.2);
        expect(poi.description, 'Steep climb');
        expect(poi.createdAt, testDate);
      });

      test('should maintain data integrity through round-trip serialization', () {
        final original = UserPOI(
          id: 'poi_test',
          name: 'Test Location',
          type: PoiType.camping,
          latitude: 48.8566,
          longitude: 2.3522,
          description: 'Great camping spot',
          createdAt: testDate,
        );

        final jsonString = original.toJsonString();
        final deserialized = UserPOI.fromJsonString(jsonString);

        expect(deserialized.id, original.id);
        expect(deserialized.name, original.name);
        expect(deserialized.type, original.type);
        expect(deserialized.latitude, original.latitude);
        expect(deserialized.longitude, original.longitude);
        expect(deserialized.description, original.description);
        expect(deserialized.createdAt, original.createdAt);
      });
    });

    group('Edge Cases', () {
      test('should handle coordinates at boundaries', () {
        final poi = UserPOI(
          id: 'poi_1',
          name: 'Edge',
          type: PoiType.parking,
          latitude: 90.0, // Max latitude
          longitude: 180.0, // Max longitude
          createdAt: testDate,
        );

        expect(poi.latitude, 90.0);
        expect(poi.longitude, 180.0);
      });

      test('should handle negative coordinates', () {
        final poi = UserPOI(
          id: 'poi_1',
          name: 'Southern',
          type: PoiType.water,
          latitude: -45.0,
          longitude: -120.0,
          createdAt: testDate,
        );

        expect(poi.latitude, -45.0);
        expect(poi.longitude, -120.0);
      });

      test('should handle very long descriptions', () {
        final longDescription = 'A' * 1000;
        final poi = UserPOI(
          id: 'poi_1',
          name: 'Test',
          type: PoiType.hazard,
          latitude: 0,
          longitude: 0,
          description: longDescription,
          createdAt: testDate,
        );

        expect(poi.description.length, 1000);
        expect(poi.description, longDescription);
      });

      test('should handle special characters in name and description', () {
        final poi = UserPOI(
          id: 'poi_1',
          name: 'Café "Le Mont" & Bar',
          type: PoiType.water,
          latitude: 0,
          longitude: 0,
          description: 'Located near "main" street & <park>',
          createdAt: testDate,
        );

        expect(poi.name, contains('Café'));
        expect(poi.name, contains('"'));
        expect(poi.description, contains('&'));
        expect(poi.description, contains('<'));
      });

      test('should handle very precise coordinates', () {
        final poi = UserPOI(
          id: 'poi_1',
          name: 'Precise',
          type: PoiType.parking,
          latitude: 47.21845678901234,
          longitude: -1.55367890123456,
          createdAt: testDate,
        );

        expect(poi.latitude, 47.21845678901234);
        expect(poi.longitude, -1.55367890123456);
      });
    });
  });
}
