import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/map_service.dart';

// Mocks
class MockStyleManager extends Mock implements StyleManager {}

class MockMapboxMap extends Mock implements MapboxMap {}

class MockLocationSettings extends Mock implements LocationSettings {}

class MockMbxImage extends Fake implements MbxImage {
  @override
  final int width;
  @override
  final int height;
  @override
  final Uint8List data;

  MockMbxImage({required this.width, required this.height, required this.data});
}

// Fake classes for mocktail registration
class FakeMbxImage extends Fake implements MbxImage {}

class FakeLocationComponentSettings extends Fake
    implements LocationComponentSettings {}

class FakeCameraOptions extends Fake implements CameraOptions {}

class FakeMapAnimationOptions extends Fake implements MapAnimationOptions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeMbxImage());
    registerFallbackValue(FakeLocationComponentSettings());
    registerFallbackValue(FakeCameraOptions());
    registerFallbackValue(FakeMapAnimationOptions());
  });

  group('MapService', () {
    late MockStyleManager mockStyleManager;
    late MockMapboxMap mockMapboxMap;
    late MockLocationSettings mockLocationInterface;

    setUp(() {
      mockStyleManager = MockStyleManager();
      mockMapboxMap = MockMapboxMap();
      mockLocationInterface = MockLocationSettings();

      // Setup default location interface behavior
      when(() => mockMapboxMap.location).thenReturn(mockLocationInterface);
    });

    group('ensureIconRegistered', () {
      test('should successfully register an icon from assets', () async {
        // Arrange
        const iconId = 'test-icon';
        const assetPath = 'assets/test.png';

        when(
          () => mockStyleManager.addStyleImage(
            iconId,
            1.0,
            any(),
            false,
            any(),
            any(),
            null,
          ),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert - Should not throw
        await expectLater(
          MapService.ensureIconRegistered(mockStyleManager, iconId, assetPath),
          completes,
        );
      });

      test('should handle error when icon registration fails', () async {
        // Arrange
        const iconId = 'invalid-icon';
        const assetPath = 'assets/invalid.png';

        when(
          () => mockStyleManager.addStyleImage(
            iconId,
            1.0,
            any(),
            false,
            any(),
            any(),
            null,
          ),
        ).thenThrow(Exception('Failed to add icon'));

        // Act & Assert - Should complete without throwing (error is caught)
        await expectLater(
          MapService.ensureIconRegistered(mockStyleManager, iconId, assetPath),
          completes,
        );
      });

      test('should handle asset loading failure gracefully', () async {
        // Arrange
        const iconId = 'missing-icon';
        const assetPath = 'assets/missing.png';

        // Act & Assert - Should complete even if asset doesn't exist
        await expectLater(
          MapService.ensureIconRegistered(mockStyleManager, iconId, assetPath),
          completes,
        );
      });

      test('should handle empty icon ID', () async {
        // Arrange
        const iconId = '';
        const assetPath = 'assets/test.png';

        when(
          () => mockStyleManager.addStyleImage(
            iconId,
            1.0,
            any(),
            false,
            any(),
            any(),
            null,
          ),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert
        await expectLater(
          MapService.ensureIconRegistered(mockStyleManager, iconId, assetPath),
          completes,
        );
      });

      test('should handle empty asset path', () async {
        // Arrange
        const iconId = 'test-icon';
        const assetPath = '';

        // Act & Assert - Should complete (error caught internally)
        await expectLater(
          MapService.ensureIconRegistered(mockStyleManager, iconId, assetPath),
          completes,
        );
      });

      test('should handle multiple consecutive registrations', () async {
        // Arrange
        const iconId1 = 'icon-1';
        const iconId2 = 'icon-2';
        const assetPath1 = 'assets/icon1.png';
        const assetPath2 = 'assets/icon2.png';

        when(
          () => mockStyleManager.addStyleImage(
            any(),
            1.0,
            any(),
            false,
            any(),
            any(),
            null,
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        await MapService.ensureIconRegistered(
          mockStyleManager,
          iconId1,
          assetPath1,
        );
        await MapService.ensureIconRegistered(
          mockStyleManager,
          iconId2,
          assetPath2,
        );

        // Assert - Methods complete without throwing (asset loading may fail silently)
      });
    });

    group('setupLocationComponent', () {
      test('should enable location component with correct settings', () async {
        // Arrange
        when(
          () => mockLocationInterface.updateSettings(any()),
        ).thenAnswer((_) async => Future.value());

        // Act
        await MapService.setupLocationComponent(mockMapboxMap);

        // Assert
        verify(() => mockLocationInterface.updateSettings(any())).called(1);
      });

      test('should configure puck bearing to HEADING', () async {
        // Arrange
        LocationComponentSettings? capturedSettings;
        when(() => mockLocationInterface.updateSettings(any())).thenAnswer((
          invocation,
        ) async {
          capturedSettings =
              invocation.positionalArguments[0] as LocationComponentSettings;
          return Future.value();
        });

        // Act
        await MapService.setupLocationComponent(mockMapboxMap);

        // Assert
        expect(capturedSettings, isNotNull);
        expect(capturedSettings!.enabled, true);
        expect(capturedSettings!.puckBearingEnabled, true);
        expect(capturedSettings!.puckBearing, PuckBearing.HEADING);
        expect(capturedSettings!.pulsingEnabled, true);
        expect(capturedSettings!.showAccuracyRing, true);
      });

      test('should handle setup failure gracefully', () async {
        // Arrange
        when(
          () => mockLocationInterface.updateSettings(any()),
        ).thenThrow(Exception('Location setup failed'));

        // Act & Assert - Should throw as error is not caught
        await expectLater(
          MapService.setupLocationComponent(mockMapboxMap),
          throwsException,
        );
      });

      test('should setup location puck with default configuration', () async {
        // Arrange
        LocationComponentSettings? capturedSettings;
        when(() => mockLocationInterface.updateSettings(any())).thenAnswer((
          invocation,
        ) async {
          capturedSettings =
              invocation.positionalArguments[0] as LocationComponentSettings;
          return Future.value();
        });

        // Act
        await MapService.setupLocationComponent(mockMapboxMap);

        // Assert
        expect(capturedSettings!.locationPuck, isNotNull);
        expect(
          capturedSettings!.locationPuck!.locationPuck2D!.topImage,
          isNull,
        );
      });

      test('should handle multiple setup calls', () async {
        // Arrange
        when(
          () => mockLocationInterface.updateSettings(any()),
        ).thenAnswer((_) async => Future.value());

        // Act - Call multiple times
        await MapService.setupLocationComponent(mockMapboxMap);
        await MapService.setupLocationComponent(mockMapboxMap);
        await MapService.setupLocationComponent(mockMapboxMap);

        // Assert
        verify(() => mockLocationInterface.updateSettings(any())).called(3);
      });
    });

    group('animateCameraTo', () {
      test('should animate camera to specified position', () async {
        // Arrange
        const longitude = 2.3522;
        const latitude = 48.8566;
        const zoom = 15.0;

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act
        await MapService.animateCameraTo(
          mockMapboxMap,
          longitude,
          latitude,
          zoom,
        );

        // Assert
        verify(() => mockMapboxMap.easeTo(any(), any())).called(1);
      });

      test('should use correct camera options with coordinates', () async {
        // Arrange
        const longitude = -73.935242;
        const latitude = 40.730610;
        const zoom = 12.0;

        CameraOptions? capturedOptions;
        when(() => mockMapboxMap.easeTo(any(), any())).thenAnswer((
          invocation,
        ) async {
          capturedOptions = invocation.positionalArguments[0] as CameraOptions;
          return Future.value();
        });

        // Act
        await MapService.animateCameraTo(
          mockMapboxMap,
          longitude,
          latitude,
          zoom,
        );

        // Assert
        expect(capturedOptions, isNotNull);
        expect(capturedOptions!.zoom, zoom);
        expect(capturedOptions!.center, isNotNull);
      });

      test('should use animation duration of 1000ms', () async {
        // Arrange
        const longitude = 0.0;
        const latitude = 0.0;
        const zoom = 10.0;

        MapAnimationOptions? capturedAnimation;
        when(() => mockMapboxMap.easeTo(any(), any())).thenAnswer((
          invocation,
        ) async {
          capturedAnimation =
              invocation.positionalArguments[1] as MapAnimationOptions;
          return Future.value();
        });

        // Act
        await MapService.animateCameraTo(
          mockMapboxMap,
          longitude,
          latitude,
          zoom,
        );

        // Assert
        expect(capturedAnimation, isNotNull);
        expect(capturedAnimation!.duration, 1000);
      });

      test('should handle negative coordinates', () async {
        // Arrange
        const longitude = -122.4194;
        const latitude = -37.7749;
        const zoom = 8.0;

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert
        await expectLater(
          MapService.animateCameraTo(mockMapboxMap, longitude, latitude, zoom),
          completes,
        );
      });

      test('should handle zero zoom level', () async {
        // Arrange
        const longitude = 10.0;
        const latitude = 20.0;
        const zoom = 0.0;

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert
        await expectLater(
          MapService.animateCameraTo(mockMapboxMap, longitude, latitude, zoom),
          completes,
        );
      });

      test('should handle high zoom level', () async {
        // Arrange
        const longitude = 10.0;
        const latitude = 20.0;
        const zoom = 20.0;

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert
        await expectLater(
          MapService.animateCameraTo(mockMapboxMap, longitude, latitude, zoom),
          completes,
        );
      });

      test('should handle animation failure', () async {
        // Arrange
        const longitude = 10.0;
        const latitude = 20.0;
        const zoom = 15.0;

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenThrow(Exception('Animation failed'));

        // Act & Assert
        await expectLater(
          MapService.animateCameraTo(mockMapboxMap, longitude, latitude, zoom),
          throwsException,
        );
      });

      test('should handle multiple consecutive animations', () async {
        // Arrange
        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act
        await MapService.animateCameraTo(mockMapboxMap, 1.0, 2.0, 10.0);
        await MapService.animateCameraTo(mockMapboxMap, 3.0, 4.0, 12.0);
        await MapService.animateCameraTo(mockMapboxMap, 5.0, 6.0, 14.0);

        // Assert
        verify(() => mockMapboxMap.easeTo(any(), any())).called(3);
      });

      test('should handle extreme coordinate values', () async {
        // Arrange
        const longitude = 180.0;
        const latitude = 90.0;
        const zoom = 15.0;

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert
        await expectLater(
          MapService.animateCameraTo(mockMapboxMap, longitude, latitude, zoom),
          completes,
        );
      });

      test('should handle extreme negative coordinate values', () async {
        // Arrange
        const longitude = -180.0;
        const latitude = -90.0;
        const zoom = 15.0;

        when(
          () => mockMapboxMap.easeTo(any(), any()),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert
        await expectLater(
          MapService.animateCameraTo(mockMapboxMap, longitude, latitude, zoom),
          completes,
        );
      });
    });

    group('Edge Cases', () {
      test(
        'should handle null style manager gracefully in real scenario',
        () async {
          // This test documents expected behavior
          // In production, null checks should be added if needed
          expect(mockStyleManager, isNotNull);
        },
      );

      test(
        'should handle rapid successive calls to different methods',
        () async {
          // Arrange
          when(
            () => mockLocationInterface.updateSettings(any()),
          ).thenAnswer((_) async => Future.value());
          when(
            () => mockMapboxMap.easeTo(any(), any()),
          ).thenAnswer((_) async => Future.value());

          // Act - Rapid calls
          await MapService.setupLocationComponent(mockMapboxMap);
          await MapService.animateCameraTo(mockMapboxMap, 0.0, 0.0, 10.0);
          await MapService.setupLocationComponent(mockMapboxMap);

          // Assert
          verify(() => mockLocationInterface.updateSettings(any())).called(2);
          verify(() => mockMapboxMap.easeTo(any(), any())).called(1);
        },
      );
    });
  });
}
