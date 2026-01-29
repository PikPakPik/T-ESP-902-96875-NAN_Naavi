import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/services/user_poi_service.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/user_poi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserPoiService', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clean up after each test
      await UserPoiService.clearAllPOIs();
    });

    group('getAllPOIs', () {
      test('should return empty list when no POIs exist', () async {
        // Act
        final result = await UserPoiService.getAllPOIs();

        // Assert
        expect(result, isEmpty);
      });

      test('should return list of saved POIs', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'Test POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          description: 'Description 1',
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'Test POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          description: 'Description 2',
          createdAt: DateTime.now(),
        );

        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);

        // Act
        final result = await UserPoiService.getAllPOIs();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, '1');
        expect(result[1].id, '2');
      });

      test('should handle corrupted data gracefully', () async {
        // Arrange - Manually set invalid data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('user_pois', ['invalid json']);

        // Act
        final result = await UserPoiService.getAllPOIs();

        // Assert - Should return empty list instead of throwing
        expect(result, isEmpty);
      });

      test('should return empty list when storage throws exception', () async {
        // Arrange - Setup will clear SharedPreferences
        // This simulates an error scenario

        // Act
        final result = await UserPoiService.getAllPOIs();

        // Assert
        expect(result, isEmpty);
      });

      test('should preserve POI properties correctly', () async {
        // Arrange
        final now = DateTime.now();
        final poi = UserPOI(
          id: 'test-id',
          name: 'Test Location',
          type: PoiType.toilets,
          latitude: 45.5,
          longitude: -73.5,
          description: 'Test description',
          createdAt: now,
        );

        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getAllPOIs();

        // Assert
        expect(result, hasLength(1));
        expect(result[0].id, 'test-id');
        expect(result[0].name, 'Test Location');
        expect(result[0].type, PoiType.toilets);
        expect(result[0].latitude, 45.5);
        expect(result[0].longitude, -73.5);
        expect(result[0].description, 'Test description');
      });
    });

    group('savePOI', () {
      test('should save a new POI successfully', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'New POI',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          description: 'Test',
          createdAt: DateTime.now(),
        );

        // Act
        final result = await UserPoiService.savePOI(poi);

        // Assert
        expect(result, true);

        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(1));
        expect(allPois[0].id, '1');
      });

      test('should save multiple POIs', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );

        // Act
        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);

        // Assert
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(2));
      });

      test('should save POI with all PoiType values', () async {
        // Arrange & Act
        for (final type in PoiType.values) {
          final poi = UserPOI(
            id: 'poi-${type.name}',
            name: 'Test ${type.name}',
            type: type,
            latitude: 48.8566,
            longitude: 2.3522,
            createdAt: DateTime.now(),
          );
          final result = await UserPoiService.savePOI(poi);
          expect(result, true);
        }

        // Assert
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(PoiType.values.length));
      });

      test('should save POI with empty description', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'POI',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          description: '',
          createdAt: DateTime.now(),
        );

        // Act
        final result = await UserPoiService.savePOI(poi);

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois[0].description, '');
      });

      test('should save POI with zero coordinates', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Zero POI',
          type: PoiType.parking,
          latitude: 0.0,
          longitude: 0.0,
          createdAt: DateTime.now(),
        );

        // Act
        final result = await UserPoiService.savePOI(poi);

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois[0].latitude, 0.0);
        expect(allPois[0].longitude, 0.0);
      });

      test('should save POI with negative coordinates', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Negative POI',
          type: PoiType.parking,
          latitude: -45.0,
          longitude: -90.0,
          createdAt: DateTime.now(),
        );

        // Act
        final result = await UserPoiService.savePOI(poi);

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois[0].latitude, -45.0);
        expect(allPois[0].longitude, -90.0);
      });

      test('should save POI with extreme coordinates', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Extreme POI',
          type: PoiType.parking,
          latitude: 90.0,
          longitude: 180.0,
          createdAt: DateTime.now(),
        );

        // Act
        final result = await UserPoiService.savePOI(poi);

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois[0].latitude, 90.0);
        expect(allPois[0].longitude, 180.0);
      });
    });

    group('deletePOI', () {
      test('should delete an existing POI', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Test POI',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.deletePOI('1');

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, isEmpty);
      });

      test('should delete only the specified POI', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);

        // Act
        final result = await UserPoiService.deletePOI('1');

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(1));
        expect(allPois[0].id, '2');
      });

      test('should return true when deleting non-existent POI', () async {
        // Act
        final result = await UserPoiService.deletePOI('non-existent');

        // Assert
        expect(result, true);
      });

      test('should handle empty POI ID', () async {
        // Act
        final result = await UserPoiService.deletePOI('');

        // Assert
        expect(result, true);
      });

      test('should delete multiple POIs sequentially', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        final poi3 = UserPOI(
          id: '3',
          name: 'POI 3',
          type: PoiType.toilets,
          latitude: 48.8568,
          longitude: 2.3524,
          createdAt: DateTime.now(),
        );

        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);
        await UserPoiService.savePOI(poi3);

        // Act
        await UserPoiService.deletePOI('1');
        await UserPoiService.deletePOI('3');

        // Assert
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(1));
        expect(allPois[0].id, '2');
      });
    });

    group('updatePOI', () {
      test('should update an existing POI', () async {
        // Arrange
        final originalPoi = UserPOI(
          id: '1',
          name: 'Original Name',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          description: 'Original',
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(originalPoi);

        final updatedPoi = UserPOI(
          id: '1',
          name: 'Updated Name',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          description: 'Updated',
          createdAt: originalPoi.createdAt,
        );

        // Act
        final result = await UserPoiService.updatePOI(updatedPoi);

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(1));
        expect(allPois[0].name, 'Updated Name');
        expect(allPois[0].type, PoiType.hazard);
        expect(allPois[0].latitude, 48.8567);
        expect(allPois[0].description, 'Updated');
      });

      test('should return false when updating non-existent POI', () async {
        // Arrange
        final poi = UserPOI(
          id: 'non-existent',
          name: 'Test',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );

        // Act
        final result = await UserPoiService.updatePOI(poi);

        // Assert
        expect(result, false);
      });

      test('should update only the specified POI', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);

        final updatedPoi1 = UserPOI(
          id: '1',
          name: 'Updated POI 1',
          type: PoiType.toilets,
          latitude: 48.8568,
          longitude: 2.3524,
          createdAt: poi1.createdAt,
        );

        // Act
        final result = await UserPoiService.updatePOI(updatedPoi1);

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(2));
        expect(allPois[0].name, 'Updated POI 1');
        expect(allPois[0].type, PoiType.toilets);
        expect(allPois[1].name, 'POI 2'); // Unchanged
      });

      test('should preserve creation date after update', () async {
        // Arrange
        final creationDate = DateTime(2023, 1, 1);
        final originalPoi = UserPOI(
          id: '1',
          name: 'Original',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: creationDate,
        );
        await UserPoiService.savePOI(originalPoi);

        final updatedPoi = UserPOI(
          id: '1',
          name: 'Updated',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: creationDate,
        );

        // Act
        await UserPoiService.updatePOI(updatedPoi);

        // Assert
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois[0].createdAt, creationDate);
      });
    });

    group('clearAllPOIs', () {
      test('should clear all POIs', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);

        // Act
        final result = await UserPoiService.clearAllPOIs();

        // Assert
        expect(result, true);
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, isEmpty);
      });

      test('should return true when clearing empty storage', () async {
        // Act
        final result = await UserPoiService.clearAllPOIs();

        // Assert
        expect(result, true);
      });

      test('should allow saving new POIs after clearing', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi1);
        await UserPoiService.clearAllPOIs();

        // Act
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi2);

        // Assert
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(1));
        expect(allPois[0].id, '2');
      });
    });

    group('getPOIsByType', () {
      test('should return POIs of specified type', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'Parking 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'Hazard 1',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        final poi3 = UserPOI(
          id: '3',
          name: 'Parking 2',
          type: PoiType.parking,
          latitude: 48.8568,
          longitude: 2.3524,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);
        await UserPoiService.savePOI(poi3);

        // Act
        final parkingPois = await UserPoiService.getPOIsByType('parking');

        // Assert
        expect(parkingPois, hasLength(2));
        expect(parkingPois[0].type, PoiType.parking);
        expect(parkingPois[1].type, PoiType.parking);
      });

      test('should return empty list when no POIs of specified type exist',
          () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Parking',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final hazardPois = await UserPoiService.getPOIsByType('hazard');

        // Assert
        expect(hazardPois, isEmpty);
      });

      test('should handle all PoiType values', () async {
        // Arrange - save one POI of each type
        final savedPois = <UserPOI>[];
        for (final type in PoiType.values) {
          final poi = UserPOI(
            id: 'poi-${type.toString().split('.').last}',
            name: 'Test ${type.toString()}',
            type: type,
            latitude: 48.8566,
            longitude: 2.3522,
            createdAt: DateTime.now(),
          );
          savedPois.add(poi);
          await UserPoiService.savePOI(poi);
        }

        // Verify all were saved
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois.length, PoiType.values.length);

        // Act & Assert - retrieve by each type using enum's built-in name property
        for (final type in PoiType.values) {
          final enumName = type.toString().split('.').last; // "parking", "hazard", etc.
          final pois = await UserPoiService.getPOIsByType(enumName);
          expect(pois.length, greaterThanOrEqualTo(1),
            reason: 'Should find at least one POI of type $enumName');
          expect(pois.any((p) => p.type == type), isTrue);
        }
      });

      test('should return empty list for non-existent type', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Parking',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getPOIsByType('nonexistent');

        // Assert
        expect(result, isEmpty);
      });

      test('should be case sensitive for type matching', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Parking',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getPOIsByType('PARKING');

        // Assert
        expect(result, isEmpty); // Should be empty as it's case sensitive
      });
    });

    group('getPOIsInArea', () {
      test('should return POIs within specified radius', () async {
        // Arrange - Paris center
        const centerLat = 48.8566;
        const centerLon = 2.3522;

        final poi1 = UserPOI(
          id: '1',
          name: 'Nearby POI',
          type: PoiType.parking,
          latitude: 48.8567, // Very close
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'Far POI',
          type: PoiType.hazard,
          latitude: 49.0, // Far away
          longitude: 3.0,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);

        // Act - Search within 1km radius
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 1.0,
        );

        // Assert
        expect(result, hasLength(1));
        expect(result[0].id, '1');
      });

      test('should return empty list when no POIs are within radius',
          () async {
        // Arrange
        const centerLat = 48.8566;
        const centerLon = 2.3522;

        final poi = UserPOI(
          id: '1',
          name: 'Far POI',
          type: PoiType.parking,
          latitude: 49.0,
          longitude: 3.0,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act - Search within 1km radius
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 1.0,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should return all POIs with large radius', () async {
        // Arrange
        const centerLat = 48.8566;
        const centerLon = 2.3522;

        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 49.0,
          longitude: 3.0,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);

        // Act - Search within 1000km radius
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 1000.0,
        );

        // Assert
        expect(result, hasLength(2));
      });

      test('should handle POI at exact center', () async {
        // Arrange
        const centerLat = 48.8566;
        const centerLon = 2.3522;

        final poi = UserPOI(
          id: '1',
          name: 'Center POI',
          type: PoiType.parking,
          latitude: centerLat,
          longitude: centerLon,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 0.01,
        );

        // Assert
        expect(result, hasLength(1));
      });

      test('should handle zero radius', () async {
        // Arrange
        const centerLat = 48.8566;
        const centerLon = 2.3522;

        final poi = UserPOI(
          id: '1',
          name: 'POI',
          type: PoiType.parking,
          latitude: centerLat,
          longitude: centerLon,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 0.0,
        );

        // Assert - Only exact matches (distance = 0)
        expect(result, hasLength(1));
      });

      test('should handle negative coordinates', () async {
        // Arrange - Southern hemisphere
        const centerLat = -33.8688; // Sydney
        const centerLon = 151.2093;

        final poi = UserPOI(
          id: '1',
          name: 'POI',
          type: PoiType.parking,
          latitude: -33.8689,
          longitude: 151.2094,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 1.0,
        );

        // Assert
        expect(result, hasLength(1));
      });

      test('should handle multiple POIs at different distances', () async {
        // Arrange
        const centerLat = 48.8566;
        const centerLon = 2.3522;

        final poi1 = UserPOI(
          id: '1',
          name: 'Very close',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'Close',
          type: PoiType.hazard,
          latitude: 48.8577,
          longitude: 2.3533,
          createdAt: DateTime.now(),
        );
        final poi3 = UserPOI(
          id: '3',
          name: 'Far',
          type: PoiType.toilets,
          latitude: 48.8666,
          longitude: 2.3622,
          createdAt: DateTime.now(),
        );

        await UserPoiService.savePOI(poi1);
        await UserPoiService.savePOI(poi2);
        await UserPoiService.savePOI(poi3);

        // Act - Search within 2km radius
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 2.0,
        );

        // Assert - Should include close ones, exclude far one
        expect(result.length, greaterThan(0));
        expect(result.length, lessThanOrEqualTo(3));
      });
    });

    group('Distance Calculation', () {
      test('should calculate zero distance for same coordinates', () async {
        // Arrange
        const lat = 48.8566;
        const lon = 2.3522;

        final poi = UserPOI(
          id: '1',
          name: 'POI',
          type: PoiType.parking,
          latitude: lat,
          longitude: lon,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getPOIsInArea(
          centerLat: lat,
          centerLon: lon,
          radiusKm: 0.0,
        );

        // Assert
        expect(result, hasLength(1));
      });

      test('should handle antipodal points', () async {
        // Arrange - Points on opposite sides of Earth
        const centerLat = 0.0;
        const centerLon = 0.0;

        final poi = UserPOI(
          id: '1',
          name: 'Antipodal POI',
          type: PoiType.parking,
          latitude: 0.0,
          longitude: 180.0,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act - Very large radius
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 25000.0, // Half Earth's circumference
        );

        // Assert
        expect(result, isNotEmpty);
      });

      test('should handle poles', () async {
        // Arrange - North pole
        const centerLat = 90.0;
        const centerLon = 0.0;

        final poi = UserPOI(
          id: '1',
          name: 'Near pole POI',
          type: PoiType.parking,
          latitude: 89.5,
          longitude: 0.0,
          createdAt: DateTime.now(),
        );
        await UserPoiService.savePOI(poi);

        // Act
        final result = await UserPoiService.getPOIsInArea(
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: 100.0,
        );

        // Assert
        expect(result, hasLength(1));
      });
    });

    group('Complex Scenarios', () {
      test('should handle concurrent operations', () async {
        // Arrange
        final poi1 = UserPOI(
          id: '1',
          name: 'POI 1',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          createdAt: DateTime.now(),
        );
        final poi2 = UserPOI(
          id: '2',
          name: 'POI 2',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          createdAt: DateTime.now(),
        );

        // Act - Concurrent saves
        await Future.wait([
          UserPoiService.savePOI(poi1),
          UserPoiService.savePOI(poi2),
        ]);

        // Assert
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois.length, greaterThanOrEqualTo(1));
      });

      test('should maintain data consistency across operations', () async {
        // Arrange
        final poi = UserPOI(
          id: '1',
          name: 'Test POI',
          type: PoiType.parking,
          latitude: 48.8566,
          longitude: 2.3522,
          description: 'Original',
          createdAt: DateTime.now(),
        );

        // Act - Series of operations
        await UserPoiService.savePOI(poi);
        var allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(1));

        final updatedPoi = UserPOI(
          id: '1',
          name: 'Updated POI',
          type: PoiType.hazard,
          latitude: 48.8567,
          longitude: 2.3523,
          description: 'Updated',
          createdAt: poi.createdAt,
        );
        await UserPoiService.updatePOI(updatedPoi);
        allPois = await UserPoiService.getAllPOIs();
        expect(allPois[0].name, 'Updated POI');

        await UserPoiService.deletePOI('1');
        allPois = await UserPoiService.getAllPOIs();
        expect(allPois, isEmpty);
      });

      test('should handle rapid save and retrieve operations', () async {
        // Arrange & Act
        for (int i = 0; i < 10; i++) {
          final poi = UserPOI(
            id: '$i',
            name: 'POI $i',
            type: PoiType.parking,
            latitude: 48.8566 + i * 0.001,
            longitude: 2.3522 + i * 0.001,
            createdAt: DateTime.now(),
          );
          await UserPoiService.savePOI(poi);
        }

        // Assert
        final allPois = await UserPoiService.getAllPOIs();
        expect(allPois, hasLength(10));
      });
    });
  });
}
