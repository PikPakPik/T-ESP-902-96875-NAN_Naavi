import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/hike/widget/poi_section.dart';

void main() {
  group('POISection', () {
    testWidgets('should display all POI categories with correct counts', (
      tester,
    ) async {
      const counts = {
        'PARKING': 5,
        'WATER': 3,
        'TOILET': 2,
        'MUST_SEE_SPOT': 1,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: const POISection(counts: counts),
          ),
        ),
      );

      // Vérifier que les textes sont présents
      expect(find.text('Parking'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Point d\'eau'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Toilette'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Signalement'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should display zero counts correctly', (tester) async {
      const counts = {
        'PARKING': 0,
        'WATER': 0,
        'TOILET': 0,
        'MUST_SEE_SPOT': 0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: const POISection(counts: counts),
          ),
        ),
      );

      expect(find.text('0'), findsNWidgets(4));
    });

    testWidgets('should handle missing categories with default 0', (
      tester,
    ) async {
      const counts = <String, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: const POISection(counts: counts),
          ),
        ),
      );

      // Tous les compteurs devraient être 0
      expect(find.text('0'), findsNWidgets(4));
    });

    testWidgets('should display correct category names', (tester) async {
      const counts = {
        'PARKING': 1,
        'WATER': 1,
        'TOILET': 1,
        'MUST_SEE_SPOT': 1,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: const POISection(counts: counts),
          ),
        ),
      );

      expect(find.text('Parking'), findsOneWidget);
      expect(find.text('Point d\'eau'), findsOneWidget);
      expect(find.text('Toilette'), findsOneWidget);
      expect(find.text('Signalement'), findsOneWidget);
    });
  });
}
