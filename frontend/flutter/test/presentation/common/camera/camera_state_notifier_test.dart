import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/tracking/camera_mode_service.dart';
import 'package:naavi/presentation/common/camera/CameraState.dart';
import 'package:naavi/presentation/common/camera/CameraStateNotifier.dart';

class MockCameraModeManager extends Mock implements CameraModeManager {}

void main() {
  late CameraStateNotifier notifier;
  late MockCameraModeManager mockCameraManager;

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
    mockCameraManager = MockCameraModeManager();
    notifier = CameraStateNotifier(cameraModeManager: mockCameraManager);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('CameraStateNotifier - Initial State', () {
    test('should start with CameraInitial state', () {
      expect(notifier.state, isA<CameraInitial>());
    });

    test('should work without camera manager', () {
      final notifierWithoutManager = CameraStateNotifier();
      expect(notifierWithoutManager.state, isA<CameraInitial>());
      notifierWithoutManager.dispose();
    });
  });

  group('CameraStateNotifier - Enable First Person Mode', () {
    test('should enable first person mode successfully', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});

      // Act
      await notifier.enableFirstPersonMode(position);

      // Assert
      expect(notifier.state, isA<CameraFirstPersonMode>());
      expect(notifier.state.isFirstPersonMode, isTrue);
      expect(notifier.state.currentPosition, equals(position));
      verify(() => mockCameraManager.enableFirstPersonMode(position)).called(1);
    });

    test('should handle error and fallback to normal mode', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenThrow(Exception('Camera error'));

      // Act
      await notifier.enableFirstPersonMode(position);

      // Assert
      expect(notifier.state, isA<CameraNormalMode>());
      expect(notifier.state.currentPosition, equals(position));
    });

    test('should do nothing if camera manager is null', () async {
      // Arrange
      final notifierWithoutManager = CameraStateNotifier();
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
      await notifierWithoutManager.enableFirstPersonMode(position);

      // Assert
      expect(notifierWithoutManager.state, isA<CameraInitial>());
      notifierWithoutManager.dispose();
    });
  });

  group('CameraStateNotifier - Disable First Person Mode', () {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraManager.disableFirstPersonMode(),
      ).thenAnswer((_) async {});

      await notifier.enableFirstPersonMode(position);

      // Act
      await notifier.disableFirstPersonMode();

      // Assert
      expect(notifier.state, isA<CameraNormalMode>());
      expect(notifier.state.currentPosition, equals(position));
      verify(() => mockCameraManager.disableFirstPersonMode()).called(1);
    });

    test('should handle error silently', () async {
      // Arrange
      when(
        () => mockCameraManager.disableFirstPersonMode(),
      ).thenThrow(Exception('Error'));

      // Act
      await notifier.disableFirstPersonMode();

      // Assert - no exception should be thrown
      expect(notifier.state, isA<CameraState>());
    });

    test('should do nothing if camera manager is null', () async {
      // Arrange
      final notifierWithoutManager = CameraStateNotifier();

      // Act
      await notifierWithoutManager.disableFirstPersonMode();

      // Assert
      expect(notifierWithoutManager.state, isA<CameraInitial>());
      notifierWithoutManager.dispose();
    });
  });

  group('CameraStateNotifier - Set User Exploring', () {
    test('should set user exploring to true', () {
      // Act
      notifier.setUserExploring(true);

      // Assert
      expect(notifier.state, isA<CameraUserExploring>());
      expect(notifier.state.isUserExploring, isTrue);
    });

    test('should set user exploring to false in normal mode', () {
      // Arrange
      notifier.setUserExploring(true);

      // Act
      notifier.setUserExploring(false);

      // Assert
      expect(notifier.state, isA<CameraNormalMode>());
      expect(notifier.state.isUserExploring, isFalse);
    });

    test(
      'should return to first person mode when stopping exploration',
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

        when(
          () => mockCameraManager.enableFirstPersonMode(any()),
        ).thenAnswer((_) async {});

        await notifier.enableFirstPersonMode(position);
        notifier.setUserExploring(true);

        // Act
        notifier.setUserExploring(false);

        // Assert
        expect(notifier.state, isA<CameraFirstPersonMode>());
        expect(notifier.state.isUserExploring, isFalse);
      },
    );

    test('should preserve first person mode flag when exploring', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});

      await notifier.enableFirstPersonMode(position);

      // Act
      notifier.setUserExploring(true);

      // Assert
      expect(notifier.state.isFirstPersonMode, isTrue);
      expect(notifier.state.isUserExploring, isTrue);
    });
  });

  group('CameraStateNotifier - Update Position', () {
    test('should update position in first person mode', () async {
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
        latitude: 48.8600,
        longitude: 2.3600,
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});

      await notifier.enableFirstPersonMode(position1);

      // Act
      notifier.updatePosition(position2);

      // Assert
      expect(notifier.state, isA<CameraFirstPersonMode>());
      expect(notifier.state.currentPosition, equals(position2));
    });

    test('should update position in user exploring mode', () {
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

      notifier.setUserExploring(true);

      // Act
      notifier.updatePosition(position);

      // Assert
      expect(notifier.state, isA<CameraUserExploring>());
      expect(notifier.state.currentPosition, equals(position));
    });

    test('should update position in initial state', () {
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
      notifier.updatePosition(position);

      // Assert - stays in initial state (switch default case)
      expect(notifier.state, isA<CameraInitial>());
    });

    test('should preserve state type when updating position', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});

      await notifier.enableFirstPersonMode(position);
      final stateBeforeUpdate = notifier.state;

      // Act
      notifier.updatePosition(position);

      // Assert
      expect(notifier.state.runtimeType, equals(stateBeforeUpdate.runtimeType));
    });
  });

  group('CameraStateNotifier - Recenter', () {
    test('should recenter when in first person mode with position', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});

      await notifier.enableFirstPersonMode(position);
      notifier.setUserExploring(true);

      // Act
      await notifier.recenter();

      // Assert
      expect(notifier.state.isUserExploring, isFalse);
      verify(() => mockCameraManager.enableFirstPersonMode(position)).called(2);
    });

    test('should not recenter if not in first person mode', () async {
      // Act
      await notifier.recenter();

      // Assert
      verifyNever(() => mockCameraManager.enableFirstPersonMode(any()));
    });

    test('should not recenter if no current position', () async {
      // Arrange
      notifier.setUserExploring(true);

      // Act
      await notifier.recenter();

      // Assert
      verifyNever(() => mockCameraManager.enableFirstPersonMode(any()));
    });
  });

  group('CameraStateNotifier - State Transitions', () {
    test('should transition from initial to first person', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});

      // Act
      expect(notifier.state, isA<CameraInitial>());
      await notifier.enableFirstPersonMode(position);

      // Assert
      expect(notifier.state, isA<CameraFirstPersonMode>());
    });

    test('should transition from first person to normal', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraManager.disableFirstPersonMode(),
      ).thenAnswer((_) async {});

      await notifier.enableFirstPersonMode(position);

      // Act
      await notifier.disableFirstPersonMode();

      // Assert
      expect(notifier.state, isA<CameraNormalMode>());
    });

    test('should handle complex state transitions', () async {
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
        () => mockCameraManager.enableFirstPersonMode(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraManager.disableFirstPersonMode(),
      ).thenAnswer((_) async {});

      // Act & Assert
      expect(notifier.state, isA<CameraInitial>());

      await notifier.enableFirstPersonMode(position);
      expect(notifier.state, isA<CameraFirstPersonMode>());

      notifier.setUserExploring(true);
      expect(notifier.state, isA<CameraUserExploring>());

      notifier.setUserExploring(false);
      expect(notifier.state, isA<CameraFirstPersonMode>());

      await notifier.disableFirstPersonMode();
      expect(notifier.state, isA<CameraNormalMode>());
    });
  });
}
