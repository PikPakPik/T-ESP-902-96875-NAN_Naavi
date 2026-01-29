import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/core/di/BottomUiProvider.dart';
import 'package:naavi/core/di/MapProviders.dart';
import 'package:naavi/presentation/common/bottom_ui/BottomUiState.dart';
import 'package:naavi/presentation/common/bottom_ui/BottomUiStateNotifier.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationState.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BottomUiProvider', () {
    group('bottomUiStateProvider', () {
      test('should provide a BottomUiStateNotifier instance', () {
        final container = ProviderContainer();

        final notifier = container.read(bottomUiStateProvider.notifier);

        expect(notifier, isA<BottomUiStateNotifier>());

        container.dispose();
      });

      test('should initialize with BottomUiIdle state', () {
        final container = ProviderContainer();

        final state = container.read(bottomUiStateProvider);

        expect(state, isA<BottomUiIdle>());

        container.dispose();
      });

      test('should provide the same notifier instance on multiple reads', () {
        final container = ProviderContainer();

        final notifier1 = container.read(bottomUiStateProvider.notifier);
        final notifier2 = container.read(bottomUiStateProvider.notifier);

        expect(notifier1, same(notifier2));

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final notifier1 = container1.read(bottomUiStateProvider.notifier);
        final notifier2 = container2.read(bottomUiStateProvider.notifier);

        expect(notifier1, isNot(same(notifier2)));

        container1.dispose();
        container2.dispose();
      });

      test('should notify listeners when state changes', () {
        final container = ProviderContainer();

        var notificationCount = 0;
        BottomUiState? lastState;

        container.listen(bottomUiStateProvider, (previous, next) {
          notificationCount++;
          lastState = next;
        });

        final notifier = container.read(bottomUiStateProvider.notifier);
        notifier.showRecap(segments: [], fromGuidedHike: false);

        expect(notificationCount, greaterThan(0));
        expect(lastState, isNotNull);

        container.dispose();
      });

      test('should support provider override for testing', () {
        final mockNotifier = BottomUiStateNotifier();
        final container = ProviderContainer(
          overrides: [
            bottomUiStateProvider.overrideWith((ref) => mockNotifier),
          ],
        );

        final notifier = container.read(bottomUiStateProvider.notifier);

        expect(notifier, same(mockNotifier));

        container.dispose();
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer();

        final notifier = container.read(bottomUiStateProvider.notifier);

        expect(notifier.mounted, true);

        container.dispose();

        expect(notifier.mounted, false);
      });

      test('should maintain independent state in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final notifier1 = container1.read(bottomUiStateProvider.notifier);
        notifier1.showRecap(segments: [], fromGuidedHike: false);

        // Container1 should have changed state
        expect(
          container1.read(bottomUiStateProvider),
          isNot(isA<BottomUiIdle>()),
        );

        // Container2 should still have initial state
        expect(container2.read(bottomUiStateProvider), isA<BottomUiIdle>());

        container1.dispose();
        container2.dispose();
      });
    });

    group('isClosingRecapProvider', () {
      test('should initialize with false', () {
        final container = ProviderContainer();

        final state = container.read(isClosingRecapProvider);

        expect(state, false);

        container.dispose();
      });

      test('should update state when changed', () {
        final container = ProviderContainer();

        expect(container.read(isClosingRecapProvider), false);

        container.read(isClosingRecapProvider.notifier).state = true;

        expect(container.read(isClosingRecapProvider), true);

        container.dispose();
      });

      test('should notify listeners when state changes', () {
        final container = ProviderContainer();

        var notificationCount = 0;
        bool? lastValue;

        container.listen(isClosingRecapProvider, (previous, next) {
          notificationCount++;
          lastValue = next;
        });

        container.read(isClosingRecapProvider.notifier).state = true;

        expect(notificationCount, 1);
        expect(lastValue, true);

        container.dispose();
      });

      test('should maintain independent state in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        container1.read(isClosingRecapProvider.notifier).state = true;

        expect(container1.read(isClosingRecapProvider), true);
        expect(container2.read(isClosingRecapProvider), false);

        container1.dispose();
        container2.dispose();
      });

      test('should support toggling state multiple times', () {
        final container = ProviderContainer();

        final notifier = container.read(isClosingRecapProvider.notifier);

        expect(notifier.state, false);

        notifier.state = true;
        expect(notifier.state, true);

        notifier.state = false;
        expect(notifier.state, false);

        notifier.state = true;
        expect(notifier.state, true);

        container.dispose();
      });
    });

    group('isFinishingHikeProvider', () {
      test('should initialize with false', () {
        final container = ProviderContainer();

        final state = container.read(isFinishingHikeProvider);

        expect(state, false);

        container.dispose();
      });

      test('should update state when changed', () {
        final container = ProviderContainer();

        expect(container.read(isFinishingHikeProvider), false);

        container.read(isFinishingHikeProvider.notifier).state = true;

        expect(container.read(isFinishingHikeProvider), true);

        container.dispose();
      });

      test('should notify listeners when state changes', () {
        final container = ProviderContainer();

        var notificationCount = 0;
        bool? lastValue;

        container.listen(isFinishingHikeProvider, (previous, next) {
          notificationCount++;
          lastValue = next;
        });

        container.read(isFinishingHikeProvider.notifier).state = true;

        expect(notificationCount, 1);
        expect(lastValue, true);

        container.dispose();
      });

      test('should maintain independent state in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        container1.read(isFinishingHikeProvider.notifier).state = true;

        expect(container1.read(isFinishingHikeProvider), true);
        expect(container2.read(isFinishingHikeProvider), false);

        container1.dispose();
        container2.dispose();
      });

      test('should support rapid state changes', () {
        final container = ProviderContainer();

        final notifier = container.read(isFinishingHikeProvider.notifier);

        for (int i = 0; i < 10; i++) {
          notifier.state = i % 2 == 0;
        }

        expect(notifier.state, false);

        container.dispose();
      });
    });

    group('guidedTrackingSheetExpandedProvider', () {
      test('should initialize with true', () {
        final container = ProviderContainer();

        final state = container.read(guidedTrackingSheetExpandedProvider);

        expect(state, true);

        container.dispose();
      });

      test('should update state when changed', () {
        final container = ProviderContainer();

        expect(container.read(guidedTrackingSheetExpandedProvider), true);

        container.read(guidedTrackingSheetExpandedProvider.notifier).state =
            false;

        expect(container.read(guidedTrackingSheetExpandedProvider), false);

        container.dispose();
      });

      test('should notify listeners when state changes', () {
        final container = ProviderContainer();

        var notificationCount = 0;
        bool? lastValue;

        container.listen(guidedTrackingSheetExpandedProvider, (previous, next) {
          notificationCount++;
          lastValue = next;
        });

        container.read(guidedTrackingSheetExpandedProvider.notifier).state =
            false;

        expect(notificationCount, 1);
        expect(lastValue, false);

        container.dispose();
      });

      test('should maintain independent state in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        container1.read(guidedTrackingSheetExpandedProvider.notifier).state =
            false;

        expect(container1.read(guidedTrackingSheetExpandedProvider), false);
        expect(container2.read(guidedTrackingSheetExpandedProvider), true);

        container1.dispose();
        container2.dispose();
      });

      test('should toggle between expanded and collapsed states', () {
        final container = ProviderContainer();

        final notifier = container.read(
          guidedTrackingSheetExpandedProvider.notifier,
        );

        expect(notifier.state, true);

        notifier.state = false;
        expect(notifier.state, false);

        notifier.state = true;
        expect(notifier.state, true);

        container.dispose();
      });
    });

    group('bottomUiOverlayProvider', () {
      test('should provide a BottomUiOverlayState instance', () {
        final container = ProviderContainer();

        final overlayState = container.read(bottomUiOverlayProvider);

        expect(overlayState, isA<BottomUiOverlayState>());

        container.dispose();
      });

      test('should initialize with default overlay state', () {
        final container = ProviderContainer();

        final overlayState = container.read(bottomUiOverlayProvider);

        expect(overlayState.showNavigationInfo, false);
        expect(overlayState.showNavigationInstructions, false);
        // showPoiButton is true by default because homeMapState=explore, isPlacingPoi=false, poiPlacementState=idle
        expect(overlayState.showPoiButton, true);
        expect(overlayState.showStartHikeButton, false);

        container.dispose();
      });

      test('should provide the same instance on multiple reads', () {
        final container = ProviderContainer();

        final overlayState1 = container.read(bottomUiOverlayProvider);
        final overlayState2 = container.read(bottomUiOverlayProvider);

        // Same state values
        expect(
          overlayState1.showNavigationInfo,
          overlayState2.showNavigationInfo,
        );

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final overlayState1 = container1.read(bottomUiOverlayProvider);
        final overlayState2 = container2.read(bottomUiOverlayProvider);

        // Different object instances
        expect(identical(overlayState1, overlayState2), false);

        container1.dispose();
        container2.dispose();
      });

      test(
        'should return navigation distance and time when HikeNavigationActive',
        () {
          final container = ProviderContainer();

          // Set HikeNavigationActive state
          final notifier = container.read(hikeNavigationProvider.notifier);
          notifier.state = HikeNavigationActive(
            route: [
              [47.0, -1.0],
              [47.1, -1.1],
            ],
            distanceToStartKm: 2.5,
            estimatedTimeMinutes: 30.0,
            startLat: 47.0,
            startLon: -1.0,
          );

          final overlayState = container.read(bottomUiOverlayProvider);

          expect(overlayState.showNavigationInfo, true);
          expect(overlayState.navigationDistanceKm, 2.5);
          expect(overlayState.navigationTimeMinutes, 30.0);
          expect(overlayState.isNearStartPoint, false);

          container.dispose();
        },
      );

      test(
        'should return current instruction and distance when GuidedHikeTrackingActive',
        () {
          final container = ProviderContainer();

          // Set GuidedHikeTrackingActive state
          final notifier = container.read(guidedHikeTrackingProvider.notifier);
          notifier.state = GuidedHikeTrackingActive(
            routeCoordinates: [
              [47.0, -1.0],
              [47.1, -1.1],
              [47.2, -1.2],
            ],
            currentWaypointIndex: 1,
            currentDirection: 'Tournez à gauche',
            currentDirectionType: DirectionType.left,
            distanceToNextWaypointMeters: 150.0,
            elapsedSeconds: 600,
            distanceKm: 1.5,
          );

          final overlayState = container.read(bottomUiOverlayProvider);

          expect(overlayState.showNavigationInstructions, true);
          expect(overlayState.currentInstruction, 'Tournez à gauche');
          expect(overlayState.distanceToNextPoint, 150.0);

          container.dispose();
        },
      );

      test(
        'should return navigation info without time when HikeNavigationNearStart',
        () {
          final container = ProviderContainer();

          // Set HikeNavigationNearStart state
          final notifier = container.read(hikeNavigationProvider.notifier);
          notifier.state = HikeNavigationNearStart(
            route: [
              [47.0, -1.0],
              [47.1, -1.1],
            ],
            distanceToStartKm: 0.015, // 15 meters
            startLat: 47.0,
            startLon: -1.0,
          );

          final overlayState = container.read(bottomUiOverlayProvider);

          expect(overlayState.showNavigationInfo, true);
          expect(overlayState.navigationDistanceKm, 0.015);
          expect(overlayState.navigationTimeMinutes, isNull);
          expect(overlayState.isNearStartPoint, true);
          expect(overlayState.showStartHikeButton, true);

          container.dispose();
        },
      );
    });

    group('State provider interactions', () {
      test('should handle all loader states independently', () {
        final container = ProviderContainer();

        container.read(isClosingRecapProvider.notifier).state = true;
        container.read(isFinishingHikeProvider.notifier).state = true;
        container.read(guidedTrackingSheetExpandedProvider.notifier).state =
            false;

        expect(container.read(isClosingRecapProvider), true);
        expect(container.read(isFinishingHikeProvider), true);
        expect(container.read(guidedTrackingSheetExpandedProvider), false);

        container.dispose();
      });

      test('should support simultaneous state changes', () {
        final container = ProviderContainer();

        final states = <String, bool>{};

        container.listen(isClosingRecapProvider, (previous, next) {
          states['closingRecap'] = next;
        });

        container.listen(isFinishingHikeProvider, (previous, next) {
          states['finishingHike'] = next;
        });

        container.read(isClosingRecapProvider.notifier).state = true;
        container.read(isFinishingHikeProvider.notifier).state = true;

        expect(states['closingRecap'], true);
        expect(states['finishingHike'], true);

        container.dispose();
      });

      test('should reset all states to initial values', () {
        final container = ProviderContainer();

        // Set all states to non-initial values
        container.read(isClosingRecapProvider.notifier).state = true;
        container.read(isFinishingHikeProvider.notifier).state = true;
        container.read(guidedTrackingSheetExpandedProvider.notifier).state =
            false;

        // Reset to initial values
        container.read(isClosingRecapProvider.notifier).state = false;
        container.read(isFinishingHikeProvider.notifier).state = false;
        container.read(guidedTrackingSheetExpandedProvider.notifier).state =
            true;

        expect(container.read(isClosingRecapProvider), false);
        expect(container.read(isFinishingHikeProvider), false);
        expect(container.read(guidedTrackingSheetExpandedProvider), true);

        container.dispose();
      });
    });

    group('Provider dependency management', () {
      test('should maintain independence between state providers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        container1.read(isClosingRecapProvider.notifier).state = true;
        container2.read(isFinishingHikeProvider.notifier).state = true;

        expect(container1.read(isClosingRecapProvider), true);
        expect(container1.read(isFinishingHikeProvider), false);

        expect(container2.read(isClosingRecapProvider), false);
        expect(container2.read(isFinishingHikeProvider), true);

        container1.dispose();
        container2.dispose();
      });

      test('should support provider overrides', () {
        final container = ProviderContainer(
          overrides: [
            isClosingRecapProvider.overrideWith((ref) => true),
            isFinishingHikeProvider.overrideWith((ref) => true),
          ],
        );

        expect(container.read(isClosingRecapProvider), true);
        expect(container.read(isFinishingHikeProvider), true);

        container.dispose();
      });
    });
  });
}
