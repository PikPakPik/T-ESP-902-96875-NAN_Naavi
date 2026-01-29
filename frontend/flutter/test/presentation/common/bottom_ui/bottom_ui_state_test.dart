import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/presentation/common/bottom_ui/BottomUiState.dart';

void main() {
  group('BottomUiIdle', () {
    test('should create idle state', () {
      const state = BottomUiIdle();
      expect(state, isA<BottomUiState>());
    });
  });

  group('BottomUiShowingHikeDetail', () {
    test('should create with hike info', () {
      final state = BottomUiShowingHikeDetail(
        hikeInfo: {'name': 'Test Hike', 'distance': 5.0},
        distanceToStart: 1.5,
        isNearby: true,
      );

      expect(state.hikeInfo['name'], equals('Test Hike'));
      expect(state.distanceToStart, equals(1.5));
      expect(state.isNearby, isTrue);
    });

    test('should handle null distance', () {
      const state = BottomUiShowingHikeDetail(
        hikeInfo: {},
        isNearby: false,
      );

      expect(state.distanceToStart, isNull);
      expect(state.isNearby, isFalse);
    });
  });

  group('BottomUiShowingGuidedTracking', () {
    test('should create with tracking data', () {
      const state = BottomUiShowingGuidedTracking(
        elapsedSeconds: 3600,
        distanceKm: 5.2,
        isPaused: false,
        currentDirection: 'Turn right',
        distanceToNextWaypointMeters: 150.0,
      );

      expect(state.elapsedSeconds, equals(3600));
      expect(state.distanceKm, equals(5.2));
      expect(state.isPaused, isFalse);
      expect(state.currentDirection, equals('Turn right'));
      expect(state.distanceToNextWaypointMeters, equals(150.0));
    });

    test('should handle paused state', () {
      const state = BottomUiShowingGuidedTracking(
        elapsedSeconds: 1800,
        distanceKm: 2.5,
        isPaused: true,
        currentDirection: '',
        distanceToNextWaypointMeters: 0,
      );

      expect(state.isPaused, isTrue);
    });
  });

  group('BottomUiShowingHikeModeButtons', () {
    test('should create mode buttons state', () {
      const state = BottomUiShowingHikeModeButtons();
      expect(state, isA<BottomUiState>());
    });
  });

  group('BottomUiShowingImproviseControls', () {
    test('should create without position', () {
      const state = BottomUiShowingImproviseControls();
      expect(state.currentPosition, isNull);
    });

    test('should create with position', () {
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      final state = BottomUiShowingImproviseControls(currentPosition: position);
      expect(state.currentPosition, equals(position));
    });
  });

  group('BottomUiShowingRecap', () {
    test('should create with segments from guided hike', () {
      final segments = [
        [
          gl.Position(
            latitude: 48.8566,
            longitude: 2.3522,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 100,
            altitudeAccuracy: 5,
            heading: 0,
            headingAccuracy: 1,
            speed: 0,
            speedAccuracy: 1,
          ),
        ],
      ];

      final state = BottomUiShowingRecap(
        segments: segments,
        fromGuidedHike: true,
      );

      expect(state.segments.length, equals(1));
      expect(state.fromGuidedHike, isTrue);
    });

    test('should create with empty segments', () {
      const state = BottomUiShowingRecap(
        segments: [],
        fromGuidedHike: false,
      );

      expect(state.segments, isEmpty);
      expect(state.fromGuidedHike, isFalse);
    });
  });

  group('BottomUiPlacingPoi', () {
    test('should create with POI placement data', () {
      const state = BottomUiPlacingPoi(
        selectedType: PoiType.parking,
        initialLatitude: 48.8566,
        initialLongitude: 2.3522,
      );

      expect(state.selectedType, equals(PoiType.parking));
      expect(state.initialLatitude, equals(48.8566));
      expect(state.initialLongitude, equals(2.3522));
    });

    test('should support all POI types', () {
      for (final type in PoiType.values) {
        final state = BottomUiPlacingPoi(
          selectedType: type,
          initialLatitude: 0.0,
          initialLongitude: 0.0,
        );
        expect(state.selectedType, equals(type));
      }
    });
  });

  group('BottomUiOverlayState', () {
    test('should create with default values', () {
      const state = BottomUiOverlayState();

      expect(state.showNavigationInfo, isFalse);
      expect(state.navigationDistanceKm, isNull);
      expect(state.navigationTimeMinutes, isNull);
      expect(state.showNavigationInstructions, isFalse);
      expect(state.currentInstruction, isNull);
      expect(state.distanceToNextPoint, isNull);
      expect(state.showPoiButton, isFalse);
      expect(state.showStartHikeButton, isFalse);
      expect(state.isNearStartPoint, isFalse);
    });

    test('should create with custom values', () {
      const state = BottomUiOverlayState(
        showNavigationInfo: true,
        navigationDistanceKm: 5.5,
        navigationTimeMinutes: 90.0,
        showNavigationInstructions: true,
        currentInstruction: 'Turn left in 100m',
        distanceToNextPoint: 100.0,
        showPoiButton: true,
        showStartHikeButton: true,
        isNearStartPoint: true,
      );

      expect(state.showNavigationInfo, isTrue);
      expect(state.navigationDistanceKm, equals(5.5));
      expect(state.navigationTimeMinutes, equals(90.0));
      expect(state.showNavigationInstructions, isTrue);
      expect(state.currentInstruction, equals('Turn left in 100m'));
      expect(state.distanceToNextPoint, equals(100.0));
      expect(state.showPoiButton, isTrue);
      expect(state.showStartHikeButton, isTrue);
      expect(state.isNearStartPoint, isTrue);
    });

    group('copyWith', () {
      test('should update showNavigationInfo', () {
        const original = BottomUiOverlayState();
        final updated = original.copyWith(showNavigationInfo: true);

        expect(updated.showNavigationInfo, isTrue);
        expect(updated.showPoiButton, isFalse);
      });

      test('should update navigation distance and time', () {
        const original = BottomUiOverlayState();
        final updated = original.copyWith(
          navigationDistanceKm: 10.0,
          navigationTimeMinutes: 120.0,
        );

        expect(updated.navigationDistanceKm, equals(10.0));
        expect(updated.navigationTimeMinutes, equals(120.0));
      });

      test('should update navigation instructions', () {
        const original = BottomUiOverlayState();
        final updated = original.copyWith(
          showNavigationInstructions: true,
          currentInstruction: 'Continue straight',
          distanceToNextPoint: 500.0,
        );

        expect(updated.showNavigationInstructions, isTrue);
        expect(updated.currentInstruction, equals('Continue straight'));
        expect(updated.distanceToNextPoint, equals(500.0));
      });

      test('should update button visibility', () {
        const original = BottomUiOverlayState();
        final updated = original.copyWith(
          showPoiButton: true,
          showStartHikeButton: true,
        );

        expect(updated.showPoiButton, isTrue);
        expect(updated.showStartHikeButton, isTrue);
      });

      test('should update isNearStartPoint', () {
        const original = BottomUiOverlayState();
        final updated = original.copyWith(isNearStartPoint: true);

        expect(updated.isNearStartPoint, isTrue);
      });

      test('should preserve values when no parameters provided', () {
        const original = BottomUiOverlayState(
          showNavigationInfo: true,
          navigationDistanceKm: 5.0,
        );

        final updated = original.copyWith();

        expect(updated.showNavigationInfo, isTrue);
        expect(updated.navigationDistanceKm, equals(5.0));
      });

      test('should create new instance not modify original', () {
        const original = BottomUiOverlayState(showPoiButton: false);
        final updated = original.copyWith(showPoiButton: true);

        expect(original.showPoiButton, isFalse);
        expect(updated.showPoiButton, isTrue);
      });
    });
  });

  group('BottomUiState type checking', () {
    test('should distinguish between different state types', () {
      const idle = BottomUiIdle();
      const hikeDetail = BottomUiShowingHikeDetail(
        hikeInfo: {},
        isNearby: false,
      );
      const guided = BottomUiShowingGuidedTracking(
        elapsedSeconds: 0,
        distanceKm: 0,
        isPaused: false,
        currentDirection: '',
        distanceToNextWaypointMeters: 0,
      );
      const modeButtons = BottomUiShowingHikeModeButtons();
      const improvise = BottomUiShowingImproviseControls();
      const recap = BottomUiShowingRecap(segments: [], fromGuidedHike: false);
      const placing = BottomUiPlacingPoi(
        selectedType: PoiType.parking,
        initialLatitude: 0,
        initialLongitude: 0,
      );

      expect(idle, isA<BottomUiIdle>());
      expect(hikeDetail, isA<BottomUiShowingHikeDetail>());
      expect(guided, isA<BottomUiShowingGuidedTracking>());
      expect(modeButtons, isA<BottomUiShowingHikeModeButtons>());
      expect(improvise, isA<BottomUiShowingImproviseControls>());
      expect(recap, isA<BottomUiShowingRecap>());
      expect(placing, isA<BottomUiPlacingPoi>());
    });
  });
}
