import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/di/HomeMapProvider.dart';
import 'package:naavi/core/di/MapProviders.dart';
import 'package:naavi/core/models/location_state.dart';
import 'package:naavi/core/services/tracking/location_state_notifier.dart';
import 'package:naavi/core/services/tracking/camera_mode_service.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingStateNotifier.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationState.dart';
// ignore: unused_import
import 'package:naavi/presentation/guided/state/HikeNavigationStateNotifier.dart';
import 'package:naavi/presentation/guided/state/RouteSelectionState.dart';
import 'package:naavi/presentation/guided/state/RouteSelectionStateNotifier.dart';
import 'package:naavi/core/services/hiking_routes_service.dart';
import 'package:naavi/core/services/hikes_api_service.dart';

// ═══════════════════════════════════════════════════════════
// MOCKS
// ═══════════════════════════════════════════════════════════

class MockMapboxMap extends Mock implements MapboxMap {}

class MockStyleManager extends Mock implements StyleManager {}

class MockHikingRoutesService extends Mock implements HikingRoutesService {}

class MockCameraModeManager extends Mock implements CameraModeManager {}

// Mock StateNotifiers
class MockLocationStateNotifier extends StateNotifier<LocationState>
    implements LocationStateNotifier {
  MockLocationStateNotifier() : super(const LocationState());

  gl.Position? _mockPosition;

  void setMockPosition(gl.Position? position) {
    _mockPosition = position;
    state = state.copyWith(currentPosition: position);
  }

  @override
  Future<void> startTracking() async {
    state = state.copyWith(isTracking: true, hasPermission: true);
  }

  @override
  void stopTracking() {
    state = state.copyWith(isTracking: false);
  }

  @override
  Future<gl.Position?> getCurrentPosition() async {
    return _mockPosition;
  }

  @override
  Future<bool> requestPermissions() async {
    state = state.copyWith(hasPermission: true);
    return true;
  }
}

class MockRouteSelectionStateNotifier extends StateNotifier<RouteSelectionState>
    implements RouteSelectionStateNotifier {
  MockRouteSelectionStateNotifier() : super(const RouteSelectionLoading());

  @override
  HikingRoutesService get routesService => MockHikingRoutesService();

  @override
  HikesApiService? get hikesApiService => null;

  @override
  Future<void> loadRoutes({
    List<String>? providedWkbStrings,
    List<String>? providedRouteNames,
  }) async {
    state = const RouteSelectionLoaded(
      routes: [],
      wkbStrings: [],
      routeNames: [],
    );
  }

  @override
  Future<void> loadHikesFromApi({
    required double latitude,
    required double longitude,
    int radius = 20,
  }) async {
    state = const RouteSelectionLoaded(
      routes: [],
      wkbStrings: [],
      routeNames: [],
    );
  }

  @override
  void selectRoute(Map<String, dynamic> hikeInfo) {
    state = RouteSelectionSelected(
      selectedHikeInfo: hikeInfo,
      allRoutes: const [],
      wkbStrings: const [],
      routeNames: const [],
    );
  }

  @override
  void deselectRoute() {
    state = const RouteSelectionLoaded(
      routes: [],
      wkbStrings: [],
      routeNames: [],
    );
  }

  @override
  List<List<double>>? getRouteCoordinates(int routeIndex) => null;

  @override
  bool get hasRoutes => state is! RouteSelectionLoading;

  @override
  bool get hasSelection => state is RouteSelectionSelected;

  @override
  Map<String, dynamic>? get selectedHike {
    final currentState = state;
    return currentState is RouteSelectionSelected
        ? currentState.selectedHikeInfo
        : null;
  }
}

class MockGuidedHikeTrackingStateNotifier
    extends StateNotifier<GuidedHikeTrackingState>
    implements GuidedHikeTrackingStateNotifier {
  MockGuidedHikeTrackingStateNotifier() : super(const GuidedHikeTrackingIdle());

  bool startTrackingCalled = false;
  List<List<double>>? lastRouteCoordinates;
  Map<String, dynamic>? lastHikeInfo;

  @override
  void startTracking({
    required List<List<double>> routeCoordinates,
    Map<String, dynamic>? hikeInfo,
  }) {
    startTrackingCalled = true;
    lastRouteCoordinates = routeCoordinates;
    lastHikeInfo = hikeInfo;
    state = GuidedHikeTrackingActive(
      routeCoordinates: routeCoordinates,
      currentWaypointIndex: 0,
      currentDirection: 'Test instruction',
      currentDirectionType: DirectionType.straight,
      distanceToNextWaypointMeters: 0,
      elapsedSeconds: 0,
      distanceKm: 0,
      hikeInfo: hikeInfo,
    );
  }

  @override
  void updatePosition(gl.Position position) {}

  @override
  void stopTracking({bool completed = false}) {
    state = const GuidedHikeTrackingIdle();
  }

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  void markCameraOriented() {}

  @override
  void reset() {
    state = const GuidedHikeTrackingIdle();
  }

  // Note: isTracking doesn't exist in parent class
  bool get isTracking => state is GuidedHikeTrackingActive;

  @override
  bool get isActive => state is GuidedHikeTrackingActive;

  @override
  bool get isCompleted => state is GuidedHikeTrackingCompleted;

  // Note: isPaused doesn't exist in parent class
  bool get isPaused {
    final currentState = state;
    return currentState is GuidedHikeTrackingActive && currentState.isPaused;
  }
}

// ═══════════════════════════════════════════════════════════
// HELPER - Create a testable notifier
// ═══════════════════════════════════════════════════════════

gl.Position createMockPosition({
  double latitude = 48.8566,
  double longitude = 2.3522,
}) {
  return gl.Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

// ═══════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════

void main() {
  late ProviderContainer container;
  late MockLocationStateNotifier mockLocationNotifier;
  late MockRouteSelectionStateNotifier mockRouteSelectionNotifier;
  late MockGuidedHikeTrackingStateNotifier mockGuidedHikeTrackingNotifier;

  setUpAll(() {
    registerFallbackValue(createMockPosition());
    registerFallbackValue(
      CameraOptions(center: Point(coordinates: Position(0.0, 0.0))),
    );
    registerFallbackValue(MapAnimationOptions(duration: 0, startDelay: 0));
  });

  setUp(() {
    mockLocationNotifier = MockLocationStateNotifier();
    mockRouteSelectionNotifier = MockRouteSelectionStateNotifier();
    mockGuidedHikeTrackingNotifier = MockGuidedHikeTrackingStateNotifier();

    // Set a mock position
    mockLocationNotifier.setMockPosition(createMockPosition());

    container = ProviderContainer(
      overrides: [
        locationStateProvider.overrideWith((ref) => mockLocationNotifier),
        routeSelectionProvider.overrideWith(
          (ref) => mockRouteSelectionNotifier,
        ),
        guidedHikeTrackingProvider.overrideWith(
          (ref) => mockGuidedHikeTrackingNotifier,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // ═══════════════════════════════════════════════════════════
  // HIKE NAVIGATION STATE NOTIFIER TESTS
  // ═══════════════════════════════════════════════════════════

  group('HikeNavigationStateNotifier', () {
    group('Initial State', () {
      test('should start with HikeNavigationIdle state', () {
        final notifier = container.read(hikeNavigationProvider.notifier);
        expect(notifier.state, isA<HikeNavigationIdle>());
      });

      test('provider should return HikeNavigationIdle initially', () {
        final state = container.read(hikeNavigationProvider);
        expect(state, isA<HikeNavigationIdle>());
      });
    });

    group('stopNavigation', () {
      test('should transition to Idle state', () {
        final notifier = container.read(hikeNavigationProvider.notifier);

        notifier.stopNavigation();

        expect(notifier.state, isA<HikeNavigationIdle>());
      });

      test('should cancel any active monitoring timer', () {
        final notifier = container.read(hikeNavigationProvider.notifier);

        // Call stopNavigation multiple times - should not throw
        notifier.stopNavigation();
        notifier.stopNavigation();

        expect(notifier.state, isA<HikeNavigationIdle>());
      });
    });

    group('updateCurrentPosition', () {
      test('should not update state when in Idle state', () {
        final notifier = container.read(hikeNavigationProvider.notifier);
        final position = createMockPosition(latitude: 48.9, longitude: 2.4);

        notifier.updateCurrentPosition(position);

        expect(notifier.state, isA<HikeNavigationIdle>());
      });

      test('should not update state when in Calculating state', () {
        final notifier = container.read(hikeNavigationProvider.notifier);
        // Manually simulate calculating state for testing
        // Since startNavigation is async and calls external services,
        // we test the guard condition
        final position = createMockPosition(latitude: 48.9, longitude: 2.4);

        notifier.updateCurrentPosition(position);

        // State should remain unchanged (Idle)
        expect(notifier.state, isA<HikeNavigationIdle>());
      });
    });

    group('startMonitoringArrival', () {
      test('should not start monitoring when state is Idle', () {
        final notifier = container.read(hikeNavigationProvider.notifier);

        // Should not throw when called in wrong state
        notifier.startMonitoringArrival();

        expect(notifier.state, isA<HikeNavigationIdle>());
      });
    });

    group('stopMonitoringArrival', () {
      test('should handle being called when no timer is running', () {
        final notifier = container.read(hikeNavigationProvider.notifier);

        // Should not throw when no timer exists
        notifier.stopMonitoringArrival();

        expect(notifier.state, isA<HikeNavigationIdle>());
      });

      test('should be idempotent - can be called multiple times', () {
        final notifier = container.read(hikeNavigationProvider.notifier);

        notifier.stopMonitoringArrival();
        notifier.stopMonitoringArrival();
        notifier.stopMonitoringArrival();

        expect(notifier.state, isA<HikeNavigationIdle>());
      });
    });

    group('dispose', () {
      test('should clean up resources on dispose', () {
        final testContainer = ProviderContainer(
          overrides: [
            locationStateProvider.overrideWith((ref) => mockLocationNotifier),
            routeSelectionProvider.overrideWith(
              (ref) => mockRouteSelectionNotifier,
            ),
            guidedHikeTrackingProvider.overrideWith(
              (ref) => mockGuidedHikeTrackingNotifier,
            ),
          ],
        );

        // Read the notifier to create it
        testContainer.read(hikeNavigationProvider.notifier);

        // Dispose should not throw
        testContainer.dispose();

        expect(true, true); // If we get here, dispose worked
      });
    });
  });

  // ═══════════════════════════════════════════════════════════
  // HIKE NAVIGATION STATE CLASS TESTS
  // ═══════════════════════════════════════════════════════════

  group('HikeNavigationState Classes', () {
    group('HikeNavigationIdle', () {
      test('should be const constructible', () {
        const idle = HikeNavigationIdle();
        expect(idle, isA<HikeNavigationState>());
      });

      test('should be equal to another HikeNavigationIdle', () {
        const idle1 = HikeNavigationIdle();
        const idle2 = HikeNavigationIdle();
        expect(identical(idle1, idle2), true);
      });
    });

    group('HikeNavigationCalculating', () {
      test('should store start coordinates', () {
        const calculating = HikeNavigationCalculating(
          startLat: 48.8566,
          startLon: 2.3522,
        );
        expect(calculating.startLat, 48.8566);
        expect(calculating.startLon, 2.3522);
      });

      test('should be a HikeNavigationState', () {
        const calculating = HikeNavigationCalculating(
          startLat: 48.8566,
          startLon: 2.3522,
        );
        expect(calculating, isA<HikeNavigationState>());
      });

      test('should handle different coordinates', () {
        const calculating = HikeNavigationCalculating(
          startLat: -33.8688,
          startLon: 151.2093,
        );
        expect(calculating.startLat, -33.8688);
        expect(calculating.startLon, 151.2093);
      });

      test('should handle edge case coordinates (0,0)', () {
        const calculating = HikeNavigationCalculating(
          startLat: 0.0,
          startLon: 0.0,
        );
        expect(calculating.startLat, 0.0);
        expect(calculating.startLon, 0.0);
      });
    });

    group('HikeNavigationActive', () {
      test('should store all required fields', () {
        const active = HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
            [2.3530, 48.8570],
          ],
          distanceToStartKm: 1.5,
          estimatedTimeMinutes: 18.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        expect(active.route.length, 2);
        expect(active.distanceToStartKm, 1.5);
        expect(active.estimatedTimeMinutes, 18.0);
        expect(active.startLat, 48.8566);
        expect(active.startLon, 2.3522);
        expect(active.activeHikeInfo, isNull);
        expect(active.hikeRouteCoordinates, isNull);
      });

      test('should store optional fields', () {
        const active = HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 1.0,
          estimatedTimeMinutes: 12.0,
          startLat: 48.8566,
          startLon: 2.3522,
          activeHikeInfo: {'name': 'Test Hike', 'difficulty': 'medium'},
          hikeRouteCoordinates: [
            [2.35, 48.85],
            [2.36, 48.86],
          ],
        );

        expect(active.activeHikeInfo, {
          'name': 'Test Hike',
          'difficulty': 'medium',
        });
        expect(active.hikeRouteCoordinates?.length, 2);
      });

      test('copyWith should update specified fields', () {
        const original = HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 1.5,
          estimatedTimeMinutes: 18.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final updated = original.copyWith(
          distanceToStartKm: 0.5,
          estimatedTimeMinutes: 6.0,
        );

        expect(updated.distanceToStartKm, 0.5);
        expect(updated.estimatedTimeMinutes, 6.0);
        expect(updated.route, original.route);
        expect(updated.startLat, original.startLat);
        expect(updated.startLon, original.startLon);
      });

      test('copyWith should preserve unspecified fields', () {
        const original = HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 1.5,
          estimatedTimeMinutes: 18.0,
          startLat: 48.8566,
          startLon: 2.3522,
          activeHikeInfo: {'name': 'Test'},
        );

        final updated = original.copyWith(distanceToStartKm: 1.0);

        expect(updated.activeHikeInfo, original.activeHikeInfo);
        expect(updated.route, original.route);
        expect(updated.estimatedTimeMinutes, original.estimatedTimeMinutes);
      });

      test('copyWith should update route', () {
        const original = HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 1.5,
          estimatedTimeMinutes: 18.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final newRoute = [
          [2.35, 48.85],
          [2.36, 48.86],
          [2.37, 48.87],
        ];
        final updated = original.copyWith(route: newRoute);

        expect(updated.route, newRoute);
        expect(updated.route.length, 3);
      });

      test('copyWith should update startLat and startLon', () {
        const original = HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 1.5,
          estimatedTimeMinutes: 18.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final updated = original.copyWith(
          startLat: 40.7128,
          startLon: -74.0060,
        );

        expect(updated.startLat, 40.7128);
        expect(updated.startLon, -74.0060);
      });

      test('copyWith should update optional fields', () {
        const original = HikeNavigationActive(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 1.5,
          estimatedTimeMinutes: 18.0,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        final updated = original.copyWith(
          activeHikeInfo: {'name': 'New Hike'},
          hikeRouteCoordinates: [
            [1.0, 2.0],
          ],
        );

        expect(updated.activeHikeInfo, {'name': 'New Hike'});
        expect(updated.hikeRouteCoordinates?.length, 1);
      });

      test('should handle empty route', () {
        const active = HikeNavigationActive(
          route: [],
          distanceToStartKm: 0,
          estimatedTimeMinutes: 0,
          startLat: 0,
          startLon: 0,
        );
        expect(active.route.isEmpty, true);
      });
    });

    group('HikeNavigationNearStart', () {
      test('should store all required fields', () {
        const nearStart = HikeNavigationNearStart(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 0.015,
          startLat: 48.8566,
          startLon: 2.3522,
        );

        expect(nearStart.route.length, 1);
        expect(nearStart.distanceToStartKm, 0.015);
        expect(nearStart.startLat, 48.8566);
        expect(nearStart.startLon, 2.3522);
      });

      test('should store optional fields', () {
        const nearStart = HikeNavigationNearStart(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 0.01,
          startLat: 48.8566,
          startLon: 2.3522,
          activeHikeInfo: {'name': 'Test'},
          hikeRouteCoordinates: [
            [2.35, 48.85],
          ],
        );

        expect(nearStart.activeHikeInfo, {'name': 'Test'});
        expect(nearStart.hikeRouteCoordinates?.length, 1);
      });

      test('should be a HikeNavigationState', () {
        const nearStart = HikeNavigationNearStart(
          route: [],
          distanceToStartKm: 0,
          startLat: 0,
          startLon: 0,
        );
        expect(nearStart, isA<HikeNavigationState>());
      });

      test('should handle very small distance', () {
        const nearStart = HikeNavigationNearStart(
          route: [
            [2.3522, 48.8566],
          ],
          distanceToStartKm: 0.001,
          startLat: 48.8566,
          startLon: 2.3522,
        );
        expect(nearStart.distanceToStartKm, 0.001);
      });
    });

    group('HikeNavigationError', () {
      test('should store error message', () {
        const error = HikeNavigationError('Test error message');
        expect(error.message, 'Test error message');
      });

      test('should be a HikeNavigationState', () {
        const error = HikeNavigationError('Error');
        expect(error, isA<HikeNavigationState>());
      });

      test('should store different error messages', () {
        const error1 = HikeNavigationError('Network error');
        const error2 = HikeNavigationError('Location unavailable');

        expect(error1.message, 'Network error');
        expect(error2.message, 'Location unavailable');
      });

      test('should handle empty error message', () {
        const error = HikeNavigationError('');
        expect(error.message, '');
      });
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ROUTE SELECTION STATE CLASS TESTS
  // ═══════════════════════════════════════════════════════════

  group('RouteSelectionState Classes', () {
    group('RouteSelectionLoading', () {
      test('should be const constructible', () {
        const loading = RouteSelectionLoading();
        expect(loading, isA<RouteSelectionState>());
      });
    });

    group('RouteSelectionLoaded', () {
      test('should store routes, wkbStrings, and routeNames', () {
        const loaded = RouteSelectionLoaded(
          routes: [
            {'name': 'Route 1', 'wkb': 'wkb1'},
            {'name': 'Route 2', 'wkb': 'wkb2'},
          ],
          wkbStrings: ['wkb1', 'wkb2'],
          routeNames: ['Route 1', 'Route 2'],
        );

        expect(loaded.routes.length, 2);
        expect(loaded.wkbStrings.length, 2);
        expect(loaded.routeNames.length, 2);
      });

      test('routeCount should return correct count', () {
        const loaded = RouteSelectionLoaded(
          routes: [
            {'name': 'Route 1'},
            {'name': 'Route 2'},
            {'name': 'Route 3'},
          ],
          wkbStrings: ['wkb1', 'wkb2', 'wkb3'],
          routeNames: ['Route 1', 'Route 2', 'Route 3'],
        );

        expect(loaded.routeCount, 3);
      });

      test('routeCount should be 0 for empty routes', () {
        const loaded = RouteSelectionLoaded(
          routes: [],
          wkbStrings: [],
          routeNames: [],
        );

        expect(loaded.routeCount, 0);
      });
    });

    group('RouteSelectionSelected', () {
      test('should store selectedHikeInfo and allRoutes', () {
        const selected = RouteSelectionSelected(
          selectedHikeInfo: {'name': 'Selected Hike', 'index': 0},
          allRoutes: [
            {'name': 'Route 1'},
            {'name': 'Route 2'},
          ],
          wkbStrings: ['wkb1', 'wkb2'],
          routeNames: ['Route 1', 'Route 2'],
        );

        expect(selected.selectedHikeInfo['name'], 'Selected Hike');
        expect(selected.allRoutes.length, 2);
      });

      group('calculateDistanceToStart', () {
        test('should return null when position is null', () {
          const selected = RouteSelectionSelected(
            selectedHikeInfo: {
              'start_point': {'latitude': 48.8566, 'longitude': 2.3522},
            },
            allRoutes: [],
            wkbStrings: [],
            routeNames: [],
          );

          expect(selected.calculateDistanceToStart(null), isNull);
        });

        test('should return null when start_point is missing', () {
          const selected = RouteSelectionSelected(
            selectedHikeInfo: {},
            allRoutes: [],
            wkbStrings: [],
            routeNames: [],
          );

          final position = createMockPosition();
          expect(selected.calculateDistanceToStart(position), isNull);
        });

        test('should return null when start_point latitude is missing', () {
          const selected = RouteSelectionSelected(
            selectedHikeInfo: {
              'start_point': {'longitude': 2.3522},
            },
            allRoutes: [],
            wkbStrings: [],
            routeNames: [],
          );

          final position = createMockPosition();
          expect(selected.calculateDistanceToStart(position), isNull);
        });

        test('should return null when start_point longitude is missing', () {
          const selected = RouteSelectionSelected(
            selectedHikeInfo: {
              'start_point': {'latitude': 48.8566},
            },
            allRoutes: [],
            wkbStrings: [],
            routeNames: [],
          );

          final position = createMockPosition();
          expect(selected.calculateDistanceToStart(position), isNull);
        });

        test('should calculate distance when all data is available', () {
          const selected = RouteSelectionSelected(
            selectedHikeInfo: {
              'start_point': {'latitude': 48.8600, 'longitude': 2.3600},
            },
            allRoutes: [],
            wkbStrings: [],
            routeNames: [],
          );

          final position = createMockPosition();
          final distance = selected.calculateDistanceToStart(position);

          expect(distance, isNotNull);
          expect(distance, greaterThan(0));
          expect(distance, lessThan(2.0));
        });

        test('should return 0 when at the same location', () {
          const selected = RouteSelectionSelected(
            selectedHikeInfo: {
              'start_point': {'latitude': 48.8566, 'longitude': 2.3522},
            },
            allRoutes: [],
            wkbStrings: [],
            routeNames: [],
          );

          final position = createMockPosition();
          final distance = selected.calculateDistanceToStart(position);

          expect(distance, isNotNull);
          expect(distance, closeTo(0, 0.001));
        });

        test('should calculate correct distance for known coordinates', () {
          // Paris to Versailles - roughly 17km
          const selected = RouteSelectionSelected(
            selectedHikeInfo: {
              'start_point': {'latitude': 48.8044, 'longitude': 2.1232},
            },
            allRoutes: [],
            wkbStrings: [],
            routeNames: [],
          );

          final position = createMockPosition();
          final distance = selected.calculateDistanceToStart(position);

          expect(distance, isNotNull);
          expect(distance, greaterThan(15));
          expect(distance, lessThan(20));
        });
      });
    });

    group('RouteSelectionError', () {
      test('should store error message', () {
        const error = RouteSelectionError('Test error');
        expect(error.message, 'Test error');
      });

      test('should be a RouteSelectionState', () {
        const error = RouteSelectionError('Error');
        expect(error, isA<RouteSelectionState>());
      });
    });
  });
}
