import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/utils/poi_type.dart';

import '../../test_helpers.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = ignoreOverflowErrors;
  });

  group('PoiType enum', () {
    test('should have all expected values', () {
      expect(PoiType.values.length, equals(6));
      expect(PoiType.values, contains(PoiType.parking));
      expect(PoiType.values, contains(PoiType.hazard));
      expect(PoiType.values, contains(PoiType.toilets));
      expect(PoiType.values, contains(PoiType.water));
      expect(PoiType.values, contains(PoiType.camping));
      expect(PoiType.values, contains(PoiType.animals));
    });
  });

  group('PoiIconTypeExtension - key', () {
    test('parking key should return parking', () {
      expect(PoiType.parking.key, equals('parking'));
    });

    test('hazard key should return hazard', () {
      expect(PoiType.hazard.key, equals('hazard'));
    });

    test('toilets key should return toilets', () {
      expect(PoiType.toilets.key, equals('toilets'));
    });

    test('water key should return water', () {
      expect(PoiType.water.key, equals('water'));
    });

    test('camping key should return camping', () {
      expect(PoiType.camping.key, equals('camping'));
    });

    test('animals key should return animals', () {
      expect(PoiType.animals.key, equals('animals'));
    });
  });

  group('PoiIconTypeExtension - name', () {
    test('parking name should return Parking', () {
      expect(PoiType.parking.name, equals('Parking'));
    });

    test('hazard name should return Danger', () {
      expect(PoiType.hazard.name, equals('Danger'));
    });

    test('toilets name should return Toilettes', () {
      expect(PoiType.toilets.name, equals('Toilettes'));
    });

    test('water name should return Source d\'eau', () {
      expect(PoiType.water.name, equals("Source d'eau"));
    });

    test('camping name should return Camping', () {
      expect(PoiType.camping.name, equals('Camping'));
    });

    test('animals name should return Passage d\'animaux', () {
      expect(PoiType.animals.name, equals("Passage d'animaux"));
    });
  });

  group('PoiIconTypeExtension - color', () {
    test('parking color should be correct', () {
      expect(PoiType.parking.color, equals(const Color(0xFF6A89CC)));
    });

    test('hazard color should be correct', () {
      expect(PoiType.hazard.color, equals(const Color(0xFFE45039)));
    });

    test('toilets color should be correct', () {
      expect(PoiType.toilets.color, equals(const Color(0xFF42A5F5)));
    });

    test('water color should be correct', () {
      expect(PoiType.water.color, equals(const Color(0xFF29B6F6)));
    });

    test('camping color should be correct', () {
      expect(PoiType.camping.color, equals(const Color(0xFF66BB6A)));
    });

    test('animals color should be correct', () {
      expect(PoiType.animals.color, equals(const Color(0xFFFF9800)));
    });
  });

  group('PoiIconTypeExtension - assetPath', () {
    test('parking assetPath should be correct', () {
      expect(
        PoiType.parking.assetPath,
        equals('assets/icons/report/parking.png'),
      );
    });

    test('hazard assetPath should be correct', () {
      expect(
        PoiType.hazard.assetPath,
        equals('assets/icons/report/hazard.png'),
      );
    });

    test('toilets assetPath should be correct', () {
      expect(PoiType.toilets.assetPath, equals('assets/icons/poi/toilets.png'));
    });

    test('water assetPath should be correct', () {
      expect(PoiType.water.assetPath, equals('assets/icons/poi/water.png'));
    });

    test('camping assetPath should be correct', () {
      expect(PoiType.camping.assetPath, equals('assets/icons/poi/camping.png'));
    });

    test('animals assetPath should be correct', () {
      expect(PoiType.animals.assetPath, equals('assets/icons/poi/pets.png'));
    });
  });

  group('PoiIconTypeExtension - icon', () {
    testWidgets('parking icon returns Image widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiType.parking.icon())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('hazard icon returns Image widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiType.hazard.icon())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('toilets icon returns Image widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiType.toilets.icon())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('water icon returns Image widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiType.water.icon())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('camping icon returns Image widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiType.camping.icon())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('animals icon returns Image widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiType.animals.icon())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('icon respects custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiType.water.icon(size: 48))),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, equals(48.0));
      expect(image.height, equals(48.0));
    });
  });

  group('PoiIcons class', () {
    testWidgets('parking static method returns Image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiIcons.parking())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('hazard static method returns Image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiIcons.hazard())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('toilets static method returns Image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiIcons.toilets())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('water static method returns Image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiIcons.water())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('camping static method returns Image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiIcons.camping())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('animals static method returns Image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiIcons.animals())),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('icon methods respect custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PoiIcons.water(size: 32))),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, equals(32.0));
      expect(image.height, equals(32.0));
    });
  });
}
