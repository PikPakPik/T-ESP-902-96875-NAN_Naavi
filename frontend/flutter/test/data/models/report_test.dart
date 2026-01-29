// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/report.dart';

void main() {
  group('Report', () {
    test('should create Report with parking type', () {
      final report = Report(PoiType.parking);

      expect(report.poiType, PoiType.parking);
    });

    test('should create Report with hazard type', () {
      final report = Report(PoiType.hazard);

      expect(report.poiType, PoiType.hazard);
    });

    test('should create Report with toilets type', () {
      final report = Report(PoiType.toilets);

      expect(report.poiType, PoiType.toilets);
    });

    test('should create Report with water type', () {
      final report = Report(PoiType.water);

      expect(report.poiType, PoiType.water);
    });

    test('should create Report with camping type', () {
      final report = Report(PoiType.camping);

      expect(report.poiType, PoiType.camping);
    });

    test('should create Report with animals type', () {
      final report = Report(PoiType.animals);

      expect(report.poiType, PoiType.animals);
    });

    test('should store the exact PoiType provided', () {
      for (final type in PoiType.values) {
        final report = Report(type);
        expect(report.poiType, type);
      }
    });

    group('PoiType Properties', () {
      test('should access PoiType properties through report', () {
        final report = Report(PoiType.hazard);

        expect(report.poiType.key, 'hazard');
        expect(report.poiType.name, 'Danger');
        expect(report.poiType.assetPath, 'assets/icons/report/hazard.png');
      });

      test('should maintain PoiType color information', () {
        final report = Report(PoiType.parking);

        expect(report.poiType.color, isNotNull);
        expect(report.poiType.color.alpha, 255);
      });

      test('should provide access to all PoiType extension methods', () {
        final report = Report(PoiType.water);

        expect(report.poiType.key, 'water');
        expect(report.poiType.name, 'Source d\'eau');
        expect(report.poiType.assetPath, contains('water.png'));
      });
    });

    group('Different POI Types', () {
      test('parking report should have parking characteristics', () {
        final report = Report(PoiType.parking);

        expect(report.poiType, PoiType.parking);
        expect(report.poiType.key, 'parking');
        expect(report.poiType.assetPath, contains('parking.png'));
      });

      test('hazard report should have hazard characteristics', () {
        final report = Report(PoiType.hazard);

        expect(report.poiType, PoiType.hazard);
        expect(report.poiType.key, 'hazard');
        expect(report.poiType.assetPath, contains('hazard.png'));
      });

      test('toilets report should have toilets characteristics', () {
        final report = Report(PoiType.toilets);

        expect(report.poiType, PoiType.toilets);
        expect(report.poiType.key, 'toilets');
        expect(report.poiType.assetPath, contains('toilets.png'));
      });

      test('water report should have water characteristics', () {
        final report = Report(PoiType.water);

        expect(report.poiType, PoiType.water);
        expect(report.poiType.key, 'water');
        expect(report.poiType.assetPath, contains('water.png'));
      });

      test('camping report should have camping characteristics', () {
        final report = Report(PoiType.camping);

        expect(report.poiType, PoiType.camping);
        expect(report.poiType.key, 'camping');
        expect(report.poiType.assetPath, contains('camping.png'));
      });

      test('animals report should have animals characteristics', () {
        final report = Report(PoiType.animals);

        expect(report.poiType, PoiType.animals);
        expect(report.poiType.key, 'animals');
        expect(report.poiType.assetPath, contains('pets.png'));
      });
    });

    group('Report Creation Patterns', () {
      test('should create multiple reports with different types', () {
        final reports = [
          Report(PoiType.parking),
          Report(PoiType.hazard),
          Report(PoiType.water),
        ];

        expect(reports.length, 3);
        expect(reports[0].poiType, PoiType.parking);
        expect(reports[1].poiType, PoiType.hazard);
        expect(reports[2].poiType, PoiType.water);
      });

      test('should create reports for all available types', () {
        final reports = PoiType.values.map((type) => Report(type)).toList();

        expect(reports.length, PoiType.values.length);
        for (int i = 0; i < PoiType.values.length; i++) {
          expect(reports[i].poiType, PoiType.values[i]);
        }
      });

      test('multiple reports of same type should be independent', () {
        final report1 = Report(PoiType.hazard);
        final report2 = Report(PoiType.hazard);

        expect(report1.poiType, report2.poiType);
        expect(identical(report1, report2), false);
      });
    });

    group('Use Cases', () {
      test('should represent a parking report', () {
        final parkingReport = Report(PoiType.parking);

        expect(parkingReport.poiType.name, 'Parking');
        expect(parkingReport.poiType.key, 'parking');
      });

      test('should represent a hazard report', () {
        final hazardReport = Report(PoiType.hazard);

        expect(hazardReport.poiType.name, 'Danger');
        expect(hazardReport.poiType.key, 'hazard');
      });

      test('should represent a water source report', () {
        final waterReport = Report(PoiType.water);

        expect(waterReport.poiType.name, 'Source d\'eau');
        expect(waterReport.poiType.key, 'water');
      });

      test('should represent a toilets report', () {
        final toiletsReport = Report(PoiType.toilets);

        expect(toiletsReport.poiType.name, 'Toilettes');
        expect(toiletsReport.poiType.key, 'toilets');
      });

      test('should represent a camping report', () {
        final campingReport = Report(PoiType.camping);

        expect(campingReport.poiType.name, 'Camping');
        expect(campingReport.poiType.key, 'camping');
      });

      test('should represent an animal sighting report', () {
        final animalsReport = Report(PoiType.animals);

        expect(animalsReport.poiType.name, 'Passage d\'animaux');
        expect(animalsReport.poiType.key, 'animals');
      });
    });

    group('Type Safety', () {
      test('should only accept PoiType values', () {
        // This test ensures type safety at compile time
        expect(() => Report(PoiType.parking), returnsNormally);
        expect(() => Report(PoiType.hazard), returnsNormally);
        expect(() => Report(PoiType.toilets), returnsNormally);
        expect(() => Report(PoiType.water), returnsNormally);
        expect(() => Report(PoiType.camping), returnsNormally);
        expect(() => Report(PoiType.animals), returnsNormally);
      });

      test('poiType should always be a valid PoiType enum value', () {
        for (final type in PoiType.values) {
          final report = Report(type);
          expect(PoiType.values.contains(report.poiType), true);
        }
      });
    });

    group('Report Comparison', () {
      test('reports with same type should have equal poiType', () {
        final report1 = Report(PoiType.parking);
        final report2 = Report(PoiType.parking);

        expect(report1.poiType, report2.poiType);
      });

      test('reports with different types should have different poiType', () {
        final report1 = Report(PoiType.parking);
        final report2 = Report(PoiType.hazard);

        expect(report1.poiType, isNot(equals(report2.poiType)));
      });

      test('should distinguish between all POI types', () {
        final reports = PoiType.values.map((type) => Report(type)).toList();

        for (int i = 0; i < reports.length; i++) {
          for (int j = i + 1; j < reports.length; j++) {
            expect(
              reports[i].poiType,
              isNot(equals(reports[j].poiType)),
              reason:
                  'Report $i (${reports[i].poiType}) should differ from report $j (${reports[j].poiType})',
            );
          }
        }
      });
    });

    group('Integration with PoiType', () {
      test('should work with PoiType icon extension', () {
        final report = Report(PoiType.parking);

        expect(() => report.poiType.icon(), returnsNormally);
      });

      test('should work with PoiType color extension', () {
        final report = Report(PoiType.hazard);

        expect(report.poiType.color, isNotNull);
        expect(report.poiType.color.alpha, greaterThan(0));
      });

      test('should work with PoiType assetPath extension', () {
        final report = Report(PoiType.water);

        expect(report.poiType.assetPath, isNotEmpty);
        expect(report.poiType.assetPath, startsWith('assets/'));
      });

      test('should work with PoiType key extension', () {
        final report = Report(PoiType.camping);

        expect(report.poiType.key, isNotEmpty);
        expect(report.poiType.key, 'camping');
      });

      test('should work with PoiType name extension', () {
        final report = Report(PoiType.animals);

        expect(report.poiType.name, isNotEmpty);
        expect(report.poiType.name, 'Passage d\'animaux');
      });
    });

    group('Practical Scenarios', () {
      test('should create report list from user selections', () {
        final selectedTypes = [PoiType.parking, PoiType.water, PoiType.toilets];

        final reports = selectedTypes.map((type) => Report(type)).toList();

        expect(reports.length, 3);
        expect(reports[0].poiType, PoiType.parking);
        expect(reports[1].poiType, PoiType.water);
        expect(reports[2].poiType, PoiType.toilets);
      });

      test('should filter reports by type', () {
        final allReports = [
          Report(PoiType.parking),
          Report(PoiType.hazard),
          Report(PoiType.parking),
          Report(PoiType.water),
          Report(PoiType.parking),
        ];

        final parkingReports = allReports
            .where((r) => r.poiType == PoiType.parking)
            .toList();

        expect(parkingReports.length, 3);
        expect(parkingReports.every((r) => r.poiType == PoiType.parking), true);
      });

      test('should group reports by type', () {
        final reports = [
          Report(PoiType.hazard),
          Report(PoiType.parking),
          Report(PoiType.hazard),
          Report(PoiType.water),
        ];

        final groupedByType = <PoiType, List<Report>>{};
        for (final report in reports) {
          groupedByType.putIfAbsent(report.poiType, () => []).add(report);
        }

        expect(groupedByType[PoiType.hazard]?.length, 2);
        expect(groupedByType[PoiType.parking]?.length, 1);
        expect(groupedByType[PoiType.water]?.length, 1);
      });

      test('should count reports by type', () {
        final reports = [
          Report(PoiType.parking),
          Report(PoiType.parking),
          Report(PoiType.hazard),
          Report(PoiType.water),
          Report(PoiType.parking),
        ];

        final parkingCount = reports
            .where((r) => r.poiType == PoiType.parking)
            .length;
        final hazardCount = reports
            .where((r) => r.poiType == PoiType.hazard)
            .length;

        expect(parkingCount, 3);
        expect(hazardCount, 1);
      });
    });
  });
}
