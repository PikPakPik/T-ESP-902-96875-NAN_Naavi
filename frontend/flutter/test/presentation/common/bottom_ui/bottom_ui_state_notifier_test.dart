import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/presentation/common/bottom_ui/BottomUiState.dart';
import 'package:naavi/presentation/common/bottom_ui/BottomUiStateNotifier.dart';
import 'package:naavi/presentation/common/poi_placement/PoiPlacementState.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationState.dart';
import 'package:naavi/presentation/improvise/state/ImproviseHikeState.dart';
import 'package:naavi/presentation/map/state/HomeMapState.dart';
import 'package:naavi/presentation/organized/state/OrganizedHikeState.dart';

void main() {
  late BottomUiStateNotifier notifier;

  gl.Position createPosition() => gl.Position(
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

  setUp(() {
    notifier = BottomUiStateNotifier();
  });

  group('BottomUiStateNotifier - Initial State', () {
    test('should start with BottomUiIdle state', () {
      expect(notifier.state, isA<BottomUiIdle>());
    });
  });

  group('BottomUiStateNotifier - Priority 1: Recap Modal', () {
    test('should show recap when showRecapModal is true', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: true,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiShowingRecap>());
      final state = notifier.state as BottomUiShowingRecap;
      expect(state.fromGuidedHike, isFalse);
    });

    test('should show recap when guided hike is completed', () {
      final segments = [
        [createPosition()],
      ];

      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: GuidedHikeTrackingCompleted(
          segments: segments,
          elapsedSeconds: 1200,
          distanceKm: 5.0,
        ),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiShowingRecap>());
      final state = notifier.state as BottomUiShowingRecap;
      expect(state.fromGuidedHike, isTrue);
      expect(state.segments, equals(segments));
    });
  });

  group('BottomUiStateNotifier - Priority 2: Guided Tracking', () {
    test('should show guided tracking when active', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingActive(
          routeCoordinates: [
            [2.3522, 48.8566],
          ],
          currentWaypointIndex: 0,
          currentDirection: 'Continuez tout droit',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 50.0,
          elapsedSeconds: 120,
          distanceKm: 1.5,
          isPaused: false,
        ),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiShowingGuidedTracking>());
      final state = notifier.state as BottomUiShowingGuidedTracking;
      expect(state.elapsedSeconds, equals(120));
      expect(state.distanceKm, equals(1.5));
      expect(state.isPaused, isFalse);
    });

    test('should not show guided tracking when placing POI', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingActive(
          routeCoordinates: [
            [2.3522, 48.8566],
          ],
          currentWaypointIndex: 0,
          currentDirection: 'Continuez tout droit',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 50.0,
          elapsedSeconds: 120,
          distanceKm: 1.5,
          isPaused: false,
        ),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: true,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      // Should fall through to another state since isPlacingPoi is true
      expect(notifier.state, isNot(isA<BottomUiShowingGuidedTracking>()));
    });
  });

  group('BottomUiStateNotifier - Priority 3: POI Placement', () {
    test('should show POI placement when active', () {
      final position = createPosition();

      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementActive(
          selectedType: PoiType.water,
        ),
        showRecapModal: false,
        isPlacingPoi: true,
        organizedHikeState: const OrganizedHikeIdle(),
        currentPosition: position,
      );

      expect(notifier.state, isA<BottomUiPlacingPoi>());
      final state = notifier.state as BottomUiPlacingPoi;
      expect(state.selectedType, equals(PoiType.water));
    });
  });

  group('BottomUiStateNotifier - Priority 4: Hike Detail', () {
    test('should show hike detail when selected', () {
      final hikeInfo = {'name': 'Test Hike', 'distance': 5.0};

      notifier.updateState(
        homeMapState: HomeMapState.explore,
        selectedHikeInfo: hikeInfo,
        distanceToHikeStart: 3.0,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiShowingHikeDetail>());
      final state = notifier.state as BottomUiShowingHikeDetail;
      expect(state.hikeInfo, equals(hikeInfo));
      expect(state.distanceToStart, equals(3.0));
      expect(state.isNearby, isTrue); // distance <= 5.0
    });

    test('should show hike detail as not nearby when far', () {
      final hikeInfo = {'name': 'Test Hike', 'distance': 5.0};

      notifier.updateState(
        homeMapState: HomeMapState.explore,
        selectedHikeInfo: hikeInfo,
        distanceToHikeStart: 10.0,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiShowingHikeDetail>());
      final state = notifier.state as BottomUiShowingHikeDetail;
      expect(state.isNearby, isFalse); // distance > 5.0
    });
  });

  group('BottomUiStateNotifier - Priority 5: Improvise Controls', () {
    test(
      'should show guided tracking UI in improvise mode with active hike',
      () {
        final position = createPosition();
        final startTime = DateTime.now().subtract(const Duration(minutes: 10));

        notifier.updateState(
          homeMapState: HomeMapState.improvise,
          guidedHikeState: const GuidedHikeTrackingIdle(),
          hikeNavigationState: const HikeNavigationIdle(),
          poiPlacementState: const PoiPlacementIdle(),
          showRecapModal: false,
          isPlacingPoi: false,
          organizedHikeState: const OrganizedHikeIdle(),
          currentPosition: position,
          improviseHikeState: ImproviseHikeActive(
            startPoint: position,
            startTime: startTime,
          ),
          improviseSegments: [
            [position],
          ],
        );

        expect(notifier.state, isA<BottomUiShowingGuidedTracking>());
      },
    );

    test('should show idle in improvise mode without active hike', () {
      final position = createPosition();

      notifier.updateState(
        homeMapState: HomeMapState.improvise,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
        currentPosition: position,
      );

      expect(notifier.state, isA<BottomUiIdle>());
    });

    test('should not show improvise controls when placing POI', () {
      notifier.updateState(
        homeMapState: HomeMapState.improvise,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: true,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isNot(isA<BottomUiShowingGuidedTracking>()));
    });
  });

  group('BottomUiStateNotifier - Priority 6: Hike Mode Buttons', () {
    test('should show hike mode buttons in explore mode', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiShowingHikeModeButtons>());
    });

    test('should not show hike mode buttons when navigating', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 1.0,
          estimatedTimeMinutes: 15.0,
          startLat: 48.8566,
          startLon: 2.3522,
        ),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isNot(isA<BottomUiShowingHikeModeButtons>()));
      expect(notifier.state, isA<BottomUiIdle>());
    });

    test('should not show hike mode buttons when selecting POI type', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementSelectingType(
          showPoiTypeSelection: true,
          showReportTypeSelection: false,
          showPoiCategorySelection: false,
        ),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isNot(isA<BottomUiShowingHikeModeButtons>()));
    });
  });

  group('BottomUiStateNotifier - Utility Methods', () {
    test('showRecap should set recap state', () {
      final segments = [
        [createPosition()],
      ];

      notifier.showRecap(segments: segments, fromGuidedHike: true);

      expect(notifier.state, isA<BottomUiShowingRecap>());
      final state = notifier.state as BottomUiShowingRecap;
      expect(state.segments, equals(segments));
      expect(state.fromGuidedHike, isTrue);
    });

    test('hideRecap should return to idle state', () {
      final segments = [
        [createPosition()],
      ];

      // First show recap
      notifier.showRecap(segments: segments, fromGuidedHike: false);
      expect(notifier.state, isA<BottomUiShowingRecap>());

      // Then hide it
      notifier.hideRecap();
      expect(notifier.state, isA<BottomUiIdle>());
    });
  });

  group('BottomUiStateNotifier - Edge Cases', () {
    test('should default to idle when in organise mode', () {
      notifier.updateState(
        homeMapState: HomeMapState.organise,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiIdle>());
    });

    test('should handle improvise finished state for recap', () {
      final position = createPosition();
      final now = DateTime.now();
      final segments = [
        [position],
      ];

      notifier.updateState(
        homeMapState: HomeMapState.improvise,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        improviseHikeState: ImproviseHikeFinished(
          segments: segments,
          startPoint: position,
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now,
          distanceKm: 5.0,
          duration: const Duration(hours: 1),
        ),
        hikeNavigationState: const HikeNavigationIdle(),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: true,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      expect(notifier.state, isA<BottomUiShowingRecap>());
      final state = notifier.state as BottomUiShowingRecap;
      expect(state.segments, equals(segments));
    });

    test('should handle near start navigation state', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationNearStart(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 0.015,
          startLat: 48.8566,
          startLon: 2.3522,
        ),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      // Should go to idle since isNavigating is true
      expect(notifier.state, isA<BottomUiIdle>());
    });

    test('should handle calculating navigation state', () {
      notifier.updateState(
        homeMapState: HomeMapState.explore,
        guidedHikeState: const GuidedHikeTrackingIdle(),
        hikeNavigationState: const HikeNavigationCalculating(
          startLat: 48.8566,
          startLon: 2.3522,
        ),
        poiPlacementState: const PoiPlacementIdle(),
        showRecapModal: false,
        isPlacingPoi: false,
        organizedHikeState: const OrganizedHikeIdle(),
      );

      // Should go to idle since isNavigating is true
      expect(notifier.state, isA<BottomUiIdle>());
    });
  });
}
