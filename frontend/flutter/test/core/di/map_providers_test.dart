import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/di/MapProviders.dart';
import 'package:naavi/core/services/tracking/camera_mode_service.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/core/services/statistics/statistics_service.dart';
import 'package:naavi/core/services/tracking/location_state_notifier.dart';
import 'package:naavi/core/services/tracking/tracking_location_service.dart';
import 'package:naavi/presentation/common/camera/CameraState.dart';
import 'package:naavi/presentation/common/camera/CameraStateNotifier.dart';
import 'package:naavi/presentation/common/compass/CompassState.dart';
import 'package:naavi/presentation/common/compass/CompassStateNotifier.dart';
import 'package:naavi/presentation/common/poi_placement/PoiPlacementState.dart';
import 'package:naavi/presentation/common/poi_placement/PoiPlacementStateNotifier.dart';
import 'package:naavi/presentation/map/state/MapControllerState.dart';
import 'package:naavi/presentation/map/state/MapControllerStateNotifier.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationState.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationStateNotifier.dart';
import 'package:naavi/presentation/guided/state/RouteSelectionState.dart';
import 'package:naavi/presentation/guided/state/RouteSelectionStateNotifier.dart';
import 'package:naavi/presentation/improvise/state/ImproviseHikeState.dart';
import 'package:naavi/presentation/improvise/state/ImproviseHikeStateNotifier.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingStateNotifier.dart';
import 'package:naavi/presentation/explorer/state/ExplorerPageState.dart';
import 'package:naavi/presentation/explorer/state/ExplorerPageStateNotifier.dart';

// Mock classes
class MockCameraModeManager extends Mock implements CameraModeManager {}

class MockPoiService extends Mock implements PoiService {}

class MockStatisticsService extends Mock implements StatisticsService {}

class MockTrackingLocationService extends Mock
    implements TrackingLocationService {}

class MockLocationStateNotifier extends Mock implements LocationStateNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapProviders', () {
    group('cameraModeManagerProvider', () {
      test('should initialize with null', () {
        final container = ProviderContainer();
        final service = container.read(cameraModeManagerProvider);
        expect(service, isNull);
        container.dispose();
      });

      test('should allow setting CameraModeManager', () {
        final container = ProviderContainer();
        final mockManager = MockCameraModeManager();
        container.read(cameraModeManagerProvider.notifier).state = mockManager;
        final service = container.read(cameraModeManagerProvider);
        expect(service, same(mockManager));
        container.dispose();
      });

      test('should notify listeners when state changes', () {
        final container = ProviderContainer();
        final mockManager = MockCameraModeManager();
        var notificationCount = 0;
        CameraModeManager? lastValue;
        container.listen(cameraModeManagerProvider, (previous, next) {
          notificationCount++;
          lastValue = next;
        });
        container.read(cameraModeManagerProvider.notifier).state = mockManager;
        expect(notificationCount, 1);
        expect(lastValue, same(mockManager));
        container.dispose();
      });

      test('should support resetting to null', () {
        final container = ProviderContainer();
        final mockManager = MockCameraModeManager();
        container.read(cameraModeManagerProvider.notifier).state = mockManager;
        expect(container.read(cameraModeManagerProvider), same(mockManager));
        container.read(cameraModeManagerProvider.notifier).state = null;
        expect(container.read(cameraModeManagerProvider), isNull);
        container.dispose();
      });
    });

    group('cameraStateProvider', () {
      test('should provide a CameraStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(cameraStateProvider.notifier);
        expect(notifier, isA<CameraStateNotifier>());
        container.dispose();
      });

      test('should initialize with CameraInitial state', () {
        final container = ProviderContainer();
        final state = container.read(cameraStateProvider);
        expect(state, isA<CameraInitial>());
        container.dispose();
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer();
        final notifier = container.read(cameraStateProvider.notifier);
        expect(notifier.mounted, true);
        container.dispose();
        expect(notifier.mounted, false);
      });
    });

    group('mapControllerProvider', () {
      test('should provide a MapControllerStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(mapControllerProvider.notifier);
        expect(notifier, isA<MapControllerStateNotifier>());
        container.dispose();
      });

      test('should initialize with MapControllerLoading state', () {
        final container = ProviderContainer();
        final state = container.read(mapControllerProvider);
        expect(state, isA<MapControllerLoading>());
        container.dispose();
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer();
        final notifier = container.read(mapControllerProvider.notifier);
        expect(notifier.mounted, true);
        container.dispose();
        expect(notifier.mounted, false);
      });
    });

    group('hikeNavigationProvider', () {
      test('should provide a HikeNavigationStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(hikeNavigationProvider.notifier);
        expect(notifier, isA<HikeNavigationStateNotifier>());
        container.dispose();
      });

      test('should initialize with HikeNavigationIdle state', () {
        final container = ProviderContainer();
        final state = container.read(hikeNavigationProvider);
        expect(state, isA<HikeNavigationIdle>());
        container.dispose();
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer();
        final notifier = container.read(hikeNavigationProvider.notifier);
        expect(notifier.mounted, true);
        container.dispose();
        expect(notifier.mounted, false);
      });
    });

    group('poiPlacementProvider', () {
      test('should provide a PoiPlacementStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(poiPlacementProvider.notifier);
        expect(notifier, isA<PoiPlacementStateNotifier>());
        container.dispose();
      });

      test('should initialize with PoiPlacementIdle state', () {
        final container = ProviderContainer();
        final state = container.read(poiPlacementProvider);
        expect(state, isA<PoiPlacementIdle>());
        container.dispose();
      });

      test('should watch poiServiceProvider', () {
        final mockPoiService = MockPoiService();
        final container = ProviderContainer(
          overrides: [poiServiceProvider.overrideWithValue(mockPoiService)],
        );
        final notifier = container.read(poiPlacementProvider.notifier);
        expect(notifier, isA<PoiPlacementStateNotifier>());
        container.dispose();
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer();
        final notifier = container.read(poiPlacementProvider.notifier);
        expect(notifier.mounted, true);
        container.dispose();
        expect(notifier.mounted, false);
      });
    });

    group('Computed state providers', () {
      group('isMapReadyProvider', () {
        test('should return false when map is loading', () {
          final container = ProviderContainer();
          final isReady = container.read(isMapReadyProvider);
          expect(isReady, false);
          container.dispose();
        });
      });

      group('isUserExploringProvider', () {
        test('should return camera exploration status', () {
          final container = ProviderContainer();
          final isExploring = container.read(isUserExploringProvider);
          expect(isExploring, isA<bool>());
          container.dispose();
        });
      });

      group('isFirstPersonModeProvider', () {
        test('should return first person mode status', () {
          final container = ProviderContainer();
          final isFirstPerson = container.read(isFirstPersonModeProvider);
          expect(isFirstPerson, isA<bool>());
          container.dispose();
        });
      });

      group('isNavigatingToHikeProvider', () {
        test('should return false when navigation is idle', () {
          final container = ProviderContainer();
          final isNavigating = container.read(isNavigatingToHikeProvider);
          expect(isNavigating, false);
          container.dispose();
        });
      });

      group('isPlacingPoiProvider', () {
        test('should return false when POI placement is idle', () {
          final container = ProviderContainer();
          final isPlacing = container.read(isPlacingPoiProvider);
          expect(isPlacing, false);
          container.dispose();
        });
      });
    });

    group('compassProvider', () {
      test('should provide a CompassStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(compassProvider.notifier);
        expect(notifier, isA<CompassStateNotifier>());
        container.dispose();
      });

      test('should initialize with CompassIdle state', () {
        final container = ProviderContainer();
        final state = container.read(compassProvider);
        expect(state, isA<CompassIdle>());
        container.dispose();
      });
    });

    group('routeSelectionProvider', () {
      test('should provide a RouteSelectionStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(routeSelectionProvider.notifier);
        expect(notifier, isA<RouteSelectionStateNotifier>());
        container.dispose();
      });

      test('should initialize with RouteSelectionLoading state', () {
        final container = ProviderContainer();
        final state = container.read(routeSelectionProvider);
        expect(state, isA<RouteSelectionLoading>());
        container.dispose();
      });
    });

    group('improviseHikeProvider', () {
      test('should provide an ImproviseHikeStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(improviseHikeProvider.notifier);
        expect(notifier, isA<ImproviseHikeStateNotifier>());
        container.dispose();
      });

      test('should initialize with ImproviseHikeIdle state', () {
        final container = ProviderContainer();
        final state = container.read(improviseHikeProvider);
        expect(state, isA<ImproviseHikeIdle>());
        container.dispose();
      });
    });

    group('guidedHikeTrackingProvider', () {
      test('should provide a GuidedHikeTrackingStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(guidedHikeTrackingProvider.notifier);
        expect(notifier, isA<GuidedHikeTrackingStateNotifier>());
        container.dispose();
      });

      test('should initialize with GuidedHikeTrackingIdle state', () {
        final container = ProviderContainer();
        final state = container.read(guidedHikeTrackingProvider);
        expect(state, isA<GuidedHikeTrackingIdle>());
        container.dispose();
      });
    });

    group('explorerPageProvider', () {
      test('should provide an ExplorerPageStateNotifier instance', () {
        final container = ProviderContainer();
        final notifier = container.read(explorerPageProvider.notifier);
        expect(notifier, isA<ExplorerPageStateNotifier>());
        container.dispose();
      });

      test('should initialize with ExplorerPageInitial state', () {
        final container = ProviderContainer();
        final state = container.read(explorerPageProvider);
        expect(state, isA<ExplorerPageInitial>());
        container.dispose();
      });
    });

    group('Additional computed states', () {
      group('isCompassActiveProvider', () {
        test('should return false when compass is idle', () {
          final container = ProviderContainer();
          final isActive = container.read(isCompassActiveProvider);
          expect(isActive, false);
          container.dispose();
        });
      });

      group('selectedHikeInfoProvider', () {
        test('should return null when no route is selected', () {
          final container = ProviderContainer();
          final hikeInfo = container.read(selectedHikeInfoProvider);
          expect(hikeInfo, isNull);
          container.dispose();
        });
      });

      group('hasLoadedRoutesProvider', () {
        test('should return false when routes are loading', () {
          final container = ProviderContainer();
          final hasLoaded = container.read(hasLoadedRoutesProvider);
          expect(hasLoaded, false);
          container.dispose();
        });
      });

      group('isImproviseHikeActiveProvider', () {
        test('should return false when improvise hike is idle', () {
          final container = ProviderContainer();
          final isActive = container.read(isImproviseHikeActiveProvider);
          expect(isActive, false);
          container.dispose();
        });
      });

      group('isGuidedHikeActiveProvider', () {
        test('should return false when guided hike is idle', () {
          final container = ProviderContainer();
          final isActive = container.read(isGuidedHikeActiveProvider);
          expect(isActive, false);
          container.dispose();
        });
      });

      group('isGuidedHikeCompletedProvider', () {
        test('should return false when guided hike is idle', () {
          final container = ProviderContainer();
          final isCompleted = container.read(isGuidedHikeCompletedProvider);
          expect(isCompleted, false);
          container.dispose();
        });
      });
    });

    group('selectedHikeInfoProvider', () {
      test(
        'should return null when route state is not RouteSelectionSelected',
        () {
          final container = ProviderContainer();
          final result = container.read(selectedHikeInfoProvider);
          expect(result, isNull);
          container.dispose();
        },
      );

      test(
        'should return selectedHikeInfo when route state is RouteSelectionSelected',
        () {
          final container = ProviderContainer();
          final notifier = container.read(routeSelectionProvider.notifier);

          // Set up selected state
          final selectedInfo = {'name': 'Test Hike', 'distance': 5.0};
          notifier.state = RouteSelectionSelected(
            selectedHikeInfo: selectedInfo,
            allRoutes: [selectedInfo],
            wkbStrings: ['wkb1'],
            routeNames: ['Test Hike'],
          );

          final result = container.read(selectedHikeInfoProvider);
          expect(result, equals(selectedInfo));
          expect(result!['name'], 'Test Hike');
          expect(result['distance'], 5.0);
          container.dispose();
        },
      );
    });

    group('isImproviseHikeStartingProvider', () {
      test('should return false when improvise state is ImproviseHikeIdle', () {
        final container = ProviderContainer();
        final result = container.read(isImproviseHikeStartingProvider);
        expect(result, false);
        container.dispose();
      });

      test(
        'should return true when improvise state is ImproviseHikeStarting',
        () {
          final container = ProviderContainer();
          final notifier = container.read(improviseHikeProvider.notifier);

          // Set to starting state
          notifier.state = const ImproviseHikeStarting();

          final result = container.read(isImproviseHikeStartingProvider);
          expect(result, true);
          container.dispose();
        },
      );

      test(
        'should return false when improvise state is ImproviseHikeActive',
        () {
          final container = ProviderContainer();
          final notifier = container.read(improviseHikeProvider.notifier);

          // Set to active state
          notifier.state = ImproviseHikeActive(
            startPoint: gl.Position(
              latitude: 47.0,
              longitude: -1.0,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
            ),
            startTime: DateTime.now(),
          );

          final result = container.read(isImproviseHikeStartingProvider);
          expect(result, false);
          container.dispose();
        },
      );
    });

    group('Provider dependency chains', () {
      test('should have correct dependencies for all state providers', () {
        final container = ProviderContainer();

        final cameraNotifier = container.read(cameraStateProvider.notifier);
        final mapControllerNotifier = container.read(
          mapControllerProvider.notifier,
        );
        final hikeNavNotifier = container.read(hikeNavigationProvider.notifier);
        final poiPlacementNotifier = container.read(
          poiPlacementProvider.notifier,
        );
        final compassNotifier = container.read(compassProvider.notifier);
        final routeSelectionNotifier = container.read(
          routeSelectionProvider.notifier,
        );
        final improviseNotifier = container.read(
          improviseHikeProvider.notifier,
        );
        final guidedNotifier = container.read(
          guidedHikeTrackingProvider.notifier,
        );
        final explorerNotifier = container.read(explorerPageProvider.notifier);

        expect(cameraNotifier, isA<CameraStateNotifier>());
        expect(mapControllerNotifier, isA<MapControllerStateNotifier>());
        expect(hikeNavNotifier, isA<HikeNavigationStateNotifier>());
        expect(poiPlacementNotifier, isA<PoiPlacementStateNotifier>());
        expect(compassNotifier, isA<CompassStateNotifier>());
        expect(routeSelectionNotifier, isA<RouteSelectionStateNotifier>());
        expect(improviseNotifier, isA<ImproviseHikeStateNotifier>());
        expect(guidedNotifier, isA<GuidedHikeTrackingStateNotifier>());
        expect(explorerNotifier, isA<ExplorerPageStateNotifier>());

        container.dispose();
      });

      test(
        'should maintain provider isolation across different containers',
        () {
          final container1 = ProviderContainer();
          final container2 = ProviderContainer();

          final camera1 = container1.read(cameraStateProvider.notifier);
          final camera2 = container2.read(cameraStateProvider.notifier);

          expect(camera1, isNot(same(camera2)));

          container1.dispose();
          container2.dispose();
        },
      );
    });
  });
}
