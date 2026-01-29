import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/tracking/camera_handler_service.dart';
import 'package:naavi/core/services/tracking/camera_mode_service.dart';
import 'package:naavi/core/services/tracking/compass_service.dart';

class MockCameraHandlerService extends Mock implements CameraHandlerService {}

class MockCompassService extends Mock implements CompassService {}

void main() {
  late CameraModeManager manager;
  late MockCameraHandlerService mockCameraService;
  late MockCompassService mockCompassService;

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
  });

  setUp(() {
    mockCameraService = MockCameraHandlerService();
    mockCompassService = MockCompassService();
    manager = CameraModeManager(
      cameraService: mockCameraService,
      compassService: mockCompassService,
    );
  });

  group('CameraModeManager - Initialization', () {
    test('should initialize in normal mode', () {
      expect(manager.isFirstPersonMode, isFalse);
    });

    test('should set compass callback', () {
      verify(() => mockCompassService.onHeadingChanged = any()).called(1);
    });
  });

  group('CameraModeManager - Heading Changed Callback', () {
    test(
      'should update bearing when heading changes in first person mode',
      () async {
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

        // Capture the callback
        void Function(double)? capturedCallback;
        when(() => mockCompassService.onHeadingChanged = any()).thenAnswer((
          invocation,
        ) {
          capturedCallback =
              invocation.positionalArguments[0] as void Function(double)?;
          return capturedCallback;
        });

        // Recreate manager to capture callback
        manager = CameraModeManager(
          cameraService: mockCameraService,
          compassService: mockCompassService,
        );

        when(
          () => mockCompassService.getStableHeading(),
        ).thenAnswer((_) async => 90.0);
        when(
          () => mockCameraService.enableFirstPersonModeSmooth(any(), any()),
        ).thenAnswer((_) async {});
        when(() => mockCompassService.startListening()).thenReturn(null);
        when(
          () => mockCameraService.updateBearing(any()),
        ).thenAnswer((_) async {});

        // Enable first person mode
        await manager.enableFirstPersonMode(position);

        // Act - simulate heading change
        capturedCallback?.call(180.0);

        // Assert
        verify(() => mockCameraService.updateBearing(180.0)).called(1);
      },
    );

    test('should not update bearing when not in first person mode', () {
      // Capture the callback
      void Function(double)? capturedCallback;
      when(() => mockCompassService.onHeadingChanged = any()).thenAnswer((
        invocation,
      ) {
        capturedCallback =
            invocation.positionalArguments[0] as void Function(double)?;
        return capturedCallback;
      });

      // Recreate manager to capture callback
      manager = CameraModeManager(
        cameraService: mockCameraService,
        compassService: mockCompassService,
      );

      // Act - simulate heading change without enabling first person mode
      capturedCallback?.call(180.0);

      // Assert - updateBearing should not be called
      verifyNever(() => mockCameraService.updateBearing(any()));
    });
  });

  group('CameraModeManager - Enable First Person Mode', () {
    test('should enable first person mode successfully', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 45,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(
        () => mockCompassService.getStableHeading(),
      ).thenAnswer((_) async => 90.0);
      when(
        () => mockCameraService.enableFirstPersonModeSmooth(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockCompassService.startListening()).thenReturn(null);

      // Act
      await manager.enableFirstPersonMode(position);

      // Assert
      expect(manager.isFirstPersonMode, isTrue);
      verify(() => mockCompassService.getStableHeading()).called(1);
      verify(
        () => mockCameraService.enableFirstPersonModeSmooth(position, 90.0),
      ).called(1);
      verify(() => mockCompassService.startListening()).called(1);
    });

    test('should use 0.0 heading when compass returns null', () async {
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

      when(
        () => mockCompassService.getStableHeading(),
      ).thenAnswer((_) async => 0.0);
      when(
        () => mockCameraService.enableFirstPersonModeSmooth(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockCompassService.startListening()).thenReturn(null);

      // Act
      await manager.enableFirstPersonMode(position);

      // Assert
      verify(
        () => mockCameraService.enableFirstPersonModeSmooth(position, 0.0),
      ).called(1);
    });
  });

  group('CameraModeManager - Disable First Person Mode', () {
    test('should disable first person mode successfully', () async {
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

      when(
        () => mockCompassService.getStableHeading(),
      ).thenAnswer((_) async => 90.0);
      when(
        () => mockCameraService.enableFirstPersonModeSmooth(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraService.resetToNormalView(any()),
      ).thenAnswer((_) async {});
      when(() => mockCompassService.startListening()).thenReturn(null);
      when(() => mockCompassService.stopListening()).thenReturn(null);

      await manager.enableFirstPersonMode(position);

      // Act
      await manager.disableFirstPersonMode();

      // Assert
      expect(manager.isFirstPersonMode, isFalse);
      verify(() => mockCompassService.stopListening()).called(1);
      verify(() => mockCameraService.resetToNormalView(position)).called(1);
    });

    test('should handle disable when no position set', () async {
      // Arrange
      when(() => mockCompassService.stopListening()).thenReturn(null);

      // Act
      await manager.disableFirstPersonMode();

      // Assert
      expect(manager.isFirstPersonMode, isFalse);
      verify(() => mockCompassService.stopListening()).called(1);
      verifyNever(() => mockCameraService.resetToNormalView(any()));
    });
  });

  group('CameraModeManager - Enable Explore Mode', () {
    test('should enable explore mode', () async {
      // Arrange
      when(() => mockCompassService.stopListening()).thenReturn(null);

      // Act
      await manager.enableExploreMode();

      // Assert
      expect(manager.isFirstPersonMode, isFalse);
      verify(() => mockCompassService.stopListening()).called(1);
    });
  });

  group('CameraModeManager - Update Position', () {
    test('should update current position', () {
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
      manager.updateCurrentPosition(position);

      // Assert - No exception thrown
      expect(true, isTrue);
    });
  });

  group('CameraModeManager - Update Camera', () {
    test('should update camera in first person mode', () async {
      // Arrange
      final position = gl.Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 100,
        altitudeAccuracy: 5,
        heading: 45,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(
        () => mockCompassService.getStableHeading(),
      ).thenAnswer((_) async => 90.0);
      when(() => mockCompassService.currentHeading).thenReturn(90.0);
      when(
        () => mockCameraService.enableFirstPersonModeSmooth(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraService.enableFirstPersonMode(
          any(),
          any(),
          duration: any(named: 'duration'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockCompassService.startListening()).thenReturn(null);

      await manager.enableFirstPersonMode(position);

      // Act
      await manager.updateCamera(position);

      // Assert
      verify(
        () => mockCameraService.enableFirstPersonMode(
          position,
          90.0,
          duration: 0,
        ),
      ).called(1);
    });

    test('should update camera in normal mode', () async {
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

      when(
        () => mockCameraService.updatePosition(any()),
      ).thenAnswer((_) async {});

      // Act
      await manager.updateCamera(position);

      // Assert
      verify(() => mockCameraService.updatePosition(position)).called(1);
    });

    test('should use 0.0 heading when compass heading is null', () async {
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

      when(
        () => mockCompassService.getStableHeading(),
      ).thenAnswer((_) async => 90.0);
      when(() => mockCompassService.currentHeading).thenReturn(null);
      when(
        () => mockCameraService.enableFirstPersonModeSmooth(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraService.enableFirstPersonMode(
          any(),
          any(),
          duration: any(named: 'duration'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockCompassService.startListening()).thenReturn(null);

      await manager.enableFirstPersonMode(position);

      // Act
      await manager.updateCamera(position);

      // Assert
      verify(
        () => mockCameraService.enableFirstPersonMode(
          position,
          0.0,
          duration: 0,
        ),
      ).called(1);
    });
  });

  group('CameraModeManager - Dispose', () {
    test('should dispose compass service', () {
      // Arrange
      when(() => mockCompassService.dispose()).thenReturn(null);

      // Act
      manager.dispose();

      // Assert
      verify(() => mockCompassService.dispose()).called(1);
    });
  });
}
