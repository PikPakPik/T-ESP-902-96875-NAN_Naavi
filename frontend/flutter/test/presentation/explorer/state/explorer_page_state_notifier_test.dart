import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/di/HomeMapProvider.dart';
import 'package:naavi/core/di/MapProviders.dart';
import 'package:naavi/core/models/location_state.dart';
import 'package:naavi/core/services/tracking/location_state_notifier.dart';
import 'package:naavi/core/services/tracking/tracking_location_service.dart';
import 'package:naavi/core/services/tracking/camera_mode_service.dart';
import 'package:naavi/core/services/statistics/statistics_service.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/presentation/common/compass/CompassState.dart';
import 'package:naavi/presentation/common/compass/CompassStateNotifier.dart';
import 'package:naavi/presentation/explorer/state/ExplorerPageState.dart';
import 'package:naavi/presentation/explorer/state/ExplorerPageStateNotifier.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingStateNotifier.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationState.dart';
import 'package:naavi/presentation/guided/state/HikeNavigationStateNotifier.dart';
import 'package:naavi/presentation/guided/state/RouteSelectionState.dart';
import 'package:naavi/presentation/guided/state/RouteSelectionStateNotifier.dart';
import 'package:naavi/core/services/hikes_api_service.dart';
import 'package:naavi/presentation/improvise/state/ImproviseHikeState.dart';
import 'package:naavi/presentation/improvise/state/ImproviseHikeStateNotifier.dart';
import 'package:naavi/presentation/map/state/HomeMapState.dart';
import 'package:naavi/presentation/map/state/HomeMapStateNotifier.dart';
import 'package:naavi/presentation/map/state/MapControllerState.dart';
import 'package:naavi/presentation/map/state/MapControllerStateNotifier.dart';
import 'package:naavi/presentation/map/state/MapServicesState.dart';
import 'package:naavi/core/services/hiking_routes_service.dart';

// ═══════════════════════════════════════════════════════════
// MOCKS
// ═══════════════════════════════════════════════════════════

class MockMapboxMap extends Mock implements MapboxMap {}

class MockPosition extends Mock implements gl.Position {}

class MockTrackingLocationService extends Mock
    implements TrackingLocationService {}

class MockCameraModeManager extends Mock implements CameraModeManager {}

class MockHikingRoutesService extends Mock implements HikingRoutesService {}

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

  bool loadRoutesCalled = false;

  @override
  HikingRoutesService get routesService => MockHikingRoutesService();

  @override
  HikesApiService? get hikesApiService => null;

  @override
  Future<void> loadRoutes({
    List<String>? providedWkbStrings,
    List<String>? providedRouteNames,
  }) async {
    loadRoutesCalled = true;
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
  void selectRoute(Map<String, dynamic> hikeInfo) {}

  @override
  void deselectRoute() {}

  @override
  List<List<double>>? getRouteCoordinates(int routeIndex) => null;

  @override
  bool get hasRoutes =>
      state is RouteSelectionLoaded || state is RouteSelectionSelected;

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

class MockCompassStateNotifier extends StateNotifier<CompassState>
    implements CompassStateNotifier {
  MockCompassStateNotifier() : super(const CompassIdle());

  bool startListeningCalled = false;
  bool stopListeningCalled = false;

  @override
  void startListening() {
    startListeningCalled = true;
    state = const CompassActive(currentHeading: 0.0, previousHeading: 0.0);
  }

  @override
  void stopListening() {
    stopListeningCalled = true;
    state = const CompassIdle();
  }

  @override
  double get headingThreshold => 5.0;

  @override
  bool get isListening => state is CompassActive;

  @override
  void Function(double heading)? get onHeadingChanged => null;
}

class MockMapControllerStateNotifier extends StateNotifier<MapControllerState>
    implements MapControllerStateNotifier {
  MockMapControllerStateNotifier() : super(const MapControllerLoading());

  bool onMapCreatedCalled = false;
  MapboxMap? lastMapboxMap;

  @override
  void onMapCreated(MapboxMap mapboxMap) {
    onMapCreatedCalled = true;
    lastMapboxMap = mapboxMap;
    state = MapControllerReady(controller: mapboxMap);
  }

  @override
  void onUserInteractionStart() {}

  @override
  void onUserInteractionEnd() {}

  @override
  MapboxMap? get controller {
    return switch (state) {
      MapControllerReady(controller: final ctrl) => ctrl,
      MapControllerInteracting(controller: final ctrl) => ctrl,
      _ => null,
    };
  }

  @override
  bool get isReady =>
      state is MapControllerReady || state is MapControllerInteracting;

  @override
  bool get isUserInteracting => state is MapControllerInteracting;
}

class MockMapServicesNotifier extends StateNotifier<MapServicesState>
    implements MapServicesNotifier {
  MockMapServicesNotifier() : super(MapServicesState());

  bool setMapControllerCalled = false;
  bool setCurrentPositionCalled = false;
  gl.Position? lastPosition;

  @override
  void setMapController(MapboxMap controller) {
    setMapControllerCalled = true;
    state = state.copyWith(mapboxMapController: controller, isMapReady: true);
  }

  @override
  void setCurrentPosition(gl.Position position) {
    setCurrentPositionCalled = true;
    lastPosition = position;
    state = state.copyWith(currentPosition: position);
  }

  @override
  void setFirstPersonMode(bool isFirstPersonMode) {
    state = state.copyWith(isFirstPersonMode: isFirstPersonMode);
  }
}

class MockHikeNavigationStateNotifier extends StateNotifier<HikeNavigationState>
    implements HikeNavigationStateNotifier {
  MockHikeNavigationStateNotifier() : super(const HikeNavigationIdle());

  @override
  Future<void> startNavigation({
    required double startLat,
    required double startLon,
    required gl.Position currentPosition,
    Map<String, dynamic>? hikeInfo,
    List<List<double>>? hikeRouteCoordinates,
  }) async {}

  @override
  void stopNavigation() {}

  @override
  void updateCurrentPosition(gl.Position position) {}

  @override
  Future<void> displayNavigationRoute(MapboxMap mapboxMap) async {}

  @override
  Future<void> cleanupNavigationRoute(MapboxMap mapboxMap) async {}

  @override
  void startMonitoringArrival() {}

  @override
  void stopMonitoringArrival() {}

  @override
  Future<void> startGuidedHikeFromNearStart(MapboxMap mapboxMap) async {}

  @override
  Future<void> orientCameraToRoute({
    required MapboxMap mapboxMap,
    required gl.Position currentPosition,
  }) async {}
}

class MockGuidedHikeTrackingStateNotifier
    extends StateNotifier<GuidedHikeTrackingState>
    implements GuidedHikeTrackingStateNotifier {
  MockGuidedHikeTrackingStateNotifier() : super(const GuidedHikeTrackingIdle());

  @override
  void startTracking({
    required List<List<double>> routeCoordinates,
    Map<String, dynamic>? hikeInfo,
  }) {}

  @override
  void stopTracking({bool completed = false}) {}

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  void updatePosition(gl.Position position) {}

  @override
  void markCameraOriented() {}

  @override
  void reset() {}

  @override
  bool get isActive => state is GuidedHikeTrackingActive;

  @override
  bool get isCompleted => state is GuidedHikeTrackingCompleted;
}

class MockImproviseHikeStateNotifier extends StateNotifier<ImproviseHikeState>
    implements ImproviseHikeStateNotifier {
  MockImproviseHikeStateNotifier() : super(const ImproviseHikeIdle());

  @override
  Future<void> startHike({
    required MapboxMap mapboxMap,
    required bool isMapReady,
  }) async {}

  @override
  Future<void> finishHike({
    required List<List<gl.Position>> segments,
    required double distanceKm,
    MapboxMap? mapboxMap,
  }) async {}

  @override
  Future<void> exitFirstPersonMode() async {}

  @override
  Future<void> reset() async {}

  @override
  bool get isActive => state is ImproviseHikeActive;

  @override
  bool get isStarting => state is ImproviseHikeStarting;

  @override
  bool get isFinished => state is ImproviseHikeFinished;

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  LocationStateNotifier get locationStateNotifier => throw UnimplementedError();

  @override
  TrackingLocationService get trackingLocation => throw UnimplementedError();

  @override
  StatisticsService? get statisticsService => null;

  @override
  CameraModeManager? get cameraModeManager => null;

  @override
  PoiService get poiService => throw UnimplementedError();
}

class MockHomeMapStateNotifier extends StateNotifier<HomeMapState>
    implements HomeMapStateNotifier {
  MockHomeMapStateNotifier() : super(HomeMapState.explore);

  @override
  void updateState(HomeMapState newState) {
    state = newState;
  }
}

// ═══════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════

void main() {
  late ProviderContainer container;
  late MockLocationStateNotifier mockLocationNotifier;
  late MockRouteSelectionStateNotifier mockRouteSelectionNotifier;
  late MockCompassStateNotifier mockCompassNotifier;
  late MockMapControllerStateNotifier mockMapControllerNotifier;
  late MockMapServicesNotifier mockMapServicesNotifier;
  late MockTrackingLocationService mockTrackingLocationService;
  late MockHikeNavigationStateNotifier mockHikeNavigationNotifier;
  late MockGuidedHikeTrackingStateNotifier mockGuidedHikeTrackingNotifier;
  late MockImproviseHikeStateNotifier mockImproviseHikeNotifier;
  late MockHomeMapStateNotifier mockHomeMapStateNotifier;
  late MockMapboxMap mockMapboxMap;
  late MockPosition mockPosition;

  setUpAll(() {
    registerFallbackValue(MockMapboxMap());
    registerFallbackValue(
      gl.Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      ),
    );
    registerFallbackValue(
      CameraOptions(center: Point(coordinates: Position(0.0, 0.0))),
    );
  });

  setUp(() {
    mockLocationNotifier = MockLocationStateNotifier();
    mockRouteSelectionNotifier = MockRouteSelectionStateNotifier();
    mockCompassNotifier = MockCompassStateNotifier();
    mockMapControllerNotifier = MockMapControllerStateNotifier();
    mockMapServicesNotifier = MockMapServicesNotifier();
    mockTrackingLocationService = MockTrackingLocationService();
    mockHikeNavigationNotifier = MockHikeNavigationStateNotifier();
    mockGuidedHikeTrackingNotifier = MockGuidedHikeTrackingStateNotifier();
    mockImproviseHikeNotifier = MockImproviseHikeStateNotifier();
    mockHomeMapStateNotifier = MockHomeMapStateNotifier();
    mockMapboxMap = MockMapboxMap();
    mockPosition = MockPosition();

    when(() => mockPosition.latitude).thenReturn(48.8566);
    when(() => mockPosition.longitude).thenReturn(2.3522);
    when(
      () => mockTrackingLocationService.setMapController(any()),
    ).thenReturn(null);
    when(() => mockTrackingLocationService.stopTracking()).thenReturn(null);
    when(() => mockMapboxMap.setCamera(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        locationStateProvider.overrideWith((ref) => mockLocationNotifier),
        routeSelectionProvider.overrideWith(
          (ref) => mockRouteSelectionNotifier,
        ),
        compassProvider.overrideWith((ref) => mockCompassNotifier),
        mapControllerProvider.overrideWith((ref) => mockMapControllerNotifier),
        mapServicesProvider.overrideWith((ref) => mockMapServicesNotifier),
        trackingLocationProvider.overrideWithValue(mockTrackingLocationService),
        hikeNavigationProvider.overrideWith(
          (ref) => mockHikeNavigationNotifier,
        ),
        guidedHikeTrackingProvider.overrideWith(
          (ref) => mockGuidedHikeTrackingNotifier,
        ),
        improviseHikeProvider.overrideWith((ref) => mockImproviseHikeNotifier),
        homeMapStateProvider.overrideWith((ref) => mockHomeMapStateNotifier),
        cameraModeManagerProvider.overrideWith((ref) => null),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ExplorerPageStateNotifier createNotifier() {
    // Create a Ref from the container to pass to the StateNotifier
    final ref = container.read(explorerPageProvider.notifier);
    return ref;
  }

  group('ExplorerPageStateNotifier', () {
    group('Initial State', () {
      test('should start with ExplorerPageInitial state', () {
        final notifier = createNotifier();
        expect(notifier.state, isA<ExplorerPageInitial>());
        expect(notifier.state, const ExplorerPageInitial());
      });

      test('isReady should be false initially', () {
        final notifier = createNotifier();
        expect(notifier.isReady, isFalse);
      });

      test('mapController should be null initially', () {
        final notifier = createNotifier();
        expect(notifier.mapController, isNull);
      });

      test('currentPosition should be null initially', () {
        final notifier = createNotifier();
        expect(notifier.currentPosition, isNull);
      });
    });

    group('initialize()', () {
      test('should transition through initializing states', () async {
        final notifier = createNotifier();

        await notifier.initialize();

        // Verify startTracking was called
        expect(mockLocationNotifier.state.isTracking, isTrue);

        // Verify loadRoutes was called
        expect(mockRouteSelectionNotifier.loadRoutesCalled, isTrue);

        // Compass is NOT started during initialize anymore
        // It's only started when a hike begins
      });

      test('should start GPS tracking', () async {
        final notifier = createNotifier();

        await notifier.initialize();

        expect(mockLocationNotifier.state.isTracking, isTrue);
        expect(mockLocationNotifier.state.hasPermission, isTrue);
      });

      test('should load routes via provider', () async {
        final notifier = createNotifier();

        await notifier.initialize();

        expect(mockRouteSelectionNotifier.loadRoutesCalled, isTrue);
        expect(mockRouteSelectionNotifier.state, isA<RouteSelectionLoaded>());
      });

      test('should not start compass during initialization', () async {
        // Compass is now only started when a hike begins
        // This is a behavior change - verify compass is NOT started
        final notifier = createNotifier();

        await notifier.initialize();

        // Compass should NOT be started during init
        expect(mockCompassNotifier.startListeningCalled, isFalse);
      });

      test('should accept custom wkbStrings and routeNames', () async {
        final notifier = createNotifier();

        await notifier.initialize(
          wkbStrings: ['wkb1', 'wkb2'],
          routeNames: ['Route 1', 'Route 2'],
        );

        expect(mockRouteSelectionNotifier.loadRoutesCalled, isTrue);
      });

      test('should accept initial position', () async {
        final notifier = createNotifier();

        await notifier.initialize(initialPosition: mockPosition);

        expect(mockLocationNotifier.state.isTracking, isTrue);
      });

      test('should handle errors during initialization', () async {
        // Create a failing route selection notifier
        final failingRouteNotifier = _FailingRouteSelectionStateNotifier();

        final errorContainer = ProviderContainer(
          overrides: [
            locationStateProvider.overrideWith((ref) => mockLocationNotifier),
            routeSelectionProvider.overrideWith((ref) => failingRouteNotifier),
            compassProvider.overrideWith((ref) => mockCompassNotifier),
          ],
        );

        final notifier = errorContainer.read(explorerPageProvider.notifier);

        await notifier.initialize();

        expect(notifier.state, isA<ExplorerPageError>());
        final errorState = notifier.state as ExplorerPageError;
        expect(errorState.message, contains('Erreur'));

        errorContainer.dispose();
      });
    });

    group('onMapReady()', () {
      test('should initialize map controller in providers', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        await notifier.onMapReady(mockMapboxMap);

        expect(mockMapControllerNotifier.onMapCreatedCalled, isTrue);
        expect(mockMapControllerNotifier.lastMapboxMap, mockMapboxMap);
      });

      test('should set map controller in map services', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        await notifier.onMapReady(mockMapboxMap);

        expect(mockMapServicesNotifier.setMapControllerCalled, isTrue);
      });

      test('should configure tracking location service', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        await notifier.onMapReady(mockMapboxMap);

        verify(
          () => mockTrackingLocationService.setMapController(mockMapboxMap),
        ).called(1);
      });

      test('should center camera on current position when available', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        await notifier.onMapReady(mockMapboxMap);

        verify(() => mockMapboxMap.setCamera(any())).called(1);
        expect(mockMapServicesNotifier.setCurrentPositionCalled, isTrue);
      });

      test('should transition to ExplorerPageReady state', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        await notifier.onMapReady(mockMapboxMap);

        expect(notifier.state, isA<ExplorerPageReady>());
        expect(notifier.isReady, isTrue);
        expect(notifier.mapController, mockMapboxMap);
      });

      test(
        'should set hasCenteredOnInitialPosition when position exists',
        () async {
          final notifier = createNotifier();
          mockLocationNotifier.setMockPosition(mockPosition);

          await notifier.onMapReady(mockMapboxMap);

          final readyState = notifier.state as ExplorerPageReady;
          expect(readyState.hasCenteredOnInitialPosition, isTrue);
        },
      );

      test('should handle case when no cached position available', () async {
        final notifier = createNotifier();
        // Don't set mock position - simulates no cached position

        await notifier.onMapReady(mockMapboxMap);

        expect(notifier.state, isA<ExplorerPageReady>());
        final readyState = notifier.state as ExplorerPageReady;
        expect(readyState.currentPosition, isNull);
        expect(readyState.hasCenteredOnInitialPosition, isFalse);
      });

      test('should create CameraModeManager', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        await notifier.onMapReady(mockMapboxMap);

        // CameraModeManager is created internally - verify state is ready
        expect(notifier.isReady, isTrue);
      });
    });

    group('refreshCurrentPosition()', () {
      test(
        'should get current position from location state notifier',
        () async {
          final notifier = createNotifier();
          mockLocationNotifier.setMockPosition(mockPosition);

          // First set up ready state
          notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

          final position = await notifier.refreshCurrentPosition();

          expect(position, mockPosition);
        },
      );

      test('should update map services with new position', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

        await notifier.refreshCurrentPosition();

        expect(mockMapServicesNotifier.setCurrentPositionCalled, isTrue);
        expect(mockMapServicesNotifier.lastPosition, mockPosition);
      });

      test('should update state with new position', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

        await notifier.refreshCurrentPosition();

        final readyState = notifier.state as ExplorerPageReady;
        expect(readyState.currentPosition, mockPosition);
      });

      test('should return null when no position available', () async {
        final notifier = createNotifier();
        // Don't set mock position

        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

        final position = await notifier.refreshCurrentPosition();

        expect(position, isNull);
      });

      test('should not update state when not in ready state', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        notifier.state = const ExplorerPageInitial();

        await notifier.refreshCurrentPosition();

        expect(notifier.state, isA<ExplorerPageInitial>());
      });
    });

    group('canAutoCenterOnPosition()', () {
      test('should return false when state is not ExplorerPageReady', () {
        final notifier = createNotifier();
        notifier.state = const ExplorerPageInitial();

        expect(notifier.canAutoCenterOnPosition(), isFalse);
      });

      test('should return false when already centered on initial position', () {
        final notifier = createNotifier();
        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: true,
        );

        expect(notifier.canAutoCenterOnPosition(), isFalse);
      });

      test('should return true when in explore mode and not centered', () {
        final notifier = createNotifier();
        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: false,
        );

        // All providers are in idle state by default
        expect(notifier.canAutoCenterOnPosition(), isTrue);
      });

      test('should return false when navigation is active', () {
        final notifier = createNotifier();
        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: false,
        );

        // Set navigation to active
        mockHikeNavigationNotifier.state = const HikeNavigationActive(
          route: [],
          distanceToStartKm: 0,
          estimatedTimeMinutes: 0,
          startLat: 0,
          startLon: 0,
        );

        expect(notifier.canAutoCenterOnPosition(), isFalse);
      });

      test('should return false when guided hike tracking is active', () {
        final notifier = createNotifier();
        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: false,
        );

        // Set guided hike tracking to active
        mockGuidedHikeTrackingNotifier.state = const GuidedHikeTrackingActive(
          routeCoordinates: [],
          currentWaypointIndex: 0,
          currentDirection: '',
          currentDirectionType: DirectionType.straight,
          distanceToNextWaypointMeters: 0,
          elapsedSeconds: 0,
          distanceKm: 0,
        );

        expect(notifier.canAutoCenterOnPosition(), isFalse);
      });

      test('should return false when improvise hike is active', () {
        final notifier = createNotifier();
        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: false,
        );

        // Set improvise hike to active
        mockImproviseHikeNotifier.state = ImproviseHikeActive(
          startPoint: mockPosition,
          startTime: DateTime.now(),
        );

        expect(notifier.canAutoCenterOnPosition(), isFalse);
      });

      test('should return false when home map state is not explore', () {
        final notifier = createNotifier();
        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: false,
        );

        // Set home map state to something other than explore
        mockHomeMapStateNotifier.state = HomeMapState.improvise;

        expect(notifier.canAutoCenterOnPosition(), isFalse);
      });
    });

    group('updatePosition()', () {
      test('should update position when state is ExplorerPageReady', () {
        final notifier = createNotifier();
        final newPosition = MockPosition();

        when(() => newPosition.latitude).thenReturn(51.5074);
        when(() => newPosition.longitude).thenReturn(-0.1278);

        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: mockPosition,
        );

        notifier.updatePosition(newPosition);

        expect(notifier.state, isA<ExplorerPageReady>());
        final readyState = notifier.state as ExplorerPageReady;
        expect(readyState.currentPosition, newPosition);
      });

      test(
        'should not update position when state is not ExplorerPageReady',
        () {
          final notifier = createNotifier();
          final newPosition = MockPosition();

          when(() => newPosition.latitude).thenReturn(51.5074);
          when(() => newPosition.longitude).thenReturn(-0.1278);

          notifier.state = const ExplorerPageInitial();

          notifier.updatePosition(newPosition);

          expect(notifier.state, isA<ExplorerPageInitial>());
        },
      );

      test('should preserve hasCenteredOnInitialPosition flag', () {
        final notifier = createNotifier();
        final newPosition = MockPosition();

        when(() => newPosition.latitude).thenReturn(51.5074);
        when(() => newPosition.longitude).thenReturn(-0.1278);

        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: mockPosition,
          hasCenteredOnInitialPosition: true,
        );

        notifier.updatePosition(newPosition);

        final readyState = notifier.state as ExplorerPageReady;
        expect(readyState.hasCenteredOnInitialPosition, isTrue);
      });

      test('should handle multiple position updates', () {
        final notifier = createNotifier();
        final positions = List.generate(10, (i) {
          final pos = MockPosition();
          when(() => pos.latitude).thenReturn(48.0 + i);
          when(() => pos.longitude).thenReturn(2.0 + i);
          return pos;
        });

        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

        for (final position in positions) {
          notifier.updatePosition(position);
        }

        expect(notifier.state, isA<ExplorerPageReady>());
        final readyState = notifier.state as ExplorerPageReady;
        expect(readyState.currentPosition, positions.last);
      });
    });

    group('markInitialPositionCentered()', () {
      test(
        'should mark position as centered when state is ExplorerPageReady',
        () {
          final notifier = createNotifier();

          notifier.state = ExplorerPageReady(
            mapController: mockMapboxMap,
            currentPosition: mockPosition,
            hasCenteredOnInitialPosition: false,
          );

          notifier.markInitialPositionCentered();

          expect(notifier.state, isA<ExplorerPageReady>());
          final readyState = notifier.state as ExplorerPageReady;
          expect(readyState.hasCenteredOnInitialPosition, isTrue);
        },
      );

      test('should not modify state when not ExplorerPageReady', () {
        final notifier = createNotifier();
        notifier.state = const ExplorerPageInitial();

        notifier.markInitialPositionCentered();

        expect(notifier.state, isA<ExplorerPageInitial>());
      });

      test('should handle already centered state', () {
        final notifier = createNotifier();

        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          hasCenteredOnInitialPosition: true,
        );

        notifier.markInitialPositionCentered();

        final readyState = notifier.state as ExplorerPageReady;
        expect(readyState.hasCenteredOnInitialPosition, isTrue);
      });
    });

    group('Lifecycle Methods', () {
      test('onAppResumed should call refreshCurrentPosition', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);
        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

        notifier.onAppResumed();

        // Give async operation time to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify position was refreshed (mapServices should have been called)
        expect(mockMapServicesNotifier.setCurrentPositionCalled, isTrue);
      });

      test('onAppPaused should not throw errors', () {
        final notifier = createNotifier();
        expect(() => notifier.onAppPaused(), returnsNormally);
      });

      test('onAppPaused should be a no-op', () {
        final notifier = createNotifier();
        final initialState = notifier.state;
        notifier.onAppPaused();
        expect(notifier.state, initialState);
      });

      test('onAppDetached should stop location tracking', () {
        final notifier = createNotifier();

        notifier.onAppDetached();

        expect(mockLocationNotifier.state.isTracking, isFalse);
        verify(() => mockTrackingLocationService.stopTracking()).called(1);
      });

      test('onAppDetached should stop tracking location service', () {
        final notifier = createNotifier();

        notifier.onAppDetached();

        verify(() => mockTrackingLocationService.stopTracking()).called(1);
      });
    });

    group('cleanup()', () {
      test('should stop location tracking', () {
        final notifier = createNotifier();

        notifier.cleanup();

        expect(mockLocationNotifier.state.isTracking, isFalse);
      });

      test('should stop compass listening', () {
        final notifier = createNotifier();

        notifier.cleanup();

        expect(mockCompassNotifier.stopListeningCalled, isTrue);
        expect(mockCompassNotifier.state, isA<CompassIdle>());
      });

      test('should be callable multiple times without error', () {
        final notifier = createNotifier();

        expect(() {
          notifier.cleanup();
          notifier.cleanup();
          notifier.cleanup();
        }, returnsNormally);
      });
    });

    group('Getters', () {
      group('mapController', () {
        test(
          'should return map controller when state is ExplorerPageReady',
          () {
            final notifier = createNotifier();

            notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

            expect(notifier.mapController, mockMapboxMap);
          },
        );

        test('should return null when state is ExplorerPageInitial', () {
          final notifier = createNotifier();
          notifier.state = const ExplorerPageInitial();

          expect(notifier.mapController, isNull);
        });

        test('should return null when state is ExplorerPageError', () {
          final notifier = createNotifier();
          notifier.state = const ExplorerPageError(message: 'Error');

          expect(notifier.mapController, isNull);
        });

        test('should return null when state is ExplorerPageInitializing', () {
          final notifier = createNotifier();
          notifier.state = const ExplorerPageInitializing(step: 'Loading');

          expect(notifier.mapController, isNull);
        });
      });

      group('currentPosition', () {
        test(
          'should return position when state is ExplorerPageReady with position',
          () {
            final notifier = createNotifier();

            notifier.state = ExplorerPageReady(
              mapController: mockMapboxMap,
              currentPosition: mockPosition,
            );

            expect(notifier.currentPosition, mockPosition);
          },
        );

        test(
          'should return null when state is ExplorerPageReady without position',
          () {
            final notifier = createNotifier();

            notifier.state = ExplorerPageReady(
              mapController: mockMapboxMap,
              currentPosition: null,
            );

            expect(notifier.currentPosition, isNull);
          },
        );

        test('should return null when state is not ExplorerPageReady', () {
          final notifier = createNotifier();
          notifier.state = const ExplorerPageInitial();

          expect(notifier.currentPosition, isNull);
        });
      });

      group('isReady', () {
        test('should return true when state is ExplorerPageReady', () {
          final notifier = createNotifier();

          notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

          expect(notifier.isReady, isTrue);
        });

        test('should return false when state is ExplorerPageInitial', () {
          final notifier = createNotifier();
          notifier.state = const ExplorerPageInitial();

          expect(notifier.isReady, isFalse);
        });

        test('should return false when state is ExplorerPageError', () {
          final notifier = createNotifier();
          notifier.state = const ExplorerPageError(message: 'Error');

          expect(notifier.isReady, isFalse);
        });

        test('should return false when state is ExplorerPageInitializing', () {
          final notifier = createNotifier();
          notifier.state = const ExplorerPageInitializing(step: 'Loading');

          expect(notifier.isReady, isFalse);
        });
      });
    });

    group('State Properties', () {
      test('ExplorerPageReady should have correct default values', () {
        final state = ExplorerPageReady(mapController: mockMapboxMap);

        expect(state.mapController, mockMapboxMap);
        expect(state.currentPosition, isNull);
        expect(state.hasCenteredOnInitialPosition, isFalse);
      });

      test('ExplorerPageReady copyWith should create new instance', () {
        final position1 = MockPosition();
        final position2 = MockPosition();

        when(() => position1.latitude).thenReturn(48.8566);
        when(() => position1.longitude).thenReturn(2.3522);
        when(() => position2.latitude).thenReturn(51.5074);
        when(() => position2.longitude).thenReturn(-0.1278);

        final original = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: position1,
          hasCenteredOnInitialPosition: false,
        );

        final copied = original.copyWith(
          currentPosition: position2,
          hasCenteredOnInitialPosition: true,
        );

        expect(copied.mapController, original.mapController);
        expect(copied.currentPosition, position2);
        expect(copied.hasCenteredOnInitialPosition, isTrue);
        expect(original.currentPosition, position1);
        expect(original.hasCenteredOnInitialPosition, isFalse);
      });

      test('ExplorerPageError should store message and details', () {
        const state = ExplorerPageError(
          message: 'Connection failed',
          details: ['Network error', 'Timeout'],
        );

        expect(state.message, 'Connection failed');
        expect(state.details, ['Network error', 'Timeout']);
      });

      test('ExplorerPageInitializing should store step', () {
        const state = ExplorerPageInitializing(step: 'Loading GPS...');

        expect(state.step, 'Loading GPS...');
      });
    });

    group('Integration Scenarios', () {
      test('typical flow: initial -> initializing -> ready', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        // Initial state
        expect(notifier.state, isA<ExplorerPageInitial>());
        expect(notifier.isReady, isFalse);

        // Initialize
        await notifier.initialize();

        // Ready state after onMapReady
        await notifier.onMapReady(mockMapboxMap);

        expect(notifier.state, isA<ExplorerPageReady>());
        expect(notifier.isReady, isTrue);
        expect(notifier.mapController, mockMapboxMap);
        expect(notifier.currentPosition, mockPosition);
      });

      test('position tracking: ready -> update position -> mark centered', () {
        final notifier = createNotifier();
        final position1 = MockPosition();
        final position2 = MockPosition();

        when(() => position1.latitude).thenReturn(48.8566);
        when(() => position1.longitude).thenReturn(2.3522);
        when(() => position2.latitude).thenReturn(48.8567);
        when(() => position2.longitude).thenReturn(2.3523);

        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: position1,
          hasCenteredOnInitialPosition: false,
        );

        notifier.updatePosition(position2);
        expect(notifier.currentPosition, position2);

        notifier.markInitialPositionCentered();
        final finalState = notifier.state as ExplorerPageReady;
        expect(finalState.hasCenteredOnInitialPosition, isTrue);
      });

      test(
        'full lifecycle: init -> ready -> pause -> resume -> cleanup',
        () async {
          final notifier = createNotifier();
          mockLocationNotifier.setMockPosition(mockPosition);

          // Initialize
          await notifier.initialize();
          expect(mockLocationNotifier.state.isTracking, isTrue);

          // Map ready
          await notifier.onMapReady(mockMapboxMap);
          expect(notifier.isReady, isTrue);

          // App paused
          notifier.onAppPaused();
          expect(notifier.isReady, isTrue); // Should remain ready

          // App resumed
          notifier.onAppResumed();
          await Future.delayed(const Duration(milliseconds: 100));

          // Cleanup
          notifier.cleanup();
          expect(mockLocationNotifier.state.isTracking, isFalse);
          expect(mockCompassNotifier.stopListeningCalled, isTrue);
        },
      );
    });

    group('Edge Cases', () {
      test('should handle null position in ExplorerPageReady', () {
        final notifier = createNotifier();

        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: null,
        );

        expect(notifier.currentPosition, isNull);
        expect(notifier.isReady, isTrue);
        expect(notifier.mapController, mockMapboxMap);
      });

      test('should handle state transitions from error to ready', () async {
        final notifier = createNotifier();
        mockLocationNotifier.setMockPosition(mockPosition);

        notifier.state = const ExplorerPageError(message: 'Error');
        expect(notifier.isReady, isFalse);

        await notifier.onMapReady(mockMapboxMap);
        expect(notifier.isReady, isTrue);
      });

      test('should handle rapid state changes', () {
        final notifier = createNotifier();

        notifier.state = const ExplorerPageInitializing(step: 'Step 1');
        notifier.state = const ExplorerPageInitializing(step: 'Step 2');
        notifier.state = const ExplorerPageInitializing(step: 'Step 3');
        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);

        expect(notifier.state, isA<ExplorerPageReady>());
        expect(notifier.isReady, isTrue);
      });

      test('should preserve state consistency after multiple operations', () {
        final notifier = createNotifier();

        notifier.state = ExplorerPageReady(
          mapController: mockMapboxMap,
          currentPosition: mockPosition,
          hasCenteredOnInitialPosition: false,
        );

        notifier.markInitialPositionCentered();

        final newPosition = MockPosition();
        when(() => newPosition.latitude).thenReturn(51.5074);
        when(() => newPosition.longitude).thenReturn(-0.1278);

        notifier.updatePosition(newPosition);

        final finalState = notifier.state as ExplorerPageReady;
        expect(finalState.hasCenteredOnInitialPosition, isTrue);
        expect(finalState.currentPosition, newPosition);
        expect(finalState.mapController, mockMapboxMap);
      });

      test('lifecycle methods should not throw on any state', () {
        final notifier = createNotifier();

        // Test on initial state
        expect(() => notifier.onAppPaused(), returnsNormally);

        // Test on ready state
        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);
        expect(() => notifier.onAppPaused(), returnsNormally);

        // Test on error state
        notifier.state = const ExplorerPageError(message: 'Error');
        expect(() => notifier.onAppPaused(), returnsNormally);

        // Test on initializing state
        notifier.state = const ExplorerPageInitializing(step: 'Loading');
        expect(() => notifier.onAppPaused(), returnsNormally);
      });
    });

    group('Boundary Conditions', () {
      test('should handle position at extreme coordinates', () {
        final notifier = createNotifier();
        final extremePosition = MockPosition();

        when(() => extremePosition.latitude).thenReturn(90.0); // North Pole
        when(() => extremePosition.longitude).thenReturn(180.0);

        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);
        notifier.updatePosition(extremePosition);

        expect(notifier.currentPosition, extremePosition);
      });

      test('should handle position at zero coordinates', () {
        final notifier = createNotifier();
        final zeroPosition = MockPosition();

        when(() => zeroPosition.latitude).thenReturn(0.0);
        when(() => zeroPosition.longitude).thenReturn(0.0);

        notifier.state = ExplorerPageReady(mapController: mockMapboxMap);
        notifier.updatePosition(zeroPosition);

        expect(notifier.currentPosition, zeroPosition);
      });

      test('should handle very long error messages', () {
        final notifier = createNotifier();
        final longMessage = 'Error ' * 100;
        notifier.state = ExplorerPageError(message: longMessage, details: []);

        final errorState = notifier.state as ExplorerPageError;
        expect(errorState.message.length, greaterThan(500));
      });

      test('should handle very long step descriptions', () {
        final notifier = createNotifier();
        final longStep = 'Step ' * 150;
        notifier.state = ExplorerPageInitializing(step: longStep);

        final initState = notifier.state as ExplorerPageInitializing;
        expect(initState.step.length, greaterThan(500));
      });
    });
  });
}

// Helper class for testing error handling
class _FailingRouteSelectionStateNotifier
    extends StateNotifier<RouteSelectionState>
    implements RouteSelectionStateNotifier {
  _FailingRouteSelectionStateNotifier() : super(const RouteSelectionLoading());

  @override
  HikingRoutesService get routesService => MockHikingRoutesService();

  @override
  HikesApiService? get hikesApiService => null;

  @override
  Future<void> loadRoutes({
    List<String>? providedWkbStrings,
    List<String>? providedRouteNames,
  }) async {
    throw Exception('Route loading failed');
  }

  @override
  Future<void> loadHikesFromApi({
    required double latitude,
    required double longitude,
    int radius = 20,
  }) async {
    throw Exception('Hikes loading failed');
  }

  @override
  void selectRoute(Map<String, dynamic> hikeInfo) {}

  @override
  void deselectRoute() {}

  @override
  List<List<double>>? getRouteCoordinates(int routeIndex) => null;

  @override
  bool get hasRoutes => false;

  @override
  bool get hasSelection => false;

  @override
  Map<String, dynamic>? get selectedHike => null;
}
