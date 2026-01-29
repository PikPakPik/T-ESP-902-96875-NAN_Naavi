import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/services/tracking/location_state_notifier.dart';
import 'package:naavi/core/services/tracking/tracking_location_service.dart';
import 'package:naavi/core/services/statistics/statistics_service.dart';
import 'package:naavi/core/services/tracking/camera_mode_service.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/core/models/location_state.dart';
import 'package:naavi/presentation/improvise/state/ImproviseHikeState.dart';
import 'package:naavi/presentation/improvise/state/ImproviseHikeStateNotifier.dart';

// Mocks
class MockLocationStateNotifier extends Mock implements LocationStateNotifier {}

class MockTrackingLocationService extends Mock
    implements TrackingLocationService {}

class MockStatisticsService extends Mock implements StatisticsService {}

class MockCameraModeManager extends Mock implements CameraModeManager {}

class MockPoiService extends Mock implements PoiService {}

class MockMapboxMap extends Mock implements MapboxMap {}

class MockLocationSettings extends Mock implements LocationSettings {}

class FakePosition extends Fake implements gl.Position {
  @override
  final double latitude;

  @override
  final double longitude;

  @override
  final double altitude;

  @override
  final double accuracy;

  @override
  final double heading;

  @override
  final double speed;

  @override
  final double speedAccuracy;

  @override
  final DateTime timestamp;

  FakePosition({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.accuracy = 0.0,
    this.heading = 0.0,
    this.speed = 0.0,
    this.speedAccuracy = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakePosition(latitude: 0.0, longitude: 0.0));
    registerFallbackValue(MockMapboxMap());
    registerFallbackValue(LocationComponentSettings(enabled: true));

    // Mock the asset bundle to return fake navigation arrow bytes
    // Using ServicesBinding to properly mock asset loading
    const MethodChannel assetsChannel = MethodChannel('flutter/assets');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(assetsChannel.name, (ByteData? message) async {
          // Return fake PNG bytes as ByteData
          final fakeBytes = Uint8List.fromList([
            137, 80, 78, 71, 13, 10, 26, 10, // PNG header
            0, 0, 0, 13, 73, 72, 68, 82, // IHDR chunk
            0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222,
            0, 0, 0, 12, 73, 68, 65, 84, // IDAT chunk
            8, 215, 99, 248, 207, 192, 0, 0, 0, 4, 0, 1, 249, 78, 186, 104,
            0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130, // IEND chunk
          ]);
          return ByteData.view(fakeBytes.buffer);
        });
  });

  group('ImproviseHikeStateNotifier', () {
    late ImproviseHikeStateNotifier notifier;
    late MockLocationStateNotifier mockLocationStateNotifier;
    late MockTrackingLocationService mockTrackingLocationService;
    late MockStatisticsService mockStatisticsService;
    late MockCameraModeManager mockCameraModeManager;
    late MockPoiService mockPoiService;
    late MockMapboxMap mockMapboxMap;
    late MockLocationSettings mockLocationSettings;
    late gl.Position testPosition;

    setUp(() {
      mockLocationStateNotifier = MockLocationStateNotifier();
      mockTrackingLocationService = MockTrackingLocationService();
      mockStatisticsService = MockStatisticsService();
      mockCameraModeManager = MockCameraModeManager();
      mockPoiService = MockPoiService();
      mockMapboxMap = MockMapboxMap();
      mockLocationSettings = MockLocationSettings();

      testPosition = FakePosition(
        latitude: 48.8566,
        longitude: 2.3522,
        altitude: 35.0,
        accuracy: 5.0,
      );

      notifier = ImproviseHikeStateNotifier(
        locationStateNotifier: mockLocationStateNotifier,
        trackingLocation: mockTrackingLocationService,
        statisticsService: mockStatisticsService,
        cameraModeManager: mockCameraModeManager,
        poiService: mockPoiService,
      );

      // Setup common stubs
      when(
        () => mockLocationStateNotifier.state,
      ).thenReturn(LocationState(currentPosition: testPosition));
      when(() => mockTrackingLocationService.stopTracking()).thenReturn(null);
      when(
        () => mockTrackingLocationService.clearTracking(),
      ).thenAnswer((_) async {});
      when(() => mockStatisticsService.startTimer()).thenReturn(null);
      when(() => mockPoiService.clearHikePois()).thenReturn(null);
      when(
        () => mockCameraModeManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockTrackingLocationService.setStartPoint(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockTrackingLocationService.startTracking(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockTrackingLocationService.setUserExploring(any()),
      ).thenReturn(null);
      // Mock for MapService.setupNavigationArrow
      when(() => mockMapboxMap.location).thenReturn(mockLocationSettings);
      when(
        () => mockLocationSettings.updateSettings(any()),
      ).thenAnswer((_) async {});
    });

    test('initial state should be ImproviseHikeIdle', () {
      expect(notifier.state, isA<ImproviseHikeIdle>());
    });

    group('isActive getter', () {
      test('should return false when state is idle', () {
        expect(notifier.isActive, false);
      });

      test('should return true when state is active', () {
        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: DateTime.now(),
        );
        expect(notifier.isActive, true);
      });

      test('should return false when state is starting', () {
        notifier.state = const ImproviseHikeStarting();
        expect(notifier.isActive, false);
      });

      test('should return false when state is finished', () {
        notifier.state = ImproviseHikeFinished(
          startPoint: testPosition,
          endPoint: testPosition,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
          segments: [],
          distanceKm: 5.0,
          duration: const Duration(hours: 1),
        );
        expect(notifier.isActive, false);
      });
    });

    group('isStarting getter', () {
      test('should return false when state is idle', () {
        expect(notifier.isStarting, false);
      });

      test('should return true when state is starting', () {
        notifier.state = const ImproviseHikeStarting();
        expect(notifier.isStarting, true);
      });

      test('should return false when state is active', () {
        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: DateTime.now(),
        );
        expect(notifier.isStarting, false);
      });
    });

    group('isFinished getter', () {
      test('should return false when state is idle', () {
        expect(notifier.isFinished, false);
      });

      test('should return true when state is finished', () {
        notifier.state = ImproviseHikeFinished(
          startPoint: testPosition,
          endPoint: testPosition,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
          segments: [],
          distanceKm: 5.0,
          duration: const Duration(hours: 1),
        );
        expect(notifier.isFinished, true);
      });

      test('should return false when state is active', () {
        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: DateTime.now(),
        );
        expect(notifier.isFinished, false);
      });
    });

    group('startHike', () {
      test(
        'should transition from idle to starting to active on successful start',
        () async {
          final states = <ImproviseHikeState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);
          await Future.delayed(Duration.zero);

          expect(states.length, 2);
          expect(states[0], isA<ImproviseHikeStarting>());
          expect(states[1], isA<ImproviseHikeActive>());

          final activeState = states[1] as ImproviseHikeActive;
          expect(activeState.startPoint, testPosition);

          await subscription.cancel();
        },
      );

      test('should call all required services in correct order', () async {
        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        // Verify cleanup calls
        verify(() => mockTrackingLocationService.stopTracking()).called(1);
        verify(() => mockTrackingLocationService.clearTracking()).called(1);

        // Verify initialization calls
        verify(() => mockStatisticsService.startTimer()).called(1);
        verify(() => mockPoiService.clearHikePois()).called(1);

        // Verify tracking setup
        verify(
          () => mockCameraModeManager.enableFirstPersonMode(testPosition),
        ).called(1);
        verify(
          () => mockTrackingLocationService.setStartPoint(
            testPosition,
            mockMapboxMap,
          ),
        ).called(1);
        verify(
          () => mockTrackingLocationService.startTracking(mockMapboxMap),
        ).called(1);
        verify(
          () => mockTrackingLocationService.setUserExploring(false),
        ).called(1);
      });

      test('should not start if already starting', () async {
        notifier.state = const ImproviseHikeStarting();

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        // State should remain starting
        expect(notifier.state, isA<ImproviseHikeStarting>());

        // Services should not be called
        verifyNever(() => mockStatisticsService.startTimer());
      });

      test('should not start if already active', () async {
        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: DateTime.now(),
        );

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        // State should remain active
        expect(notifier.state, isA<ImproviseHikeActive>());

        // Services should not be called
        verifyNever(() => mockStatisticsService.startTimer());
      });

      test(
        'should emit error state when GPS position is not available',
        () async {
          when(
            () => mockLocationStateNotifier.state,
          ).thenReturn(const LocationState(currentPosition: null));
          when(
            () => mockLocationStateNotifier.getCurrentPosition(),
          ).thenAnswer((_) async => null);

          await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

          expect(notifier.state, isA<ImproviseHikeError>());
          final errorState = notifier.state as ImproviseHikeError;
          expect(errorState.message, 'GPS non disponible');
          expect(errorState.reasons.isNotEmpty, true);
        },
      );

      test('should emit error state when map is not ready', () async {
        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: false);

        expect(notifier.state, isA<ImproviseHikeError>());
        final errorState = notifier.state as ImproviseHikeError;
        expect(errorState.message, 'Carte pas prête');
      });

      test('should emit error state when camera manager is null', () async {
        notifier = ImproviseHikeStateNotifier(
          locationStateNotifier: mockLocationStateNotifier,
          trackingLocation: mockTrackingLocationService,
          statisticsService: mockStatisticsService,
          cameraModeManager: null,
          poiService: mockPoiService,
        );

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        expect(notifier.state, isA<ImproviseHikeError>());
        final errorState = notifier.state as ImproviseHikeError;
        expect(errorState.message, 'Caméra non initialisée');
      });

      test('should handle exception during start', () async {
        when(
          () => mockCameraModeManager.enableFirstPersonMode(any()),
        ).thenThrow(Exception('Camera error'));

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        expect(notifier.state, isA<ImproviseHikeError>());
        final errorState = notifier.state as ImproviseHikeError;
        expect(errorState.message, 'Erreur lors du démarrage');
        expect(errorState.reasons.first, contains('Exception'));
      });

      test(
        'should use getCurrentPosition if current position is null',
        () async {
          // Reconfigure les mocks pour ce test spécifique
          when(
            () => mockLocationStateNotifier.state,
          ).thenReturn(const LocationState(currentPosition: null));
          when(
            () => mockLocationStateNotifier.getCurrentPosition(),
          ).thenAnswer((_) => Future.value(testPosition));
          when(
            () => mockTrackingLocationService.stopTracking(),
          ).thenReturn(null);
          when(
            () => mockTrackingLocationService.clearTracking(),
          ).thenAnswer((_) async {});
          when(() => mockStatisticsService.startTimer()).thenReturn(null);
          when(() => mockPoiService.clearHikePois()).thenReturn(null);
          when(
            () => mockCameraModeManager.enableFirstPersonMode(any()),
          ).thenAnswer((_) async {});
          when(
            () => mockTrackingLocationService.setStartPoint(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockTrackingLocationService.startTracking(any()),
          ).thenAnswer((_) async {});
          when(
            () => mockTrackingLocationService.setUserExploring(any()),
          ).thenReturn(null);

          await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

          expect(notifier.state, isA<ImproviseHikeActive>());
          verify(
            () => mockLocationStateNotifier.getCurrentPosition(),
          ).called(1);
        },
      );

      test('should handle timeout when getting position', () async {
        when(
          () => mockLocationStateNotifier.state,
        ).thenReturn(const LocationState(currentPosition: null));
        when(() => mockLocationStateNotifier.getCurrentPosition()).thenAnswer(
          (_) => Future.delayed(const Duration(seconds: 5), () => testPosition),
        );

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        // Should handle timeout and emit error
        expect(notifier.state, isA<ImproviseHikeError>());
      });
    });

    group('finishHike', () {
      setUp(() {
        // Set notifier to active state
        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(
          () => mockCameraModeManager.disableFirstPersonMode(),
        ).thenAnswer((_) async {});
        when(
          () => mockLocationStateNotifier.getCurrentPosition(),
        ).thenAnswer((_) async => testPosition);
      });

      test('should transition from active to finished state', () async {
        final segments = [
          [testPosition],
        ];
        final distanceKm = 5.0;

        await notifier.finishHike(segments: segments, distanceKm: distanceKm);

        expect(notifier.state, isA<ImproviseHikeFinished>());
        final finishedState = notifier.state as ImproviseHikeFinished;
        expect(finishedState.startPoint, testPosition);
        expect(finishedState.endPoint, testPosition);
        expect(finishedState.segments, segments);
        expect(finishedState.distanceKm, distanceKm);
      });

      test('should stop tracking and disable first person mode', () async {
        await notifier.finishHike(segments: [], distanceKm: 0.0);

        verify(() => mockTrackingLocationService.stopTracking()).called(1);
        verify(() => mockCameraModeManager.disableFirstPersonMode()).called(1);
      });

      test('should not finish if not in active state', () async {
        notifier.state = const ImproviseHikeIdle();

        await notifier.finishHike(segments: [], distanceKm: 0.0);

        // State should remain idle
        expect(notifier.state, isA<ImproviseHikeIdle>());

        // Services should not be called
        verifyNever(() => mockTrackingLocationService.stopTracking());
      });

      test('should emit finished state with correct timing', () async {
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: startTime,
        );

        final beforeFinish = DateTime.now();
        await notifier.finishHike(segments: [], distanceKm: 10.5);
        final afterFinish = DateTime.now();

        expect(notifier.state, isA<ImproviseHikeFinished>());
        final finishedState = notifier.state as ImproviseHikeFinished;
        expect(finishedState.startTime, startTime);
        expect(finishedState.endTime.isAfter(beforeFinish), true);
        expect(finishedState.endTime.isBefore(afterFinish), true);
      });

      test('should handle null end position', () async {
        when(
          () => mockLocationStateNotifier.getCurrentPosition(),
        ).thenAnswer((_) async => null);

        await notifier.finishHike(segments: [], distanceKm: 5.0);

        expect(notifier.state, isA<ImproviseHikeFinished>());
        final finishedState = notifier.state as ImproviseHikeFinished;
        expect(finishedState.endPoint, null);
      });

      test('should preserve start point from active state', () async {
        final differentPosition = FakePosition(latitude: 45.0, longitude: 3.0);
        notifier.state = ImproviseHikeActive(
          startPoint: differentPosition,
          startTime: DateTime.now(),
        );

        await notifier.finishHike(segments: [], distanceKm: 0.0);

        final finishedState = notifier.state as ImproviseHikeFinished;
        expect(finishedState.startPoint, differentPosition);
      });
    });

    group('exitFirstPersonMode', () {
      test('should stop tracking and disable first person mode', () async {
        when(
          () => mockCameraModeManager.disableFirstPersonMode(),
        ).thenAnswer((_) async {});

        await notifier.exitFirstPersonMode();

        verify(() => mockTrackingLocationService.stopTracking()).called(1);
        verify(() => mockCameraModeManager.disableFirstPersonMode()).called(1);
      });

      test('should handle exception during exit', () async {
        when(
          () => mockCameraModeManager.disableFirstPersonMode(),
        ).thenThrow(Exception('Exit error'));

        expect(() => notifier.exitFirstPersonMode(), throwsException);
      });

      test('should not change state', () async {
        when(
          () => mockCameraModeManager.disableFirstPersonMode(),
        ).thenAnswer((_) async {});

        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: DateTime.now(),
        );

        await notifier.exitFirstPersonMode();

        // State should remain active
        expect(notifier.state, isA<ImproviseHikeActive>());
      });
    });

    group('reset', () {
      test('should reset state to idle', () async {
        notifier.state = ImproviseHikeFinished(
          startPoint: testPosition,
          endPoint: testPosition,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          segments: [],
          distanceKm: 5.0,
          duration: Duration.zero,
        );

        await notifier.reset();

        expect(notifier.state, isA<ImproviseHikeIdle>());
      });

      test('should reset from error state', () async {
        notifier.state = const ImproviseHikeError(
          message: 'Test error',
          reasons: ['Reason 1'],
        );

        await notifier.reset();

        expect(notifier.state, isA<ImproviseHikeIdle>());
      });

      test('should reset from active state', () async {
        notifier.state = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: DateTime.now(),
        );

        await notifier.reset();

        expect(notifier.state, isA<ImproviseHikeIdle>());
      });
    });

    group('State Transitions', () {
      test(
        'should follow complete lifecycle: idle -> starting -> active -> finished -> idle',
        () async {
          final states = <ImproviseHikeState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          when(
            () => mockCameraModeManager.disableFirstPersonMode(),
          ).thenAnswer((_) async {});
          when(
            () => mockLocationStateNotifier.getCurrentPosition(),
          ).thenAnswer((_) async => testPosition);

          // idle -> starting -> active
          expect(notifier.state, isA<ImproviseHikeIdle>());
          await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);
          await Future.delayed(Duration.zero);

          // active -> finished
          await notifier.finishHike(segments: [], distanceKm: 5.0);
          await Future.delayed(Duration.zero);

          // finished -> idle
          await notifier.reset();
          await Future.delayed(Duration.zero);

          expect(states.length, 4);
          expect(states[0], isA<ImproviseHikeStarting>());
          expect(states[1], isA<ImproviseHikeActive>());
          expect(states[2], isA<ImproviseHikeFinished>());
          expect(states[3], isA<ImproviseHikeIdle>());

          await subscription.cancel();
        },
      );

      test('should handle error during start and allow reset', () async {
        when(
          () => mockLocationStateNotifier.state,
        ).thenReturn(const LocationState(currentPosition: null));
        when(
          () => mockLocationStateNotifier.getCurrentPosition(),
        ).thenAnswer((_) async => null);

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        expect(notifier.state, isA<ImproviseHikeError>());

        await notifier.reset();

        expect(notifier.state, isA<ImproviseHikeIdle>());
      });

      test(
        'should maintain active state when attempting invalid finish',
        () async {
          notifier.state = const ImproviseHikeIdle();

          await notifier.finishHike(segments: [], distanceKm: 0.0);

          // Should remain idle since not in active state
          expect(notifier.state, isA<ImproviseHikeIdle>());
        },
      );
    });

    group('ImproviseHikeActive.elapsedTime', () {
      test('should calculate elapsed time correctly', () async {
        final startTime = DateTime.now().subtract(const Duration(minutes: 30));
        final activeState = ImproviseHikeActive(
          startPoint: testPosition,
          startTime: startTime,
        );

        final elapsed = activeState.elapsedTime;

        expect(elapsed.inMinutes, greaterThanOrEqualTo(29));
        expect(elapsed.inMinutes, lessThanOrEqualTo(31));
      });
    });

    group('ImproviseHikeFinished.duration', () {
      test('should calculate duration correctly', () {
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        final endTime = DateTime.now();
        final finishedState = ImproviseHikeFinished(
          startPoint: testPosition,
          endPoint: testPosition,
          startTime: startTime,
          endTime: endTime,
          segments: [],
          distanceKm: 5.0,
          duration: const Duration(hours: 2),
        );

        final duration = finishedState.duration;

        expect(duration.inHours, equals(2));
      });
    });

    group('Error Handling', () {
      test('should handle null statistics service gracefully', () async {
        notifier = ImproviseHikeStateNotifier(
          locationStateNotifier: mockLocationStateNotifier,
          trackingLocation: mockTrackingLocationService,
          statisticsService: null,
          cameraModeManager: mockCameraModeManager,
          poiService: mockPoiService,
        );

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        expect(notifier.state, isA<ImproviseHikeActive>());
      });

      test('should preserve error reasons in error state', () async {
        when(
          () => mockLocationStateNotifier.state,
        ).thenReturn(const LocationState(currentPosition: null));
        when(
          () => mockLocationStateNotifier.getCurrentPosition(),
        ).thenAnswer((_) async => null);

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        expect(notifier.state, isA<ImproviseHikeError>());
        final errorState = notifier.state as ImproviseHikeError;
        expect(errorState.reasons, isNotEmpty);
        expect(
          errorState.reasons.first,
          contains('Position GPS non disponible'),
        );
      });

      test('should handle multiple errors correctly', () async {
        // Test GPS error
        when(
          () => mockLocationStateNotifier.state,
        ).thenReturn(const LocationState(currentPosition: null));
        when(
          () => mockLocationStateNotifier.getCurrentPosition(),
        ).thenAnswer((_) async => null);

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: true);

        expect(notifier.state, isA<ImproviseHikeError>());

        // Reset and test map not ready error
        await notifier.reset();
        when(
          () => mockLocationStateNotifier.state,
        ).thenReturn(LocationState(currentPosition: testPosition));

        await notifier.startHike(mapboxMap: mockMapboxMap, isMapReady: false);

        expect(notifier.state, isA<ImproviseHikeError>());
        expect(
          (notifier.state as ImproviseHikeError).message,
          'Carte pas prête',
        );
      });
    });
  });
}
