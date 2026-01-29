import 'package:flutter_test/flutter_test.dart';
import 'package:geobase/geobase.dart';
import 'package:naavi/core/classes/HikeLine.dart';

void main() {
  group('HikeLine', () {
    group('constructor', () {
      test('should create HikeLine instance with valid line and info', () {
        // Arrange
        final lineString = LineString.build(
          [1.5536, 47.2184, 1.5537, 47.2185],
          type: Coords.xy,
        );
        final info = {
          'name': 'Test Route',
          'distance': 5.2,
          'duration': 120,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine, isNotNull);
        expect(hikeLine.line, equals(lineString));
        expect(hikeLine.info, equals(info));
      });

      test('should create HikeLine with empty info map', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = <String, dynamic>{};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line, equals(lineString));
        expect(hikeLine.info, isEmpty);
      });

      test('should create HikeLine with two points', () {
        // Arrange
        final lineString = LineString.build(
          [2.3522, 48.8566, 2.3523, 48.8567],
          type: Coords.xy,
        );
        final info = {'name': 'Two Points'};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(2));
        expect(hikeLine.info['name'], equals('Two Points'));
      });

      test('should create HikeLine with multiple points', () {
        // Arrange
        final coords = <double>[];
        for (int i = 0; i < 10; i++) {
          coords.addAll([i.toDouble(), i.toDouble() * 2]);
        }
        final lineString = LineString.build(coords, type: Coords.xy);
        final info = {'points': 10};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(10));
        expect(hikeLine.info['points'], equals(10));
      });

      test('should create HikeLine with complex info containing various data types', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 2.0, 3.0, 4.0],
          type: Coords.xy,
        );
        final info = {
          'name': 'Complex Route',
          'distance': 10.5,
          'duration': 180,
          'difficulty': 'moderate',
          'elevation_gain': 500,
          'tags': ['scenic', 'popular'],
          'rating': 4.5,
          'is_favorite': true,
          'metadata': {
            'created_at': '2024-01-01',
            'updated_at': '2024-01-02',
          },
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['name'], equals('Complex Route'));
        expect(hikeLine.info['distance'], equals(10.5));
        expect(hikeLine.info['duration'], equals(180));
        expect(hikeLine.info['difficulty'], equals('moderate'));
        expect(hikeLine.info['elevation_gain'], equals(500));
        expect(hikeLine.info['tags'], isA<List>());
        expect(hikeLine.info['tags'], contains('scenic'));
        expect(hikeLine.info['rating'], equals(4.5));
        expect(hikeLine.info['is_favorite'], isTrue);
        expect(hikeLine.info['metadata'], isA<Map>());
        expect(hikeLine.info['metadata']['created_at'], equals('2024-01-01'));
      });

      test('should create HikeLine with info containing null values', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = {
          'name': 'Test',
          'description': null,
          'optional_field': null,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['name'], equals('Test'));
        expect(hikeLine.info['description'], isNull);
        expect(hikeLine.info.containsKey('optional_field'), isTrue);
      });
    });

    group('properties', () {
      test('should provide access to line property', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 2.0, 3.0, 4.0],
          type: Coords.xy,
        );
        final info = {'test': 'data'};
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final retrievedLine = hikeLine.line;

        // Assert
        expect(retrievedLine, equals(lineString));
        expect(retrievedLine.chain.positionCount, equals(2));
      });

      test('should provide access to info property', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = {
          'key1': 'value1',
          'key2': 123,
          'key3': true,
        };
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final retrievedInfo = hikeLine.info;

        // Assert
        expect(retrievedInfo, equals(info));
        expect(retrievedInfo['key1'], equals('value1'));
        expect(retrievedInfo['key2'], equals(123));
        expect(retrievedInfo['key3'], isTrue);
      });

      test('should maintain immutability of required properties', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 1.0, 2.0, 2.0],
          type: Coords.xy,
        );
        final info = {'original': 'data'};
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act - Try to access properties multiple times
        final line1 = hikeLine.line;
        final line2 = hikeLine.line;
        final info1 = hikeLine.info;
        final info2 = hikeLine.info;

        // Assert - Should return same references
        expect(identical(line1, line2), isTrue);
        expect(identical(info1, info2), isTrue);
      });
    });

    group('toString', () {
      test('should return formatted string with info and position count', () {
        // Arrange
        final lineString = LineString.build(
          [1.5536, 47.2184, 1.5537, 47.2185, 1.5538, 47.2186],
          type: Coords.xy,
        );
        final info = {
          'name': 'Test Route',
          'distance': 5.2,
        };
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result = hikeLine.toString();

        // Assert
        expect(result, contains('HikeLine'));
        expect(result, contains('info:'));
        expect(result, contains('points:'));
        expect(result, contains('3'));
      });

      test('should handle toString with empty info map', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = <String, dynamic>{};
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result = hikeLine.toString();

        // Assert
        expect(result, equals('HikeLine(info: {}, points: 2)'));
      });

      test('should handle toString with two points line', () {
        // Arrange
        final lineString = LineString.build(
          [5.0, 10.0, 5.1, 10.1],
          type: Coords.xy,
        );
        final info = {'id': 1};
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result = hikeLine.toString();

        // Assert
        expect(result, contains('points: 2'));
        expect(result, contains('id: 1'));
      });

      test('should handle toString with zero points line', () {
        // Arrange
        final lineString = LineString.build(const [], type: Coords.xy);
        final info = {'empty': true};
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result = hikeLine.toString();

        // Assert
        expect(result, contains('points: 0'));
        expect(result, contains('empty: true'));
      });

      test('should handle toString with large number of points', () {
        // Arrange
        final coords = <double>[];
        for (int i = 0; i < 1000; i++) {
          coords.addAll([i.toDouble(), i.toDouble()]);
        }
        final lineString = LineString.build(coords, type: Coords.xy);
        final info = {'large': 'dataset'};
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result = hikeLine.toString();

        // Assert
        expect(result, contains('points: 1000'));
        expect(result, contains('large: dataset'));
      });

      test('should handle toString with complex nested info', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 2.0, 3.0, 4.0],
          type: Coords.xy,
        );
        final info = {
          'name': 'Complex',
          'metadata': {
            'nested': {
              'deeply': 'nested value',
            },
          },
          'list': [1, 2, 3],
        };
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result = hikeLine.toString();

        // Assert
        expect(result, contains('HikeLine'));
        expect(result, contains('info:'));
        expect(result, contains('points: 2'));
        // The exact formatting of nested structures depends on Map.toString()
        expect(result, contains('name'));
        expect(result, contains('Complex'));
      });

      test('should handle toString with special characters in info', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = {
          'name': 'Route with "quotes" and \'apostrophes\'',
          'description': 'Line\nwith\nnewlines',
          'special': 'Characters: !@#\$%^&*()',
        };
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result = hikeLine.toString();

        // Assert
        expect(result, isNotEmpty);
        expect(result, contains('HikeLine'));
        expect(result, contains('info:'));
        expect(result, contains('points: 2'));
      });

      test('should produce consistent toString output for same data', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 1.0, 2.0, 2.0],
          type: Coords.xy,
        );
        final info = {'consistent': 'data'};
        final hikeLine = HikeLine(line: lineString, info: info);

        // Act
        final result1 = hikeLine.toString();
        final result2 = hikeLine.toString();

        // Assert
        expect(result1, equals(result2));
      });
    });

    group('edge cases', () {
      test('should handle LineString with decimal precision coordinates', () {
        // Arrange
        final lineString = LineString.build(
          [1.123456789, 47.987654321, 1.234567890, 47.876543210],
          type: Coords.xy,
        );
        final info = {'precision': 'high'};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(2));
        expect(hikeLine.info['precision'], equals('high'));
      });

      test('should handle negative coordinates', () {
        // Arrange - San Francisco and Los Angeles
        final lineString = LineString.build(
          [-122.4194, 37.7749, -118.2437, 34.0522],
          type: Coords.xy,
        );
        final info = {'region': 'California'};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(2));
        expect(hikeLine.info['region'], equals('California'));
      });

      test('should handle coordinates at extreme values', () {
        // Arrange - Min and max lat/long values
        final lineString = LineString.build(
          [-180.0, -90.0, 180.0, 90.0],
          type: Coords.xy,
        );
        final info = {'extreme': true};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(2));
        expect(hikeLine.info['extreme'], isTrue);
      });

      test('should handle info with very long string values', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final longString = 'A' * 10000;
        final info = {'long_description': longString};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['long_description'], equals(longString));
        expect(hikeLine.info['long_description'].length, equals(10000));
      });

      test('should handle info with numeric edge values', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = {
          'zero': 0,
          'negative': -999,
          'large_int': 999999999,
          'small_double': 0.000001,
          'large_double': 999999.999999,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['zero'], equals(0));
        expect(hikeLine.info['negative'], equals(-999));
        expect(hikeLine.info['large_int'], equals(999999999));
        expect(hikeLine.info['small_double'], equals(0.000001));
        expect(hikeLine.info['large_double'], equals(999999.999999));
      });

      test('should handle duplicate consecutive points in LineString', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0],
          type: Coords.xy,
        );
        final info = {'has_duplicates': true};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(4));
        expect(hikeLine.info['has_duplicates'], isTrue);
      });

      test('should handle info with empty string values', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = {
          'empty_string': '',
          'name': 'Route',
          'description': '',
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['empty_string'], equals(''));
        expect(hikeLine.info['name'], equals('Route'));
        expect(hikeLine.info['description'], equals(''));
      });

      test('should handle info with boolean values', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 1.0, 2.0, 2.0],
          type: Coords.xy,
        );
        final info = {
          'is_active': true,
          'is_favorite': false,
          'is_public': true,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['is_active'], isTrue);
        expect(hikeLine.info['is_favorite'], isFalse);
        expect(hikeLine.info['is_public'], isTrue);
      });

      test('should handle info with mixed list types', () {
        // Arrange
        final lineString = LineString.build(
          [0.0, 0.0, 1.0, 1.0],
          type: Coords.xy,
        );
        final info = {
          'mixed_list': [1, 'two', 3.0, true, null],
          'empty_list': [],
          'nested_list': [
            [1, 2],
            [3, 4]
          ],
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['mixed_list'], hasLength(5));
        expect(hikeLine.info['empty_list'], isEmpty);
        expect(hikeLine.info['nested_list'], hasLength(2));
      });
    });

    group('real-world scenarios', () {
      test('should handle typical hiking route data', () {
        // Arrange - Simulating a real hiking trail in Chamonix
        final lineString = LineString.build(
          [
            6.8650, 45.8326, // Chamonix start
            6.8670, 45.8340,
            6.8690, 45.8355,
            6.8710, 45.8370, // Chamonix end
          ],
          type: Coords.xy,
        );
        final info = {
          'name': 'Lac Blanc Trail',
          'distance': 7.5,
          'duration': 240,
          'difficulty': 'moderate',
          'elevation_gain': 800,
          'region': 'French Alps',
          'rating': 4.8,
          'reviews': 1250,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(4));
        expect(hikeLine.info['name'], equals('Lac Blanc Trail'));
        expect(hikeLine.info['distance'], equals(7.5));
        expect(hikeLine.toString(), contains('points: 4'));
      });

      test('should handle urban walking route', () {
        // Arrange - City walking path in Paris
        final lineString = LineString.build(
          [
            2.3522, 48.8566, // Paris
            2.3530, 48.8570,
            2.3540, 48.8575,
          ],
          type: Coords.xy,
        );
        final info = {
          'name': 'Champs-Élysées Walk',
          'distance': 2.0,
          'duration': 30,
          'type': 'urban',
          'points_of_interest': ['Arc de Triomphe', 'Place de la Concorde'],
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(3));
        expect(hikeLine.info['type'], equals('urban'));
        expect(hikeLine.info['points_of_interest'], hasLength(2));
      });

      test('should handle GPS track with many waypoints', () {
        // Arrange - Dense GPS track with 500 points
        final coords = <double>[];
        for (int i = 0; i < 500; i++) {
          coords.addAll([
            1.4437 + (i * 0.0001),
            43.6047 + (i * 0.0001),
          ]);
        }
        final lineString = LineString.build(coords, type: Coords.xy);
        final info = {
          'name': 'GPS Track - Toulouse Circuit',
          'recorded_at': '2024-01-15T10:30:00Z',
          'device': 'GPS Watch',
          'accuracy': 'high',
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(500));
        expect(hikeLine.info['device'], equals('GPS Watch'));
        expect(hikeLine.toString(), contains('points: 500'));
      });

      test('should handle minimal route data', () {
        // Arrange - Bare minimum data
        final lineString = LineString.build(
          [0.0, 0.0, 0.1, 0.1],
          type: Coords.xy,
        );
        final info = <String, dynamic>{};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(2));
        expect(hikeLine.info, isEmpty);
        expect(hikeLine.toString(), equals('HikeLine(info: {}, points: 2)'));
      });

      test('should handle route with elevation data in coordinates', () {
        // Arrange - Using 3D positions with elevation (XYZ)
        final lineString = LineString.build(
          [
            1.0, 2.0, 100.0,
            1.1, 2.1, 150.0,
            1.2, 2.2, 200.0,
          ],
          type: Coords.xyz,
        );
        final info = {
          'has_elevation': true,
          'max_elevation': 200.0,
          'min_elevation': 100.0,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(3));
        expect(hikeLine.info['has_elevation'], isTrue);
        expect(hikeLine.info['max_elevation'], equals(200.0));
      });
    });

    group('type safety', () {
      test('should accept LineString as required type', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 1.0, 2.0, 2.0],
          type: Coords.xy,
        );
        final info = {'test': 'data'};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line, isA<LineString>());
      });

      test('should accept Map<String, dynamic> as info type', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 1.0, 2.0, 2.0],
          type: Coords.xy,
        );
        final info = <String, dynamic>{'test': 'data'};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info, isA<Map<String, dynamic>>());
      });

      test('should handle info map with various dynamic value types', () {
        // Arrange
        final lineString = LineString.build(
          [1.0, 1.0, 2.0, 2.0],
          type: Coords.xy,
        );
        final info = <String, dynamic>{
          'string': 'value',
          'int': 42,
          'double': 3.14,
          'bool': true,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
          'null': null,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.info['string'], isA<String>());
        expect(hikeLine.info['int'], isA<int>());
        expect(hikeLine.info['double'], isA<double>());
        expect(hikeLine.info['bool'], isA<bool>());
        expect(hikeLine.info['list'], isA<List>());
        expect(hikeLine.info['map'], isA<Map>());
        expect(hikeLine.info['null'], isNull);
      });
    });

    group('integration with actual usage patterns', () {
      test('should work with decodeWKBFromString-like usage', () {
        // Arrange - Simulating how the class is used in utils.dart
        final lineString = LineString.build(
          [1.5536, 47.2184, 1.5537, 47.2185],
          type: Coords.xy,
        );
        final routeData = {
          'wkb': 'test_data',
          'name': 'Mountain Trail',
          'distance': 10.5,
          'coordinates': [
            [1.5536, 47.2184],
            [1.5537, 47.2185]
          ],
        };
        final info = Map<String, dynamic>.from(routeData);
        info['hikeIndex'] = 0;
        info['start_point'] = {
          'longitude': 1.5536,
          'latitude': 47.2184,
        };

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(2));
        expect(hikeLine.info['name'], equals('Mountain Trail'));
        expect(hikeLine.info['distance'], equals(10.5));
        expect(hikeLine.info['hikeIndex'], equals(0));
        expect(hikeLine.info['coordinates'], isA<List>());
        expect(hikeLine.info['start_point'], isA<Map>());
        expect(hikeLine.info['start_point']['longitude'], equals(1.5536));
      });

      test('should handle coordinates extraction pattern', () {
        // Arrange - Testing coordinate extraction like in utils.dart lines 62-65
        final lineString = LineString.build(
          [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
          type: Coords.xy,
        );
        final hikeLine = HikeLine(line: lineString, info: {});

        // Act - Extract coordinates from line like in the actual code
        final coordinatesList = <List<double>>[];
        for (int j = 0; j < hikeLine.line.chain.positionCount; j++) {
          final pos = hikeLine.line.chain[j];
          coordinatesList.add([pos.x, pos.y]);
        }

        // Assert
        expect(coordinatesList.length, equals(3));
        expect(coordinatesList[0], equals([1.0, 2.0]));
        expect(coordinatesList[1], equals([3.0, 4.0]));
        expect(coordinatesList[2], equals([5.0, 6.0]));
      });

      test('should work with empty LineString like decodeWKBFromString error case', () {
        // Arrange - Simulating error case that returns empty LineString
        final lineString = LineString.build(const [], type: Coords.xy);
        final info = {'error': 'invalid_wkb'};

        // Act
        final hikeLine = HikeLine(line: lineString, info: info);

        // Assert
        expect(hikeLine.line.chain.positionCount, equals(0));
        expect(hikeLine.info['error'], equals('invalid_wkb'));
        expect(hikeLine.toString(), contains('points: 0'));
      });
    });
  });
}
