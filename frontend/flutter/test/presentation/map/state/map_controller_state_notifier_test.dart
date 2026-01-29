import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/presentation/map/state/MapControllerState.dart';
import 'package:naavi/presentation/map/state/MapControllerStateNotifier.dart';

// Mocks
class MockMapboxMap extends Mock implements MapboxMap {}

void main() {
  group('MapControllerStateNotifier', () {
    late MapControllerStateNotifier notifier;
    late MockMapboxMap mockMapboxMap;

    setUp(() {
      notifier = MapControllerStateNotifier();
      mockMapboxMap = MockMapboxMap();
    });

    tearDown(() {
      if (notifier.mounted) {
        notifier.dispose();
      }
    });

    test('initial state should be MapControllerLoading', () {
      expect(notifier.state, isA<MapControllerLoading>());
    });

    group('onMapCreated', () {
      test(
        'should transition to MapControllerReady on successful map creation',
        () {
          notifier.onMapCreated(mockMapboxMap);

          expect(notifier.state, isA<MapControllerReady>());
          final readyState = notifier.state as MapControllerReady;
          expect(readyState.controller, mockMapboxMap);
          expect(readyState.isMapReady, true);
        },
      );

      test('should emit state change through stream', () async {
        final states = <MapControllerState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        notifier.onMapCreated(mockMapboxMap);
        await Future.delayed(Duration.zero);

        expect(states.length, 1);
        expect(states[0], isA<MapControllerReady>());

        await subscription.cancel();
      });

      test('should set controller property when map is created', () {
        notifier.onMapCreated(mockMapboxMap);

        expect(notifier.controller, mockMapboxMap);
        expect(notifier.isReady, true);
      });
    });

    group('onUserInteractionStart', () {
      test('should transition from Ready to Interacting', () {
        notifier.onMapCreated(mockMapboxMap);
        expect(notifier.state, isA<MapControllerReady>());

        notifier.onUserInteractionStart();

        expect(notifier.state, isA<MapControllerInteracting>());
        final interactingState = notifier.state as MapControllerInteracting;
        expect(interactingState.controller, mockMapboxMap);
        expect(interactingState.isUserInteracting, true);
      });

      test('should not affect state if not in Ready state', () {
        expect(notifier.state, isA<MapControllerLoading>());

        notifier.onUserInteractionStart();

        expect(notifier.state, isA<MapControllerLoading>());
      });

      test('should update isUserInteracting getter', () {
        notifier.onMapCreated(mockMapboxMap);
        expect(notifier.isUserInteracting, false);

        notifier.onUserInteractionStart();
        expect(notifier.isUserInteracting, true);
      });

      test('should maintain controller reference during interaction', () {
        notifier.onMapCreated(mockMapboxMap);
        final controllerBeforeInteraction = notifier.controller;

        notifier.onUserInteractionStart();
        final controllerDuringInteraction = notifier.controller;

        expect(controllerBeforeInteraction, mockMapboxMap);
        expect(controllerDuringInteraction, mockMapboxMap);
        expect(controllerBeforeInteraction, controllerDuringInteraction);
      });
    });

    group('onUserInteractionEnd', () {
      test('should transition from Interacting to Ready after 500ms', () async {
        notifier.onMapCreated(mockMapboxMap);
        notifier.onUserInteractionStart();
        expect(notifier.state, isA<MapControllerInteracting>());

        notifier.onUserInteractionEnd();

        // Should still be interacting immediately
        expect(notifier.state, isA<MapControllerInteracting>());

        // Wait for the 500ms timer
        await Future.delayed(const Duration(milliseconds: 600));

        expect(notifier.state, isA<MapControllerReady>());
        final readyState = notifier.state as MapControllerReady;
        expect(readyState.controller, mockMapboxMap);
        expect(readyState.isMapReady, true);
      });

      test('should cancel previous timer when called multiple times', () async {
        notifier.onMapCreated(mockMapboxMap);
        notifier.onUserInteractionStart();
        expect(notifier.state, isA<MapControllerInteracting>());

        notifier.onUserInteractionEnd();
        await Future.delayed(const Duration(milliseconds: 200));

        // Call again before first timer completes
        notifier.onUserInteractionEnd();
        await Future.delayed(const Duration(milliseconds: 200));

        // Should still be interacting (timer was reset)
        expect(notifier.state, isA<MapControllerInteracting>());

        // Wait for the second timer to complete
        await Future.delayed(const Duration(milliseconds: 400));

        expect(notifier.state, isA<MapControllerReady>());
      });

      test('should not affect state if not in Interacting state', () async {
        notifier.onMapCreated(mockMapboxMap);
        expect(notifier.state, isA<MapControllerReady>());

        notifier.onUserInteractionEnd();
        await Future.delayed(const Duration(milliseconds: 600));

        // Should remain Ready
        expect(notifier.state, isA<MapControllerReady>());
      });

      test(
        'should update isUserInteracting getter after timer completes',
        () async {
          notifier.onMapCreated(mockMapboxMap);
          notifier.onUserInteractionStart();
          expect(notifier.isUserInteracting, true);

          notifier.onUserInteractionEnd();
          expect(notifier.isUserInteracting, true); // Still true immediately

          await Future.delayed(const Duration(milliseconds: 600));
          expect(notifier.isUserInteracting, false);
        },
      );
    });

    group('dispose', () {
      test('should cancel interaction timer on dispose', () async {
        notifier.onMapCreated(mockMapboxMap);
        notifier.onUserInteractionStart();
        notifier.onUserInteractionEnd();

        // Vérifier l'état avant dispose
        expect(notifier.state, isA<MapControllerInteracting>());

        // Dispose before timer completes
        expect(() => notifier.dispose(), returnsNormally);

        // Wait for what would have been the timer duration
        await Future.delayed(const Duration(milliseconds: 600));

        // Le notifier est disposé, ne pas accéder au state après dispose
        // Le test vérifie simplement que le dispose ne lance pas d'exception
      });

      test('should handle dispose when no timer is active', () {
        notifier.onMapCreated(mockMapboxMap);

        expect(() => notifier.dispose(), returnsNormally);
      });

      test('should handle dispose when in loading state', () {
        expect(notifier.state, isA<MapControllerLoading>());

        expect(() => notifier.dispose(), returnsNormally);
      });
    });

    group('controller getter', () {
      test('should return controller when in Ready state', () {
        notifier.onMapCreated(mockMapboxMap);

        expect(notifier.controller, mockMapboxMap);
      });

      test('should return controller when in Interacting state', () {
        notifier.onMapCreated(mockMapboxMap);
        notifier.onUserInteractionStart();

        expect(notifier.controller, mockMapboxMap);
      });

      test('should return null when in Loading state', () {
        expect(notifier.controller, null);
      });

      test('should return null when in Error state', () {
        // Force error state by mocking onMapCreated to throw
        notifier = MapControllerStateNotifier();
        notifier.state = const MapControllerError('Test error');

        expect(notifier.controller, null);
      });
    });

    group('isReady getter', () {
      test('should return false when in Loading state', () {
        expect(notifier.isReady, false);
      });

      test('should return true when in Ready state', () {
        notifier.onMapCreated(mockMapboxMap);

        expect(notifier.isReady, true);
      });

      test('should return true when in Interacting state', () {
        notifier.onMapCreated(mockMapboxMap);
        notifier.onUserInteractionStart();

        expect(notifier.isReady, true);
      });

      test('should return false when in Error state', () {
        notifier.state = const MapControllerError('Test error');

        expect(notifier.isReady, false);
      });
    });

    group('isUserInteracting getter', () {
      test('should return false when in Loading state', () {
        expect(notifier.isUserInteracting, false);
      });

      test('should return false when in Ready state', () {
        notifier.onMapCreated(mockMapboxMap);

        expect(notifier.isUserInteracting, false);
      });

      test('should return true when in Interacting state', () {
        notifier.onMapCreated(mockMapboxMap);
        notifier.onUserInteractionStart();

        expect(notifier.isUserInteracting, true);
      });

      test('should return false when in Error state', () {
        notifier.state = const MapControllerError('Test error');

        expect(notifier.isUserInteracting, false);
      });
    });

    group('State Transitions', () {
      test('should transition through all expected states', () async {
        final states = <MapControllerState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        // Loading -> Ready
        notifier.onMapCreated(mockMapboxMap);
        await Future.delayed(Duration.zero);

        // Ready -> Interacting
        notifier.onUserInteractionStart();
        await Future.delayed(Duration.zero);

        // Interacting -> Ready (after timer)
        notifier.onUserInteractionEnd();
        await Future.delayed(const Duration(milliseconds: 600));

        expect(states.length, 3);
        expect(states[0], isA<MapControllerReady>());
        expect(states[1], isA<MapControllerInteracting>());
        expect(states[2], isA<MapControllerReady>());

        await subscription.cancel();
      });

      test('should handle multiple interaction cycles', () async {
        notifier.onMapCreated(mockMapboxMap);

        // First interaction
        notifier.onUserInteractionStart();
        expect(notifier.state, isA<MapControllerInteracting>());

        notifier.onUserInteractionEnd();
        await Future.delayed(const Duration(milliseconds: 600));
        expect(notifier.state, isA<MapControllerReady>());

        // Second interaction
        notifier.onUserInteractionStart();
        expect(notifier.state, isA<MapControllerInteracting>());

        notifier.onUserInteractionEnd();
        await Future.delayed(const Duration(milliseconds: 600));
        expect(notifier.state, isA<MapControllerReady>());
      });

      test(
        'should maintain state consistency during rapid interactions',
        () async {
          notifier.onMapCreated(mockMapboxMap);

          // Rapid start/end cycles
          for (var i = 0; i < 5; i++) {
            notifier.onUserInteractionStart();
            expect(notifier.state, isA<MapControllerInteracting>());

            notifier.onUserInteractionEnd();
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // Wait for final timer
          await Future.delayed(const Duration(milliseconds: 500));
          expect(notifier.state, isA<MapControllerReady>());
        },
      );
    });

    group('Error Handling', () {
      test('should handle MapControllerError state', () {
        final errorState = MapControllerError('Test error message');
        notifier.state = errorState;

        expect(notifier.state, isA<MapControllerError>());
        expect(
          (notifier.state as MapControllerError).message,
          'Test error message',
        );
        expect(notifier.controller, null);
        expect(notifier.isReady, false);
        expect(notifier.isUserInteracting, false);
      });

      test(
        'should not transition from Error to Interacting on user interaction',
        () {
          notifier.state = const MapControllerError('Test error');

          notifier.onUserInteractionStart();

          expect(notifier.state, isA<MapControllerError>());
        },
      );
    });

    group('MapControllerReady.copyWith', () {
      test('should create new instance with updated controller', () {
        final mockMapboxMap2 = MockMapboxMap();
        final state = MapControllerReady(controller: mockMapboxMap);
        final newState = state.copyWith(controller: mockMapboxMap2);

        expect(newState.controller, mockMapboxMap2);
        expect(newState.isMapReady, state.isMapReady);
      });

      test('should create new instance with updated isMapReady', () {
        final state = MapControllerReady(
          controller: mockMapboxMap,
          isMapReady: true,
        );
        final newState = state.copyWith(isMapReady: false);

        expect(newState.controller, state.controller);
        expect(newState.isMapReady, false);
      });

      test('should preserve original values when null is passed', () {
        final state = MapControllerReady(
          controller: mockMapboxMap,
          isMapReady: true,
        );
        final newState = state.copyWith();

        expect(newState.controller, state.controller);
        expect(newState.isMapReady, state.isMapReady);
      });
    });
  });
}
