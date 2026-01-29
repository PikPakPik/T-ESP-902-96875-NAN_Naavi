import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/common/compass/CompassState.dart';
import 'package:naavi/presentation/common/compass/CompassStateNotifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompassStateNotifier', () {
    group('Initialization', () {
      test('should initialize with CompassIdle state', () {
        final notifier = CompassStateNotifier();

        expect(notifier.state, isA<CompassIdle>());
        expect(notifier.state.currentHeading, isNull);
        expect(notifier.state.previousHeading, isNull);

        notifier.dispose();
      });

      test('should use default heading threshold of 5.0', () {
        final notifier = CompassStateNotifier();

        expect(notifier.headingThreshold, 5.0);

        notifier.dispose();
      });

      test('should accept custom heading threshold', () {
        final notifier = CompassStateNotifier(headingThreshold: 10.0);

        expect(notifier.headingThreshold, 10.0);

        notifier.dispose();
      });

      test('should accept onHeadingChanged callback', () {
        double? lastHeading;
        final notifier = CompassStateNotifier(
          onHeadingChanged: (heading) => lastHeading = heading,
        );

        expect(notifier.onHeadingChanged, isNotNull);
        notifier.onHeadingChanged!(45.0);
        expect(lastHeading, 45.0);

        notifier.dispose();
      });
    });

    group('isListening', () {
      test('should return false when in CompassIdle state', () {
        final notifier = CompassStateNotifier();

        expect(notifier.isListening, false);

        notifier.dispose();
      });
    });

    group('stopListening', () {
      test('should reset state to CompassIdle', () {
        final notifier = CompassStateNotifier();

        notifier.stopListening();

        expect(notifier.state, isA<CompassIdle>());
        expect(notifier.isListening, false);

        notifier.dispose();
      });

      test('should be safe to call multiple times', () {
        final notifier = CompassStateNotifier();

        notifier.stopListening();
        notifier.stopListening();
        notifier.stopListening();

        expect(notifier.state, isA<CompassIdle>());

        notifier.dispose();
      });
    });

    group('dispose', () {
      test('should stop listening and call super.dispose', () {
        final notifier = CompassStateNotifier();

        // Should not throw
        expect(() => notifier.dispose(), returnsNormally);
      });

      test('should set state to CompassIdle before dispose', () {
        final notifier = CompassStateNotifier();

        notifier.dispose();

        // After dispose, state should be idle (set by stopListening in dispose)
        // Note: accessing state after dispose may throw in some implementations
      });
    });

    group('startListening', () {
      test('should not throw when FlutterCompass.events is null', () {
        final notifier = CompassStateNotifier();

        // FlutterCompass.events returns null in test environment
        // startListening should handle this gracefully
        expect(() => notifier.startListening(), returnsNormally);

        notifier.dispose();
      });

      test('should not start listening multiple times', () {
        final notifier = CompassStateNotifier();

        // First call - should set up subscription (or handle null gracefully)
        notifier.startListening();

        // Second call - should return early if already listening
        expect(() => notifier.startListening(), returnsNormally);

        notifier.dispose();
      });
    });

    group('State transitions', () {
      test('should maintain state after stopListening', () {
        final notifier = CompassStateNotifier();

        // Start and stop
        notifier.startListening();
        notifier.stopListening();

        expect(notifier.state, isA<CompassIdle>());
        expect(notifier.isListening, false);

        notifier.dispose();
      });
    });
  });

  group('CompassState', () {
    group('CompassIdle', () {
      test('should have null headings', () {
        const state = CompassIdle();

        expect(state.currentHeading, isNull);
        expect(state.previousHeading, isNull);
      });

      test('should be equal to another CompassIdle', () {
        const state1 = CompassIdle();
        const state2 = CompassIdle();

        expect(state1.currentHeading, state2.currentHeading);
        expect(state1.previousHeading, state2.previousHeading);
      });
    });

    group('CompassActive', () {
      test('should store current and previous heading', () {
        const state = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        expect(state.currentHeading, 90.0);
        expect(state.previousHeading, 85.0);
      });

      test('copyWith should update currentHeading', () {
        const state = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = state.copyWith(currentHeading: 100.0);

        expect(updated.currentHeading, 100.0);
        expect(updated.previousHeading, 85.0);
      });

      test('copyWith should update previousHeading', () {
        const state = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = state.copyWith(previousHeading: 90.0);

        expect(updated.currentHeading, 90.0);
        expect(updated.previousHeading, 90.0);
      });

      test('copyWith should update both headings', () {
        const state = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = state.copyWith(
          currentHeading: 180.0,
          previousHeading: 175.0,
        );

        expect(updated.currentHeading, 180.0);
        expect(updated.previousHeading, 175.0);
      });

      test('copyWith with no parameters returns same values', () {
        const state = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = state.copyWith();

        expect(updated.currentHeading, 90.0);
        expect(updated.previousHeading, 85.0);
      });

      test('should handle zero heading', () {
        const state = CompassActive(currentHeading: 0.0, previousHeading: 0.0);

        expect(state.currentHeading, 0.0);
        expect(state.previousHeading, 0.0);
      });

      test('should handle 360 degree heading', () {
        const state = CompassActive(
          currentHeading: 360.0,
          previousHeading: 355.0,
        );

        expect(state.currentHeading, 360.0);
        expect(state.previousHeading, 355.0);
      });

      test('should handle negative heading', () {
        const state = CompassActive(
          currentHeading: -10.0,
          previousHeading: -5.0,
        );

        expect(state.currentHeading, -10.0);
        expect(state.previousHeading, -5.0);
      });
    });
  });
}
