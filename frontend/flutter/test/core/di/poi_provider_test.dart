import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/core/di/PoiProvider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoiProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('poiRefreshProvider', () {
      test('should provide a PoiRefreshNotifier instance', () {
        final notifier = container.read(poiRefreshProvider.notifier);

        expect(notifier, isA<PoiRefreshNotifier>());
      });

      test('should initialize with state 0', () {
        final state = container.read(poiRefreshProvider);

        expect(state, 0);
      });

      test('should increment state when refresh is called', () {
        final notifier = container.read(poiRefreshProvider.notifier);

        expect(container.read(poiRefreshProvider), 0);

        notifier.refresh();

        expect(container.read(poiRefreshProvider), 1);
      });

      test('should increment state multiple times', () {
        final notifier = container.read(poiRefreshProvider.notifier);

        expect(container.read(poiRefreshProvider), 0);

        notifier.refresh();
        expect(container.read(poiRefreshProvider), 1);

        notifier.refresh();
        expect(container.read(poiRefreshProvider), 2);

        notifier.refresh();
        expect(container.read(poiRefreshProvider), 3);
      });

      test('should provide the same notifier instance on multiple reads', () {
        final notifier1 = container.read(poiRefreshProvider.notifier);
        final notifier2 = container.read(poiRefreshProvider.notifier);

        expect(notifier1, same(notifier2));
      });

      test('should notify listeners when state changes', () {
        var notificationCount = 0;
        container.listen(
          poiRefreshProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final notifier = container.read(poiRefreshProvider.notifier);
        notifier.refresh();

        expect(notificationCount, 1);

        notifier.refresh();
        expect(notificationCount, 2);
      });

      test('should handle rapid consecutive refresh calls', () {
        final notifier = container.read(poiRefreshProvider.notifier);

        for (int i = 0; i < 10; i++) {
          notifier.refresh();
        }

        expect(container.read(poiRefreshProvider), 10);
      });

      test('should maintain independent state in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final notifier1 = container1.read(poiRefreshProvider.notifier);
        final notifier2 = container2.read(poiRefreshProvider.notifier);

        notifier1.refresh();
        notifier1.refresh();

        notifier2.refresh();

        expect(container1.read(poiRefreshProvider), 2);
        expect(container2.read(poiRefreshProvider), 1);

        container1.dispose();
        container2.dispose();
      });

      test('should support provider override', () {
        final overriddenContainer = ProviderContainer(
          overrides: [
            poiRefreshProvider.overrideWith((ref) => PoiRefreshNotifier()),
          ],
        );

        final state = overriddenContainer.read(poiRefreshProvider);
        expect(state, 0);

        overriddenContainer.dispose();
      });

      test('should emit previous and next values correctly', () {
        int? previousValue;
        int? nextValue;

        container.listen(
          poiRefreshProvider,
          (previous, next) {
            previousValue = previous;
            nextValue = next;
          },
        );

        final notifier = container.read(poiRefreshProvider.notifier);
        notifier.refresh();

        expect(previousValue, 0);
        expect(nextValue, 1);

        notifier.refresh();

        expect(previousValue, 1);
        expect(nextValue, 2);
      });
    });

    group('PoiRefreshNotifier', () {
      test('should be a StateNotifier with int state', () {
        final notifier = PoiRefreshNotifier();

        expect(notifier, isA<StateNotifier<int>>());
        expect(notifier.state, 0);
      });

      test('should maintain state across multiple refresh calls', () {
        final notifier = PoiRefreshNotifier();

        expect(notifier.state, 0);

        notifier.refresh();
        expect(notifier.state, 1);

        notifier.refresh();
        expect(notifier.state, 2);
      });

      test('should work with large state values', () {
        final notifier = PoiRefreshNotifier();

        for (int i = 0; i < 1000; i++) {
          notifier.refresh();
        }

        expect(notifier.state, 1000);
      });
    });

    group('Integration scenarios', () {
      test('should support multiple listeners tracking POI changes', () {
        var listener1Count = 0;
        var listener2Count = 0;

        container.listen(
          poiRefreshProvider,
          (previous, next) {
            listener1Count++;
          },
        );

        container.listen(
          poiRefreshProvider,
          (previous, next) {
            listener2Count++;
          },
        );

        final notifier = container.read(poiRefreshProvider.notifier);
        notifier.refresh();

        expect(listener1Count, 1);
        expect(listener2Count, 1);
      });

      test('should synchronize POI updates between profile and map', () {
        // Simulate profile page listening to POI changes
        var profileRefreshCount = 0;
        container.listen(
          poiRefreshProvider,
          (previous, next) {
            profileRefreshCount++;
          },
        );

        // Simulate map page listening to POI changes
        var mapRefreshCount = 0;
        container.listen(
          poiRefreshProvider,
          (previous, next) {
            mapRefreshCount++;
          },
        );

        // Trigger a POI update (e.g., user adds a new POI)
        final notifier = container.read(poiRefreshProvider.notifier);
        notifier.refresh();

        // Both pages should be notified
        expect(profileRefreshCount, 1);
        expect(mapRefreshCount, 1);
      });

      test('should handle state persistence across provider reads', () {
        final notifier = container.read(poiRefreshProvider.notifier);

        notifier.refresh();
        notifier.refresh();

        // Reading from different locations should get the same state
        final state1 = container.read(poiRefreshProvider);
        final state2 = container.read(poiRefreshProvider);

        expect(state1, 2);
        expect(state2, 2);
        expect(state1, state2);
      });
    });
  });
}
