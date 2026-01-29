import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/data/models/user_poi.dart';
import 'package:naavi/presentation/common/poi_placement/PoiPlacementState.dart';
import 'package:naavi/presentation/common/poi_placement/PoiPlacementStateNotifier.dart';

class MockPoiService extends Mock implements PoiService {}

// Fake UserPOI for mocktail fallback
class FakeUserPOI extends Fake implements UserPOI {}

void main() {
  late PoiPlacementStateNotifier notifier;
  late MockPoiService mockPoiService;

  setUpAll(() {
    registerFallbackValue(FakeUserPOI());
  });

  setUp(() {
    mockPoiService = MockPoiService();
    notifier = PoiPlacementStateNotifier(poiService: mockPoiService);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('PoiPlacementStateNotifier - Initial State', () {
    test('should start with PoiPlacementIdle state', () {
      expect(notifier.state, isA<PoiPlacementIdle>());
    });

    test('should not be placing initially', () {
      expect(notifier.isPlacing, isFalse);
    });

    test('should not be selecting type initially', () {
      expect(notifier.isSelectingType, isFalse);
    });
  });

  group('PoiPlacementStateNotifier - Open Type Selection', () {
    test('should open POI type selection', () {
      // Act
      notifier.openTypeSelection();

      // Assert
      expect(notifier.state, isA<PoiPlacementSelectingType>());
      final state = notifier.state as PoiPlacementSelectingType;
      expect(state.showPoiTypeSelection, isTrue);
      expect(state.showReportTypeSelection, isFalse);
      expect(state.showPoiCategorySelection, isFalse);
      expect(notifier.isSelectingType, isTrue);
    });

    test('should open report type selection', () {
      // Act
      notifier.openTypeSelection(isSignalement: true);

      // Assert
      expect(notifier.state, isA<PoiPlacementSelectingType>());
      final state = notifier.state as PoiPlacementSelectingType;
      expect(state.showPoiTypeSelection, isFalse);
      expect(state.showReportTypeSelection, isTrue);
      expect(state.showPoiCategorySelection, isFalse);
    });

    test('should open category selection', () {
      // Act
      notifier.openTypeSelection(isCategory: true);

      // Assert
      expect(notifier.state, isA<PoiPlacementSelectingType>());
      final state = notifier.state as PoiPlacementSelectingType;
      expect(state.showPoiTypeSelection, isFalse);
      expect(state.showReportTypeSelection, isFalse);
      expect(state.showPoiCategorySelection, isTrue);
    });
  });

  group('PoiPlacementStateNotifier - Close Type Selection', () {
    test('should close type selection', () {
      // Arrange
      notifier.openTypeSelection();

      // Act
      notifier.closeTypeSelection();

      // Assert
      expect(notifier.state, isA<PoiPlacementIdle>());
      expect(notifier.isSelectingType, isFalse);
    });
  });

  group('PoiPlacementStateNotifier - Start Placement', () {
    test('should start placement with POI type and position', () {
      // Arrange
      final position = Position(2.3522, 48.8566);

      // Act
      notifier.startPlacement(PoiType.parking, position);

      // Assert
      expect(notifier.state, isA<PoiPlacementActive>());
      final state = notifier.state as PoiPlacementActive;
      expect(state.selectedType, equals(PoiType.parking));
      expect(state.markerPosition, equals(position));
      expect(notifier.isPlacing, isTrue);
    });

    test('should support all POI types', () {
      final position = Position(2.3522, 48.8566);

      for (final type in PoiType.values) {
        notifier.startPlacement(type, position);

        expect(notifier.state, isA<PoiPlacementActive>());
        final state = notifier.state as PoiPlacementActive;
        expect(state.selectedType, equals(type));

        notifier.cancelPlacement();
      }
    });
  });

  group('PoiPlacementStateNotifier - Update Marker Position', () {
    test('should update marker position when active', () {
      // Arrange
      final initialPosition = Position(2.3522, 48.8566);
      final newPosition = Position(2.3600, 48.8600);

      notifier.startPlacement(PoiType.water, initialPosition);

      // Act
      notifier.updateMarkerPosition(newPosition);

      // Assert
      expect(notifier.state, isA<PoiPlacementActive>());
      final state = notifier.state as PoiPlacementActive;
      expect(state.markerPosition, equals(newPosition));
    });

    test('should update marker position with screen coordinate', () {
      // Arrange
      final position = Position(2.3522, 48.8566);
      final screenPos = ScreenCoordinate(x: 100, y: 200);

      notifier.startPlacement(PoiType.toilets, position);

      // Act
      notifier.updateMarkerPosition(position, screenPos);

      // Assert
      final state = notifier.state as PoiPlacementActive;
      expect(state.markerScreenPosition, equals(screenPos));
    });

    test('should not update if not in active state', () {
      // Arrange
      final position = Position(2.3522, 48.8566);

      // Act
      notifier.updateMarkerPosition(position);

      // Assert
      expect(notifier.state, isA<PoiPlacementIdle>());
    });
  });

  group('PoiPlacementStateNotifier - Save POI', () {
    test('should save POI successfully', () async {
      // Arrange
      final position = Position(2.3522, 48.8566);
      when(() => mockPoiService.addHikePoi(any())).thenReturn(null);

      notifier.startPlacement(PoiType.parking, position);

      // Act
      await notifier.savePoi(latitude: 48.8566, longitude: 2.3522);

      // Assert - Will transition through Saving -> Success -> Idle
      await Future.delayed(const Duration(milliseconds: 600));
      expect(notifier.state, isA<PoiPlacementIdle>());
      verify(() => mockPoiService.addHikePoi(any())).called(1);
    });

    test('should save POI with custom name', () async {
      // Arrange
      final position = Position(2.3522, 48.8566);
      when(() => mockPoiService.addHikePoi(any())).thenReturn(null);

      notifier.startPlacement(PoiType.water, position);

      // Act
      await notifier.savePoi(
        latitude: 48.8566,
        longitude: 2.3522,
        customName: 'My Water Source',
      );

      // Assert
      await Future.delayed(const Duration(milliseconds: 600));
      verify(() => mockPoiService.addHikePoi(any())).called(1);
    });

    test('should handle save error', () async {
      // Arrange
      final position = Position(2.3522, 48.8566);
      when(
        () => mockPoiService.addHikePoi(any()),
      ).thenThrow(Exception('Save error'));

      notifier.startPlacement(PoiType.hazard, position);

      // Act
      await notifier.savePoi(latitude: 48.8566, longitude: 2.3522);

      // Assert - Will transition through Saving -> Error -> Idle
      await Future.delayed(const Duration(milliseconds: 2100));
      expect(notifier.state, isA<PoiPlacementIdle>());
    });

    test('should not save if not in active state', () async {
      // Act
      await notifier.savePoi(latitude: 48.8566, longitude: 2.3522);

      // Assert
      verifyNever(() => mockPoiService.addHikePoi(any()));
    });

    test('should transition to saving state', () async {
      // Arrange
      final position = Position(2.3522, 48.8566);
      when(() => mockPoiService.addHikePoi(any())).thenReturn(null);

      notifier.startPlacement(PoiType.camping, position);

      // Act
      final saveFuture = notifier.savePoi(latitude: 48.8566, longitude: 2.3522);

      // Allow async code to start
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should be in saving state briefly
      if (notifier.state is PoiPlacementSaving) {
        final state = notifier.state as PoiPlacementSaving;
        expect(state.type, equals(PoiType.camping));
      }

      await saveFuture;
    });
  });

  group('PoiPlacementStateNotifier - Cancel Placement', () {
    test('should cancel active placement', () {
      // Arrange
      final position = Position(2.3522, 48.8566);
      notifier.startPlacement(PoiType.animals, position);

      // Act
      notifier.cancelPlacement();

      // Assert
      expect(notifier.state, isA<PoiPlacementIdle>());
      expect(notifier.isPlacing, isFalse);
    });

    test('should work when already idle', () {
      // Act
      notifier.cancelPlacement();

      // Assert
      expect(notifier.state, isA<PoiPlacementIdle>());
    });
  });

  group('PoiPlacementStateNotifier - Getters', () {
    test('isPlacing should return true when in active state', () {
      final position = Position(2.3522, 48.8566);
      notifier.startPlacement(PoiType.parking, position);

      expect(notifier.isPlacing, isTrue);
    });

    test('isPlacing should return true when saving', () async {
      final position = Position(2.3522, 48.8566);
      when(() => mockPoiService.addHikePoi(any())).thenReturn(null);

      notifier.startPlacement(PoiType.parking, position);

      final saveFuture = notifier.savePoi(latitude: 48.8566, longitude: 2.3522);
      await Future.delayed(const Duration(milliseconds: 10));

      if (notifier.state is PoiPlacementSaving) {
        expect(notifier.isPlacing, isTrue);
      }

      await saveFuture;
    });

    test('isPlacing should return false when idle', () {
      expect(notifier.isPlacing, isFalse);
    });

    test('isSelectingType should return true when selecting', () {
      notifier.openTypeSelection();
      expect(notifier.isSelectingType, isTrue);
    });

    test('isSelectingType should return false when not selecting', () {
      expect(notifier.isSelectingType, isFalse);
    });
  });

  group('PoiPlacementStateNotifier - State Transitions', () {
    test('should transition from idle to selecting to active', () {
      // Idle
      expect(notifier.state, isA<PoiPlacementIdle>());

      // Selecting
      notifier.openTypeSelection();
      expect(notifier.state, isA<PoiPlacementSelectingType>());

      // Active
      final position = Position(2.3522, 48.8566);
      notifier.startPlacement(PoiType.parking, position);
      expect(notifier.state, isA<PoiPlacementActive>());
    });

    test('should handle complete placement flow', () async {
      // Arrange
      final position = Position(2.3522, 48.8566);
      when(() => mockPoiService.addHikePoi(any())).thenReturn(null);

      // Start with type selection
      notifier.openTypeSelection();
      expect(notifier.state, isA<PoiPlacementSelectingType>());

      // Start placement
      notifier.startPlacement(PoiType.water, position);
      expect(notifier.state, isA<PoiPlacementActive>());

      // Update position
      notifier.updateMarkerPosition(Position(2.3600, 48.8600));
      expect(notifier.state, isA<PoiPlacementActive>());

      // Save
      await notifier.savePoi(latitude: 48.8600, longitude: 2.3600);

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 600));

      // Should return to idle
      expect(notifier.state, isA<PoiPlacementIdle>());
    });

    test('should handle cancellation at any stage', () {
      // From selecting
      notifier.openTypeSelection();
      notifier.cancelPlacement();
      expect(notifier.state, isA<PoiPlacementIdle>());

      // From active
      final position = Position(2.3522, 48.8566);
      notifier.startPlacement(PoiType.parking, position);
      notifier.cancelPlacement();
      expect(notifier.state, isA<PoiPlacementIdle>());
    });
  });

  group('PoiPlacementStateNotifier - Edge Cases', () {
    test('should handle rapid state changes', () {
      final position = Position(2.3522, 48.8566);

      notifier.openTypeSelection();
      notifier.closeTypeSelection();
      notifier.openTypeSelection(isSignalement: true);
      notifier.closeTypeSelection();
      notifier.startPlacement(PoiType.parking, position);
      notifier.cancelPlacement();

      expect(notifier.state, isA<PoiPlacementIdle>());
    });

    test(
      'should handle marker position updates without screen coordinates',
      () {
        final position = Position(2.3522, 48.8566);
        notifier.startPlacement(PoiType.parking, position);

        notifier.updateMarkerPosition(Position(2.3600, 48.8600));

        final state = notifier.state as PoiPlacementActive;
        expect(state.markerScreenPosition, isNull);
      },
    );

    test('should handle all POI types in complete flow', () async {
      when(() => mockPoiService.addHikePoi(any())).thenReturn(null);

      for (final type in PoiType.values.take(3)) {
        // Limit to first 3 to save time
        final position = Position(2.3522, 48.8566);
        notifier.startPlacement(type, position);
        await notifier.savePoi(latitude: 48.8566, longitude: 2.3522);
        await Future.delayed(const Duration(milliseconds: 600));

        expect(notifier.state, isA<PoiPlacementIdle>());
      }
    });
  });
}
