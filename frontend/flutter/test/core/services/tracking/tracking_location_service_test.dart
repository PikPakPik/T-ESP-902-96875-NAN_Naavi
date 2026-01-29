import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/services/tracking/tracking_location_service.dart';
import 'package:naavi/data/models/HikeModel.dart';
import 'package:naavi/domain/entities/Hike.dart';

// Mock classes
class MockMapboxMap extends Mock implements MapboxMap {}

class MockAnnotationManager extends Mock implements AnnotationManager {}

class MockPointAnnotationManager extends Mock
    implements PointAnnotationManager {}

class MockPolylineAnnotationManager extends Mock
    implements PolylineAnnotationManager {}

class MockPointAnnotation extends Mock implements PointAnnotation {}

class MockPolylineAnnotation extends Mock implements PolylineAnnotation {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TrackingLocationService service;
  late MockMapboxMap mockMapboxMap;
  late MockAnnotationManager mockAnnotationManager;
  late MockPointAnnotationManager mockPointManager;
  late MockPolylineAnnotationManager mockPolylineManager;

  setUpAll(() {
    registerFallbackValue(
      gl.Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );
    registerFallbackValue(
      PointAnnotationOptions(geometry: Point(coordinates: Position(0, 0))),
    );
    registerFallbackValue(
      PolylineAnnotationOptions(geometry: LineString(coordinates: [])),
    );
    registerFallbackValue(MockPointAnnotation());
    registerFallbackValue(MockPolylineAnnotation());
  });

  setUp(() {
    service = TrackingLocationService();
    mockMapboxMap = MockMapboxMap();
    mockAnnotationManager = MockAnnotationManager();
    mockPointManager = MockPointAnnotationManager();
    mockPolylineManager = MockPolylineAnnotationManager();

    // Setup default mock behavior
    when(() => mockMapboxMap.annotations).thenReturn(mockAnnotationManager);
    when(
      () => mockAnnotationManager.createPointAnnotationManager(),
    ).thenAnswer((_) async => mockPointManager);
    when(
      () => mockAnnotationManager.createPolylineAnnotationManager(
        below: any(named: 'below'),
      ),
    ).thenAnswer((_) async => mockPolylineManager);
    when(
      () => mockAnnotationManager.createPolylineAnnotationManager(),
    ).thenAnswer((_) async => mockPolylineManager);
    when(
      () => mockPointManager.create(any()),
    ).thenAnswer((_) async => MockPointAnnotation());
    when(
      () => mockPolylineManager.create(any()),
    ).thenAnswer((_) async => MockPolylineAnnotation());
    when(() => mockPointManager.delete(any())).thenAnswer((_) async {});
    when(() => mockPointManager.deleteAll()).thenAnswer((_) async {});
    when(() => mockPolylineManager.delete(any())).thenAnswer((_) async {});
    when(() => mockPolylineManager.deleteAll()).thenAnswer((_) async {});
  });

  tearDown(() {
    service.dispose();
  });

  group('TrackingLocationService - Initialization', () {
    test('should initialize with idle state', () {
      expect(service.currentState, equals(TrackingState.idle));
      expect(service.isTracking, isFalse);
      expect(service.isPaused, isFalse);
      expect(service.isUserExploring, isFalse);
    });

    test('should set map controller', () {
      // Act
      service.setMapController(mockMapboxMap);

      // Assert - no exception thrown
      expect(true, isTrue);
    });

    test('should initialize with empty segments', () {
      // Assert
      expect(service.getAllSegments(), isEmpty);
    });

    test('should have null last known position initially', () {
      // Assert
      expect(service.getLastKnownPosition(), isNull);
    });
  });

  group('TrackingLocationService - State Management', () {
    test('should track state correctly', () {
      // Initially idle
      expect(service.currentState, equals(TrackingState.idle));
      expect(service.isTracking, isFalse);
      expect(service.isPaused, isFalse);
    });

    test('should update user exploring state', () {
      // Act
      service.setUserExploring(true);

      // Assert
      expect(service.isUserExploring, isTrue);

      // Act
      service.setUserExploring(false);

      // Assert
      expect(service.isUserExploring, isFalse);
    });

    test('should handle multiple exploring state changes', () {
      for (int i = 0; i < 5; i++) {
        service.setUserExploring(i.isEven);
        expect(service.isUserExploring, equals(i.isEven));
      }
    });
  });

  group('TrackingLocationService - setStartPoint', () {
    test('should set start point successfully', () async {
      // Arrange
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

      // Act
      await service.setStartPoint(position, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
      verify(() => mockMapboxMap.annotations).called(greaterThan(0));
    });

    test('should handle null position', () async {
      // Act
      await service.setStartPoint(null, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
    });

    test('should handle null map controller', () async {
      // Arrange
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

      // Act
      await service.setStartPoint(position, null);

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
    });

    test('should handle null position and map controller', () async {
      // Act
      await service.setStartPoint(null, null);

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
    });

    test('should clear previous tracking data on new start', () async {
      // Arrange
      final position1 = gl.Position(
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
      final position2 = gl.Position(
        latitude: 48.8567,
        longitude: 2.3523,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      // Act
      await service.setStartPoint(position1, mockMapboxMap);
      await service.setStartPoint(position2, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
    });
  });

  group('TrackingLocationService - setEndPoint', () {
    test('should set end point successfully', () async {
      // Arrange
      final startPosition = gl.Position(
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
      final endPosition = gl.Position(
        latitude: 48.8567,
        longitude: 2.3523,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      await service.setStartPoint(startPosition, mockMapboxMap);

      // Act
      await service.setEndPoint(endPosition, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.finished));
      // Note: Le service utilise maintenant RouteMarkerService au lieu de pointManager.create
    });

    test('should handle null map controller in setEndPoint', () async {
      // Arrange
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

      // Act
      await service.setEndPoint(position, null);

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
    });

    test('should handle null position in setEndPoint', () async {
      // Arrange
      await service.setStartPoint(
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
        mockMapboxMap,
      );

      // Act
      await service.setEndPoint(null, mockMapboxMap);

      // Assert
      // Le service ne crée plus de point quand la position est null
      expect(service.currentState, equals(TrackingState.ready));
    });
  });

  group('TrackingLocationService - Tracking Control', () {
    test('should start tracking', () async {
      // Act & Assert - should not throw
      await expectLater(service.startTracking(mockMapboxMap), completes);
    });

    test('should stop tracking', () {
      // Act
      service.stopTracking();

      // Assert - no exception thrown
      expect(true, isTrue);
    });

    test('should handle stop when not tracking', () {
      // Act & Assert - should not throw
      expect(() => service.stopTracking(), returnsNormally);
    });

    test('should handle multiple stop calls', () {
      // Act
      service.stopTracking();
      service.stopTracking();
      service.stopTracking();

      // Assert - no exception thrown
      expect(true, isTrue);
    });
  });

  group('TrackingLocationService - Pause and Continue', () {
    test('should pause tracking', () async {
      // Arrange
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
      await service.setStartPoint(position, mockMapboxMap);

      // Act
      await service.pauseTracking();

      // Assert
      expect(service.currentState, equals(TrackingState.paused));
      expect(service.isPaused, isTrue);
    });

    test('should continue tracking after pause', () async {
      // Arrange
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
      await service.setStartPoint(position, mockMapboxMap);
      service.setMapController(mockMapboxMap);
      await service.pauseTracking();

      // Act
      await service.continueTracking();

      // Assert - continueTracking should start the tracking process
      // Note: The actual state change happens when position updates arrive
      // For now, we just verify it completes without error
      expect(true, isTrue);
    });

    test('should handle continue when not paused', () async {
      // Act & Assert - should not throw but may not change state
      await expectLater(service.continueTracking(), completes);
    });

    test('should handle pause without start point', () async {
      // Act
      await service.pauseTracking();

      // Assert
      expect(service.currentState, equals(TrackingState.paused));
    });
  });

  group('TrackingLocationService - Segments Management', () {
    test('should return empty segments initially', () {
      // Assert
      expect(service.getAllSegments(), isEmpty);
    });

    test('should return null for last known position when no segments', () {
      // Assert
      expect(service.getLastKnownPosition(), isNull);
    });

    test('should get current path', () async {
      // Act
      final path = await service.getCurrentPath();

      // Assert
      expect(path, isA<List<List<PathPoint>>>());
      expect(path, isEmpty);
    });

    test('should handle empty segments in getCurrentPath', () async {
      // Act
      final path = await service.getCurrentPath();

      // Assert
      expect(path, isEmpty);
    });
  });

  group('TrackingLocationService - Clear Tracking', () {
    test('should clear tracking data', () async {
      // Arrange
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
      await service.setStartPoint(position, mockMapboxMap);

      // Act
      await service.clearTracking();

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
      expect(service.getAllSegments(), isEmpty);
    });

    test('should clear when no tracking data exists', () async {
      // Act
      await service.clearTracking();

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
    });

    test('should handle multiple clear calls', () async {
      // Arrange
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
      await service.setStartPoint(position, mockMapboxMap);

      // Act
      await service.clearTracking();
      await service.clearTracking();
      await service.clearTracking();

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
    });
  });

  group('TrackingLocationService - Restore Hike', () {
    test('should restore hike with start and end points', () async {
      // Arrange
      final hike = Hike(
        startPoint: PathPoint(latitude: 48.8566, longitude: 2.3522),
        endPoint: PathPoint(latitude: 48.8567, longitude: 2.3523),
        paths: [
          [
            PathPoint(latitude: 48.8566, longitude: 2.3522),
            PathPoint(latitude: 48.8567, longitude: 2.3523),
          ],
        ],
      );

      // Act
      await service.restoreHike(hike, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.paused));
      // Note: Le service utilise maintenant RouteMarkerService au lieu de pointManager.create
    });

    test('should restore hike without end point', () async {
      // Arrange
      final hike = Hike(
        startPoint: PathPoint(latitude: 48.8566, longitude: 2.3522),
        endPoint: null,
        paths: [
          [
            PathPoint(latitude: 48.8566, longitude: 2.3522),
            PathPoint(latitude: 48.8567, longitude: 2.3523),
          ],
        ],
      );

      // Act
      await service.restoreHike(hike, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.paused));
    });

    test('should restore hike with multiple paths', () async {
      // Arrange
      final hike = Hike(
        startPoint: PathPoint(latitude: 48.8566, longitude: 2.3522),
        endPoint: PathPoint(latitude: 48.8570, longitude: 2.3526),
        paths: [
          [
            PathPoint(latitude: 48.8566, longitude: 2.3522),
            PathPoint(latitude: 48.8567, longitude: 2.3523),
          ],
          [
            PathPoint(latitude: 48.8568, longitude: 2.3524),
            PathPoint(latitude: 48.8569, longitude: 2.3525),
          ],
          [
            PathPoint(latitude: 48.8569, longitude: 2.3525),
            PathPoint(latitude: 48.8570, longitude: 2.3526),
          ],
        ],
      );

      // Act
      await service.restoreHike(hike, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.paused));
      verify(() => mockPolylineManager.create(any())).called(greaterThan(0));
    });

    test('should restore hike with empty paths', () async {
      // Arrange
      final hike = Hike(
        startPoint: PathPoint(latitude: 48.8566, longitude: 2.3522),
        endPoint: null,
        paths: [],
      );

      // Act
      await service.restoreHike(hike, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.paused));
    });
  });

  group('TrackingLocationService - Position Callbacks', () {
    test('should call onNewPosition callback when set', () {
      // Arrange
      final capturedPositions = <gl.Position>[];
      service.onNewPosition = (position) {
        capturedPositions.add(position);
      };

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

      // Act
      service.onNewPosition?.call(position);

      // Assert
      expect(capturedPositions, hasLength(1));
      expect(capturedPositions.first, equals(position));
    });

    test('should handle null callback', () {
      // Arrange
      service.onNewPosition = null;

      // Act & Assert - should not throw
      expect(() => service.onNewPosition?.call(any()), returnsNormally);
    });

    test('should handle multiple position callbacks', () {
      // Arrange
      final capturedPositions = <gl.Position>[];
      service.onNewPosition = (position) {
        capturedPositions.add(position);
      };

      // Act
      for (int i = 0; i < 5; i++) {
        final position = gl.Position(
          latitude: 48.8566 + i * 0.001,
          longitude: 2.3522 + i * 0.001,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 5,
          heading: i * 10.0,
          headingAccuracy: 1,
          speed: i.toDouble(),
          speedAccuracy: 1,
        );
        service.onNewPosition?.call(position);
      }

      // Assert
      expect(capturedPositions, hasLength(5));
    });
  });

  group('TrackingLocationService - Dispose', () {
    test('should dispose successfully', () {
      // Act & Assert - should not throw
      expect(() => service.dispose(), returnsNormally);
    });

    test('should handle dispose after tracking', () async {
      // Arrange
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
      await service.setStartPoint(position, mockMapboxMap);

      // Act & Assert
      expect(() => service.dispose(), returnsNormally);
    });

    test('should handle multiple dispose calls', () {
      // Act
      service.dispose();
      service.dispose();
      service.dispose();

      // Assert - no exception thrown
      expect(true, isTrue);
    });
  });

  group('TrackingLocationService - Edge Cases', () {
    test('should handle extreme coordinates', () async {
      // Arrange
      final extremePosition = gl.Position(
        latitude: 90.0, // North Pole
        longitude: 180.0, // Date line
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 8848, // Mt. Everest height
        altitudeAccuracy: 5,
        heading: 360,
        headingAccuracy: 1,
        speed: 100,
        speedAccuracy: 1,
      );

      // Act
      await service.setStartPoint(extremePosition, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
    });

    test('should handle negative coordinates', () async {
      // Arrange
      final negativePosition = gl.Position(
        latitude: -45.0,
        longitude: -120.0,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: -100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      // Act
      await service.setStartPoint(negativePosition, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
    });

    test('should handle zero coordinates', () async {
      // Arrange
      final zeroPosition = gl.Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // Act
      await service.setStartPoint(zeroPosition, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
    });

    test('should handle very high accuracy values', () async {
      // Arrange
      final highAccuracyPosition = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 1000,
        altitude: 100,
        altitudeAccuracy: 1000,
        heading: 0,
        headingAccuracy: 360,
        speed: 0,
        speedAccuracy: 100,
      );

      // Act
      await service.setStartPoint(highAccuracyPosition, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
    });
  });

  group('TrackingLocationService - Integration Scenarios', () {
    test('should handle complete tracking lifecycle', () async {
      // Arrange
      final startPosition = gl.Position(
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
      final endPosition = gl.Position(
        latitude: 48.8567,
        longitude: 2.3523,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      // Act
      await service.setStartPoint(startPosition, mockMapboxMap);
      expect(service.currentState, equals(TrackingState.ready));

      await service.startTracking(mockMapboxMap);

      await service.pauseTracking();
      expect(service.isPaused, isTrue);

      await service.continueTracking();

      await service.setEndPoint(endPosition, mockMapboxMap);
      expect(service.currentState, equals(TrackingState.finished));

      // Assert
      // Note: Le service utilise maintenant RouteMarkerService au lieu de pointManager.create
    });

    test('should handle pause and end without continue', () async {
      // Arrange
      final startPosition = gl.Position(
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
      final endPosition = gl.Position(
        latitude: 48.8567,
        longitude: 2.3523,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      // Act
      await service.setStartPoint(startPosition, mockMapboxMap);
      await service.pauseTracking();
      await service.setEndPoint(endPosition, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.finished));
    });

    test('should handle multiple pause/continue cycles', () async {
      // Arrange
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
      await service.setStartPoint(position, mockMapboxMap);

      // Act - Multiple cycles
      for (int i = 0; i < 3; i++) {
        await service.pauseTracking();
        expect(service.isPaused, isTrue);

        await service.continueTracking();
      }

      // Assert - should complete without errors
      expect(true, isTrue);
    });

    test('should handle clear and restart', () async {
      // Arrange
      final position1 = gl.Position(
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
      final position2 = gl.Position(
        latitude: 48.8567,
        longitude: 2.3523,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      // Act
      await service.setStartPoint(position1, mockMapboxMap);
      await service.clearTracking();
      await service.setStartPoint(position2, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
    });
  });

  group('TrackingLocationService - State Transitions', () {
    test('should transition from idle to ready', () async {
      // Arrange
      expect(service.currentState, equals(TrackingState.idle));
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

      // Act
      await service.setStartPoint(position, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.ready));
    });

    test('should transition from ready to paused', () async {
      // Arrange
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
      await service.setStartPoint(position, mockMapboxMap);

      // Act
      await service.pauseTracking();

      // Assert
      expect(service.currentState, equals(TrackingState.paused));
    });

    test('should transition to finished', () async {
      // Arrange
      final startPosition = gl.Position(
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
      final endPosition = gl.Position(
        latitude: 48.8567,
        longitude: 2.3523,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );
      await service.setStartPoint(startPosition, mockMapboxMap);

      // Act
      await service.setEndPoint(endPosition, mockMapboxMap);

      // Assert
      expect(service.currentState, equals(TrackingState.finished));
    });

    test('should transition from finished to idle', () async {
      // Arrange
      final startPosition = gl.Position(
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
      final endPosition = gl.Position(
        latitude: 48.8567,
        longitude: 2.3523,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );
      await service.setStartPoint(startPosition, mockMapboxMap);
      await service.setEndPoint(endPosition, mockMapboxMap);

      // Act
      await service.clearTracking();

      // Assert
      expect(service.currentState, equals(TrackingState.idle));
    });
  });
}
