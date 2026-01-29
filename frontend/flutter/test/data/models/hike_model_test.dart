import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/data/models/HikeModel.dart';

void main() {
  group('PathPoint', () {
    test('should create a PathPoint with latitude and longitude', () {
      final point = PathPoint(latitude: 47.2184, longitude: -1.5536);

      expect(point.latitude, 47.2184);
      expect(point.longitude, -1.5536);
    });
  });

  group('HikeModel', () {
    late PathPoint startPoint;
    late PathPoint endPoint;
    late List<List<PathPoint>> paths;

    setUp(() {
      startPoint = PathPoint(latitude: 47.2184, longitude: -1.5536);
      endPoint = PathPoint(latitude: 47.2284, longitude: -1.5436);
      paths = [
        [
          PathPoint(latitude: 47.2184, longitude: -1.5536),
          PathPoint(latitude: 47.2194, longitude: -1.5526),
          PathPoint(latitude: 47.2204, longitude: -1.5516),
        ],
        [
          PathPoint(latitude: 47.2214, longitude: -1.5506),
          PathPoint(latitude: 47.2224, longitude: -1.5496),
          PathPoint(latitude: 47.2284, longitude: -1.5436),
        ],
      ];
    });

    test('should create a HikeModel with required fields', () {
      final hike = HikeModel(
        startPoint: startPoint,
        paths: paths,
      );

      expect(hike.startPoint, startPoint);
      expect(hike.endPoint, isNull);
      expect(hike.paths, paths);
      expect(hike.paths.length, 2);
      expect(hike.paths[0].length, 3);
    });

    test('should create a HikeModel with endPoint', () {
      final hike = HikeModel(
        startPoint: startPoint,
        endPoint: endPoint,
        paths: paths,
      );

      expect(hike.startPoint, startPoint);
      expect(hike.endPoint, endPoint);
      expect(hike.endPoint!.latitude, 47.2284);
      expect(hike.endPoint!.longitude, -1.5436);
    });

    group('toMap', () {
      test('should convert HikeModel to Map with all fields', () {
        final hike = HikeModel(
          startPoint: startPoint,
          endPoint: endPoint,
          paths: paths,
        );

        final map = hike.toMap();

        expect(map['startPoint']['latitude'], 47.2184);
        expect(map['startPoint']['longitude'], -1.5536);
        expect(map['endPoint']['latitude'], 47.2284);
        expect(map['endPoint']['longitude'], -1.5436);
        expect(map['paths'], isA<List>());
        expect((map['paths'] as List).length, 2);
      });

      test('should convert HikeModel to Map with null endPoint', () {
        final hike = HikeModel(
          startPoint: startPoint,
          paths: paths,
        );

        final map = hike.toMap();

        expect(map['startPoint']['latitude'], 47.2184);
        expect(map['endPoint']['latitude'], isNull);
        expect(map['endPoint']['longitude'], isNull);
        expect(map['paths'], isA<List>());
      });

      test('should correctly serialize nested paths', () {
        final hike = HikeModel(
          startPoint: startPoint,
          paths: paths,
        );

        final map = hike.toMap();
        final pathsList = map['paths'] as List;

        expect(pathsList.length, 2);
        expect((pathsList[0] as List).length, 3);
        expect((pathsList[1] as List).length, 3);

        final firstPathFirstPoint = pathsList[0][0];
        expect(firstPathFirstPoint['latitude'], 47.2184);
        expect(firstPathFirstPoint['longitude'], -1.5536);
      });
    });

    group('toJson', () {
      test('should convert HikeModel to JSON string', () {
        final hike = HikeModel(
          startPoint: startPoint,
          endPoint: endPoint,
          paths: paths,
        );

        final jsonString = hike.toJson();

        expect(jsonString, isA<String>());
        expect(jsonString.contains('startPoint'), true);
        expect(jsonString.contains('endPoint'), true);
        expect(jsonString.contains('paths'), true);

        // Verify it's valid JSON
        final decoded = jsonDecode(jsonString);
        expect(decoded, isA<Map>());
      });
    });

    group('fromMap', () {
      test('should create HikeModel from Map', () {
        final map = {
          'startPoint': {
            'latitude': 47.2184,
            'longitude': -1.5536,
          },
          'endPoint': {
            'latitude': 47.2284,
            'longitude': -1.5436,
          },
          'paths': [
            [
              {'latitude': 47.2184, 'longitude': -1.5536},
              {'latitude': 47.2194, 'longitude': -1.5526},
            ],
            [
              {'latitude': 47.2204, 'longitude': -1.5516},
              {'latitude': 47.2284, 'longitude': -1.5436},
            ],
          ],
        };

        final hike = HikeModel.fromMap(map);

        expect(hike.startPoint.latitude, 47.2184);
        expect(hike.startPoint.longitude, -1.5536);
        expect(hike.endPoint, isNotNull);
        expect(hike.paths.length, 2);
        expect(hike.paths[0].length, 2);
        expect(hike.paths[1].length, 2);
      });
    });

    group('fromJson', () {
      test('should create HikeModel from JSON string', () {
        final jsonString = '''
        {
          "startPoint": {
            "latitude": 47.2184,
            "longitude": -1.5536
          },
          "endPoint": {
            "latitude": 47.2284,
            "longitude": -1.5436
          },
          "paths": [
            [
              {"latitude": 47.2184, "longitude": -1.5536},
              {"latitude": 47.2194, "longitude": -1.5526}
            ]
          ]
        }
        ''';

        final hike = HikeModel.fromJson(jsonString);

        expect(hike.startPoint.latitude, 47.2184);
        expect(hike.startPoint.longitude, -1.5536);
        expect(hike.endPoint, isNotNull);
        expect(hike.paths.length, 1);
        expect(hike.paths[0].length, 2);
      });
    });

    group('Serialization Round-Trip', () {
      test('should maintain data integrity through serialization and deserialization', () {
        final originalHike = HikeModel(
          startPoint: startPoint,
          endPoint: endPoint,
          paths: paths,
        );

        // Convert to JSON and back
        final jsonString = originalHike.toJson();
        final deserializedHike = HikeModel.fromJson(jsonString);

        expect(deserializedHike.startPoint.latitude, originalHike.startPoint.latitude);
        expect(deserializedHike.startPoint.longitude, originalHike.startPoint.longitude);
        expect(deserializedHike.endPoint, isNotNull);
        expect(deserializedHike.paths.length, originalHike.paths.length);

        for (int i = 0; i < originalHike.paths.length; i++) {
          expect(deserializedHike.paths[i].length, originalHike.paths[i].length);
          for (int j = 0; j < originalHike.paths[i].length; j++) {
            expect(
              deserializedHike.paths[i][j].latitude,
              originalHike.paths[i][j].latitude,
            );
            expect(
              deserializedHike.paths[i][j].longitude,
              originalHike.paths[i][j].longitude,
            );
          }
        }
      });
    });
  });
}
