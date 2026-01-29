// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/poi_configuration.dart';

void main() {
  group('POIConfiguration (Deprecated)', () {
    group('getAssetPathForPOIType', () {
      test('should return correct asset path for parking type', () {
        final path = POIConfiguration.getAssetPathForPOIType(PoiType.parking);

        expect(path, 'assets/icons/report/parking.png');
      });

      test('should return correct asset path for hazard type', () {
        final path = POIConfiguration.getAssetPathForPOIType(PoiType.hazard);

        expect(path, 'assets/icons/report/hazard.png');
      });

      test('should return correct asset path for toilets type', () {
        final path = POIConfiguration.getAssetPathForPOIType(PoiType.toilets);

        expect(path, 'assets/icons/poi/toilets.png');
      });

      test('should return correct asset path for water type', () {
        final path = POIConfiguration.getAssetPathForPOIType(PoiType.water);

        expect(path, 'assets/icons/poi/water.png');
      });

      test('should return correct asset path for camping type', () {
        final path = POIConfiguration.getAssetPathForPOIType(PoiType.camping);

        expect(path, 'assets/icons/poi/camping.png');
      });

      test('should return correct asset path for animals type', () {
        final path = POIConfiguration.getAssetPathForPOIType(PoiType.animals);

        expect(path, 'assets/icons/poi/pets.png');
      });

      test('should return path that ends with .png', () {
        for (final type in PoiType.values) {
          final path = POIConfiguration.getAssetPathForPOIType(type);
          expect(
            path.endsWith('.png'),
            true,
            reason: 'Path for $type should end with .png',
          );
        }
      });

      test('should return path that starts with assets/icons/', () {
        for (final type in PoiType.values) {
          final path = POIConfiguration.getAssetPathForPOIType(type);
          expect(
            path.startsWith('assets/icons/'),
            true,
            reason: 'Path for $type should start with assets/icons/',
          );
        }
      });

      test('should delegate to PoiType.assetPath extension', () {
        for (final type in PoiType.values) {
          final deprecatedPath = POIConfiguration.getAssetPathForPOIType(type);
          final extensionPath = type.assetPath;

          expect(
            deprecatedPath,
            extensionPath,
            reason:
                'Deprecated method should return same path as extension for $type',
          );
        }
      });
    });

    group('getColorForPOIType', () {
      test('should return correct color for parking type', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.parking);

        expect(color, const Color(0xFF6A89CC));
      });

      test('should return correct color for hazard type', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.hazard);

        expect(color, const Color(0xFFE45039));
      });

      test('should return correct color for toilets type', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.toilets);

        expect(color, const Color(0xFF42A5F5));
      });

      test('should return correct color for water type', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.water);

        expect(color, const Color(0xFF29B6F6));
      });

      test('should return correct color for camping type', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.camping);

        expect(color, const Color(0xFF66BB6A));
      });

      test('should return correct color for animals type', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.animals);

        expect(color, const Color(0xFFFF9800));
      });

      test('should return valid Color objects for all types', () {
        for (final type in PoiType.values) {
          final color = POIConfiguration.getColorForPOIType(type);
          expect(
            color,
            isA<Color>(),
            reason: 'Color for $type should be a valid Color object',
          );
        }
      });

      test('should delegate to PoiType.color extension', () {
        for (final type in PoiType.values) {
          final deprecatedColor = POIConfiguration.getColorForPOIType(type);
          final extensionColor = type.color;

          expect(
            deprecatedColor,
            extensionColor,
            reason:
                'Deprecated method should return same color as extension for $type',
          );
        }
      });

      test('should return colors with proper opacity', () {
        for (final type in PoiType.values) {
          final color = POIConfiguration.getColorForPOIType(type);
          expect(
            color.opacity,
            1.0,
            reason: 'Color for $type should have full opacity',
          );
        }
      });
    });

    group('Color Consistency', () {
      test('parking color should be blue-ish', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.parking);

        // Blue-ish should have blue > red and blue > green
        expect(color.blue, greaterThan(color.red));
      });

      test('hazard color should be red-ish', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.hazard);

        // Red-ish should have red > blue and red > green
        expect(color.red, greaterThan(color.blue));
        expect(color.red, greaterThan(color.green));
      });

      test('camping color should be green-ish', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.camping);

        // Green-ish should have green > red and green > blue
        expect(color.green, greaterThan(color.red));
        expect(color.green, greaterThan(color.blue));
      });

      test('animals color should be orange-ish', () {
        final color = POIConfiguration.getColorForPOIType(PoiType.animals);

        // Orange-ish should have red and green high, blue low
        expect(color.red, greaterThan(color.blue));
        expect(color.green, greaterThan(color.blue));
      });

      test('water colors should be blue variations', () {
        final waterColor = POIConfiguration.getColorForPOIType(PoiType.water);
        final toiletsColor = POIConfiguration.getColorForPOIType(
          PoiType.toilets,
        );

        // Both should have high blue values
        expect(waterColor.blue, greaterThan(150));
        expect(toiletsColor.blue, greaterThan(150));
      });
    });

    group('All POI Types Coverage', () {
      test('should have asset path for all POI types', () {
        for (final type in PoiType.values) {
          expect(
            () => POIConfiguration.getAssetPathForPOIType(type),
            returnsNormally,
            reason: 'Should have asset path for $type',
          );
        }
      });

      test('should have color for all POI types', () {
        for (final type in PoiType.values) {
          expect(
            () => POIConfiguration.getColorForPOIType(type),
            returnsNormally,
            reason: 'Should have color for $type',
          );
        }
      });

      test('asset paths should be unique for each type', () {
        final paths = <String>{};
        for (final type in PoiType.values) {
          final path = POIConfiguration.getAssetPathForPOIType(type);
          expect(
            paths.contains(path),
            false,
            reason: 'Path $path for $type should be unique',
          );
          paths.add(path);
        }
      });

      test('colors should be distinguishable (not identical)', () {
        final colors = <Color>[];
        for (final type in PoiType.values) {
          final color = POIConfiguration.getColorForPOIType(type);
          // Check that this color is not identical to any previous color
          for (final existingColor in colors) {
            expect(
              color.value,
              isNot(equals(existingColor.value)),
              reason: 'Color for $type should be distinguishable',
            );
          }
          colors.add(color);
        }
      });
    });

    group('Deprecation Status', () {
      test('POIConfiguration class should be deprecated', () {
        // This test documents that the class is deprecated
        // The @Deprecated annotation should be present on the class
        expect(POIConfiguration, isNotNull);
      });

      test('getAssetPathForPOIType method should be deprecated', () {
        // This test documents that the method is deprecated
        // The @Deprecated annotation should be present on the method
        expect(
          () => POIConfiguration.getAssetPathForPOIType(PoiType.parking),
          returnsNormally,
        );
      });

      test('getColorForPOIType method should be deprecated', () {
        // This test documents that the method is deprecated
        // The @Deprecated annotation should be present on the method
        expect(
          () => POIConfiguration.getColorForPOIType(PoiType.parking),
          returnsNormally,
        );
      });
    });

    group('Migration to Extension Methods', () {
      test('extension method should produce same asset paths', () {
        // Verify that the new extension methods work correctly as replacements
        expect(PoiType.parking.assetPath, 'assets/icons/report/parking.png');
        expect(PoiType.hazard.assetPath, 'assets/icons/report/hazard.png');
        expect(PoiType.toilets.assetPath, 'assets/icons/poi/toilets.png');
        expect(PoiType.water.assetPath, 'assets/icons/poi/water.png');
        expect(PoiType.camping.assetPath, 'assets/icons/poi/camping.png');
        expect(PoiType.animals.assetPath, 'assets/icons/poi/pets.png');
      });

      test('extension method should produce same colors', () {
        // Verify that the new extension methods work correctly as replacements
        expect(PoiType.parking.color, const Color(0xFF6A89CC));
        expect(PoiType.hazard.color, const Color(0xFFE45039));
        expect(PoiType.toilets.color, const Color(0xFF42A5F5));
        expect(PoiType.water.color, const Color(0xFF29B6F6));
        expect(PoiType.camping.color, const Color(0xFF66BB6A));
        expect(PoiType.animals.color, const Color(0xFFFF9800));
      });
    });
  });
}
