import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/common/compass/CompassState.dart';

void main() {
  group('CompassIdle', () {
    test('should initialize with null headings', () {
      const state = CompassIdle();

      expect(state.currentHeading, isNull);
      expect(state.previousHeading, isNull);
    });

    test('should be a CompassState', () {
      const state = CompassIdle();
      expect(state, isA<CompassState>());
    });
  });

  group('CompassActive', () {
    test('should initialize with provided headings', () {
      const state = CompassActive(currentHeading: 90.0, previousHeading: 85.0);

      expect(state.currentHeading, equals(90.0));
      expect(state.previousHeading, equals(85.0));
    });

    test('should initialize with null headings', () {
      const state = CompassActive(currentHeading: null, previousHeading: null);

      expect(state.currentHeading, isNull);
      expect(state.previousHeading, isNull);
    });

    test('should handle zero heading', () {
      const state = CompassActive(currentHeading: 0.0, previousHeading: 0.0);

      expect(state.currentHeading, equals(0.0));
      expect(state.previousHeading, equals(0.0));
    });

    test('should handle heading of 360 degrees', () {
      const state = CompassActive(
        currentHeading: 360.0,
        previousHeading: 359.0,
      );

      expect(state.currentHeading, equals(360.0));
      expect(state.previousHeading, equals(359.0));
    });

    test('should handle negative headings', () {
      const state = CompassActive(
        currentHeading: -45.0,
        previousHeading: -90.0,
      );

      expect(state.currentHeading, equals(-45.0));
      expect(state.previousHeading, equals(-90.0));
    });

    group('copyWith', () {
      test('should update currentHeading', () {
        const original = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = original.copyWith(currentHeading: 95.0);

        expect(updated.currentHeading, equals(95.0));
        expect(updated.previousHeading, equals(85.0));
      });

      test('should update previousHeading', () {
        const original = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = original.copyWith(previousHeading: 90.0);

        expect(updated.currentHeading, equals(90.0));
        expect(updated.previousHeading, equals(90.0));
      });

      test('should update both headings', () {
        const original = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = original.copyWith(
          currentHeading: 180.0,
          previousHeading: 170.0,
        );

        expect(updated.currentHeading, equals(180.0));
        expect(updated.previousHeading, equals(170.0));
      });

      test('should preserve values when copyWith called without params', () {
        const original = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = original.copyWith();

        expect(updated.currentHeading, equals(90.0));
        expect(updated.previousHeading, equals(85.0));
      });

      test('should preserve values when copyWith called with null params', () {
        const original = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        // copyWith with null keeps existing values (null means "don't change")
        final updated = original.copyWith(
          currentHeading: null,
          previousHeading: null,
        );

        expect(updated.currentHeading, equals(90.0));
        expect(updated.previousHeading, equals(85.0));
      });

      test('should create new instance not modify original', () {
        const original = CompassActive(
          currentHeading: 90.0,
          previousHeading: 85.0,
        );

        final updated = original.copyWith(currentHeading: 180.0);

        expect(original.currentHeading, equals(90.0));
        expect(updated.currentHeading, equals(180.0));
      });
    });
  });

  group('CompassState type checking', () {
    test('should distinguish between CompassIdle and CompassActive', () {
      const idle = CompassIdle();
      const active = CompassActive(currentHeading: 90.0, previousHeading: 85.0);

      expect(idle, isA<CompassIdle>());
      expect(active, isA<CompassActive>());
      expect(idle, isNot(isA<CompassActive>()));
      expect(active, isNot(isA<CompassIdle>()));
    });
  });

  group('Compass state transitions', () {
    test('should transition from idle to active', () {
      const idle = CompassIdle();
      const active = CompassActive(currentHeading: 0.0, previousHeading: null);

      expect(idle, isA<CompassIdle>());
      expect(active, isA<CompassActive>());
    });

    test('should simulate heading updates', () {
      const state1 = CompassActive(currentHeading: 90.0, previousHeading: null);

      final state2 = state1.copyWith(
        previousHeading: 90.0,
        currentHeading: 95.0,
      );

      final state3 = state2.copyWith(
        previousHeading: 95.0,
        currentHeading: 100.0,
      );

      expect(state1.currentHeading, equals(90.0));
      expect(state2.currentHeading, equals(95.0));
      expect(state2.previousHeading, equals(90.0));
      expect(state3.currentHeading, equals(100.0));
      expect(state3.previousHeading, equals(95.0));
    });
  });
}
