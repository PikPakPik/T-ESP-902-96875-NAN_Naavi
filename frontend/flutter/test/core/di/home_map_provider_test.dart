import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/core/di/HomeMapProvider.dart';
import 'package:naavi/core/services/tracking/tracking_location_service.dart';
import 'package:naavi/core/services/tracking/location_service.dart';
import 'package:naavi/core/services/tracking/location_state_notifier.dart';
import 'package:naavi/core/models/location_state.dart';

void main() {
  group('HomeMapProvider', () {
    group('trackingLocationProvider', () {
      test('should provide a TrackingLocationService instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(trackingLocationProvider);
        expect(service, isA<TrackingLocationService>());
      });

      test('should provide same instance on multiple reads (singleton)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service1 = container.read(trackingLocationProvider);
        final service2 = container.read(trackingLocationProvider);
        expect(identical(service1, service2), isTrue);
      });
    });

    group('locationStateProvider', () {
      test('should provide a LocationStateNotifier instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(locationStateProvider.notifier);
        expect(notifier, isA<LocationStateNotifier>());
      });

      test('should initialize with LocationState', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = container.read(locationStateProvider);
        expect(state, isA<LocationState>());
      });

      test('should provide same notifier on multiple reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier1 = container.read(locationStateProvider.notifier);
        final notifier2 = container.read(locationStateProvider.notifier);
        expect(identical(notifier1, notifier2), isTrue);
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer();
        final notifier = container.read(locationStateProvider.notifier);
        expect(notifier.mounted, isTrue);

        container.dispose();
        expect(notifier.mounted, isFalse);
      });
    });

    // ignore: deprecated_member_use_from_same_package
    group('locationServiceProvider (deprecated)', () {
      test('should provide a LocationService instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // ignore: deprecated_member_use_from_same_package
        final service = container.read(locationServiceProvider);
        expect(service, isA<LocationService>());
      });

      test('should provide same instance on multiple reads (singleton)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // ignore: deprecated_member_use_from_same_package
        final service1 = container.read(locationServiceProvider);
        // ignore: deprecated_member_use_from_same_package
        final service2 = container.read(locationServiceProvider);
        expect(identical(service1, service2), isTrue);
      });
    });
  });
}
