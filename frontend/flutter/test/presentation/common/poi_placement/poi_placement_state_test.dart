import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/presentation/common/poi_placement/PoiPlacementState.dart';

void main() {
  group('PoiPlacementIdle', () {
    test('should create idle state', () {
      const state = PoiPlacementIdle();
      expect(state, isA<PoiPlacementState>());
    });
  });

  group('PoiPlacementSelectingType', () {
    test('should create with default values', () {
      const state = PoiPlacementSelectingType();

      expect(state.showPoiTypeSelection, isFalse);
      expect(state.showReportTypeSelection, isFalse);
      expect(state.showPoiCategorySelection, isFalse);
    });

    test('should create showing POI type selection', () {
      const state = PoiPlacementSelectingType(showPoiTypeSelection: true);
      expect(state.showPoiTypeSelection, isTrue);
    });

    test('should create showing report type selection', () {
      const state = PoiPlacementSelectingType(showReportTypeSelection: true);
      expect(state.showReportTypeSelection, isTrue);
    });

    test('should create showing POI category selection', () {
      const state = PoiPlacementSelectingType(showPoiCategorySelection: true);
      expect(state.showPoiCategorySelection, isTrue);
    });

    group('copyWith', () {
      test('should update showPoiTypeSelection', () {
        const original = PoiPlacementSelectingType();
        final updated = original.copyWith(showPoiTypeSelection: true);

        expect(updated.showPoiTypeSelection, isTrue);
        expect(updated.showReportTypeSelection, isFalse);
        expect(updated.showPoiCategorySelection, isFalse);
      });

      test('should update showReportTypeSelection', () {
        const original = PoiPlacementSelectingType();
        final updated = original.copyWith(showReportTypeSelection: true);

        expect(updated.showPoiTypeSelection, isFalse);
        expect(updated.showReportTypeSelection, isTrue);
      });

      test('should update showPoiCategorySelection', () {
        const original = PoiPlacementSelectingType();
        final updated = original.copyWith(showPoiCategorySelection: true);

        expect(updated.showPoiCategorySelection, isTrue);
      });

      test('should update multiple values', () {
        const original = PoiPlacementSelectingType();
        final updated = original.copyWith(
          showPoiTypeSelection: true,
          showReportTypeSelection: true,
        );

        expect(updated.showPoiTypeSelection, isTrue);
        expect(updated.showReportTypeSelection, isTrue);
      });

      test('should preserve values when no parameters provided', () {
        const original = PoiPlacementSelectingType(showPoiTypeSelection: true);
        final updated = original.copyWith();

        expect(updated.showPoiTypeSelection, isTrue);
      });
    });
  });

  group('PoiPlacementActive', () {
    test('should create with POI type', () {
      const state = PoiPlacementActive(selectedType: PoiType.parking);

      expect(state.selectedType, equals(PoiType.parking));
      expect(state.markerPosition, isNull);
      expect(state.markerScreenPosition, isNull);
    });

    test('should support all POI types', () {
      for (final type in PoiType.values) {
        final state = PoiPlacementActive(selectedType: type);
        expect(state.selectedType, equals(type));
      }
    });

    test('should create with marker position', () {
      final position = Position(2.3522, 48.8566);
      final state = PoiPlacementActive(
        selectedType: PoiType.water,
        markerPosition: position,
      );

      expect(state.markerPosition, equals(position));
    });

    test('should create with screen position', () {
      final screenPos = ScreenCoordinate(x: 100, y: 200);
      final state = PoiPlacementActive(
        selectedType: PoiType.toilets,
        markerScreenPosition: screenPos,
      );

      expect(state.markerScreenPosition, equals(screenPos));
    });

    group('copyWith', () {
      test('should update selectedType', () {
        const original = PoiPlacementActive(selectedType: PoiType.parking);
        final updated = original.copyWith(selectedType: PoiType.hazard);

        expect(updated.selectedType, equals(PoiType.hazard));
      });

      test('should update markerPosition', () {
        const original = PoiPlacementActive(selectedType: PoiType.parking);
        final position = Position(2.3522, 48.8566);
        final updated = original.copyWith(markerPosition: position);

        expect(updated.markerPosition, equals(position));
      });

      test('should update markerScreenPosition', () {
        const original = PoiPlacementActive(selectedType: PoiType.parking);
        final screenPos = ScreenCoordinate(x: 50, y: 100);
        final updated = original.copyWith(markerScreenPosition: screenPos);

        expect(updated.markerScreenPosition, equals(screenPos));
      });

      test('should preserve values when no parameters provided', () {
        final position = Position(2.3522, 48.8566);
        final original = PoiPlacementActive(
          selectedType: PoiType.camping,
          markerPosition: position,
        );

        final updated = original.copyWith();

        expect(updated.selectedType, equals(PoiType.camping));
        expect(updated.markerPosition, equals(position));
      });
    });
  });

  group('PoiPlacementSaving', () {
    test('should create with type and position', () {
      final position = Position(2.3522, 48.8566);
      final state = PoiPlacementSaving(
        type: PoiType.animals,
        position: position,
      );

      expect(state.type, equals(PoiType.animals));
      expect(state.position, equals(position));
    });
  });

  group('PoiPlacementSuccess', () {
    test('should create with POI ID', () {
      const state = PoiPlacementSuccess('poi-123');
      expect(state.poiId, equals('poi-123'));
    });

    test('should handle empty POI ID', () {
      const state = PoiPlacementSuccess('');
      expect(state.poiId, isEmpty);
    });
  });

  group('PoiPlacementError', () {
    test('should create with error message', () {
      const state = PoiPlacementError('Failed to save POI');
      expect(state.message, equals('Failed to save POI'));
    });

    test('should handle empty error message', () {
      const state = PoiPlacementError('');
      expect(state.message, isEmpty);
    });
  });

  group('PoiPlacementState type checking', () {
    test('should distinguish between different state types', () {
      const idle = PoiPlacementIdle();
      const selecting = PoiPlacementSelectingType();
      const active = PoiPlacementActive(selectedType: PoiType.parking);
      final saving = PoiPlacementSaving(
        type: PoiType.parking,
        position: Position(0, 0),
      );
      const success = PoiPlacementSuccess('id');
      const error = PoiPlacementError('error');

      expect(idle, isA<PoiPlacementIdle>());
      expect(selecting, isA<PoiPlacementSelectingType>());
      expect(active, isA<PoiPlacementActive>());
      expect(saving, isA<PoiPlacementSaving>());
      expect(success, isA<PoiPlacementSuccess>());
      expect(error, isA<PoiPlacementError>());
    });
  });

  group('PoiPlacement state flow', () {
    test('should represent complete placement flow', () {
      // Start idle
      const step1 = PoiPlacementIdle();
      expect(step1, isA<PoiPlacementIdle>());

      // Select type
      const step2 = PoiPlacementSelectingType(showPoiTypeSelection: true);
      expect(step2.showPoiTypeSelection, isTrue);

      // Active placement
      const step3 = PoiPlacementActive(selectedType: PoiType.parking);
      expect(step3.selectedType, equals(PoiType.parking));

      // Saving
      final step4 = PoiPlacementSaving(
        type: PoiType.parking,
        position: Position(2.3522, 48.8566),
      );
      expect(step4, isA<PoiPlacementSaving>());

      // Success
      const step5 = PoiPlacementSuccess('new-poi-id');
      expect(step5.poiId, equals('new-poi-id'));
    });

    test('should handle error flow', () {
      const step1 = PoiPlacementIdle();
      const step2 = PoiPlacementSelectingType(showPoiTypeSelection: true);
      const step3 = PoiPlacementActive(selectedType: PoiType.hazard);
      const step4Error = PoiPlacementError('Network error');

      expect(step1, isA<PoiPlacementIdle>());
      expect(step2, isA<PoiPlacementSelectingType>());
      expect(step3, isA<PoiPlacementActive>());
      expect(step4Error.message, equals('Network error'));
    });
  });
}
