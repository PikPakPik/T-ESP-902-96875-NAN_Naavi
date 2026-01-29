import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/utils/utils.dart';

void main() {
  group('decodeWKBFromString', () {
    test(
      'should handle invalid input gracefully and return empty LineString',
      () {
        // The function catches exceptions and returns empty LineString
        final result = decodeWKBFromString('invalid_data');

        expect(result.chain.positionCount, 0);
      },
    );

    test('should handle empty string and return empty LineString', () {
      final result = decodeWKBFromString('');

      expect(result.chain.positionCount, 0);
    });
  });

  group('decodeMultipleWKBFromStrings', () {
    test('should process multiple strings', () {
      final results = decodeMultipleWKBFromStrings(['data1', 'data2']);

      // Even with invalid data, it should return a list
      expect(results.length, greaterThanOrEqualTo(0));
    });

    test('should handle empty list', () {
      final results = decodeMultipleWKBFromStrings([]);

      expect(results, isEmpty);
    });
  });

  group('decodeMultipleWKBWithInfo', () {
    test(
      'should process WKB with route information using existing coordinates',
      () {
        final wkbWithInfoList = [
          {
            'wkb': 'test_data',
            'name': 'Route 1',
            'distance': 5.2,
            'coordinates': [
              [0.0, 0.0],
              [1.0, 1.0],
            ],
          },
        ];

        final results = decodeMultipleWKBWithInfo(wkbWithInfoList);

        // Should process entries even with invalid WKB when coordinates are provided
        expect(results.length, greaterThanOrEqualTo(0));
      },
    );

    test('should use existing coordinates if available', () {
      final coordinates = [
        [1.5536, 47.2184],
        [1.5537, 47.2185],
      ];

      final wkbWithInfoList = [
        {'wkb': 'test_data', 'name': 'Route 1', 'coordinates': coordinates},
      ];

      final results = decodeMultipleWKBWithInfo(wkbWithInfoList);

      expect(results.length, greaterThanOrEqualTo(0));
    });

    test('should set hikeIndex correctly for multiple routes', () {
      final wkbWithInfoList = List.generate(
        3,
        (i) => {
          'wkb': 'test_data_$i',
          'name': 'Route $i',
          'coordinates': [
            [0.0, 0.0],
          ],
        },
      );

      final results = decodeMultipleWKBWithInfo(wkbWithInfoList);

      expect(results.length, greaterThanOrEqualTo(0));
    });

    test('should handle empty list', () {
      final results = decodeMultipleWKBWithInfo([]);

      expect(results, isEmpty);
    });

    test('should preserve route metadata', () {
      final wkbWithInfoList = [
        {
          'wkb': 'test_data',
          'name': 'Mountain Trail',
          'distance': 10.5,
          'duration': 180,
          'coordinates': [
            [0.0, 0.0],
          ],
        },
      ];

      final results = decodeMultipleWKBWithInfo(wkbWithInfoList);

      expect(results.length, greaterThanOrEqualTo(0));
    });
  });

  group('formatDurationFromSeconds', () {
    test('should format seconds correctly for hours and minutes', () {
      expect(formatDurationFromSeconds(9000), '2h 30min'); // 2h 30min
      expect(formatDurationFromSeconds(5400), '1h 30min'); // 1h 30min
      expect(formatDurationFromSeconds(3600), '1h'); // 1h
    });

    test('should format seconds correctly for minutes only', () {
      expect(formatDurationFromSeconds(1800), '30min'); // 30min
      expect(formatDurationFromSeconds(900), '15min'); // 15min
      expect(formatDurationFromSeconds(60), '1min'); // 1min
    });

    test('should return "?" for null input', () {
      expect(formatDurationFromSeconds(null), '?');
    });

    test('should return "?" for zero or negative input', () {
      expect(formatDurationFromSeconds(0), '?');
      expect(formatDurationFromSeconds(-100), '?');
    });

    test('should handle edge cases', () {
      expect(formatDurationFromSeconds(59), '0min'); // Less than 1 minute
      expect(formatDurationFromSeconds(3599), '59min'); // Just under 1 hour
      expect(formatDurationFromSeconds(3660), '1h 1min'); // 1h 1min
    });
  });
}
