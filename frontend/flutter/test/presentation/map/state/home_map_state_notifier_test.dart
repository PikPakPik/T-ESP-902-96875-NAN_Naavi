import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/map/state/HomeMapState.dart';
import 'package:naavi/presentation/map/state/HomeMapStateNotifier.dart';

void main() {
  group('HomeMapStateNotifier', () {
    late HomeMapStateNotifier notifier;

    setUp(() {
      notifier = HomeMapStateNotifier();
    });

    test('initial state should be explore', () {
      expect(notifier.state, HomeMapState.explore);
    });

    group('updateState', () {
      test('should update state to explore', () {
        notifier.updateState(HomeMapState.improvise);
        expect(notifier.state, HomeMapState.improvise);

        notifier.updateState(HomeMapState.explore);
        expect(notifier.state, HomeMapState.explore);
      });

      test('should update state to organise', () {
        notifier.updateState(HomeMapState.organise);
        expect(notifier.state, HomeMapState.organise);
      });

      test('should update state to improvise', () {
        notifier.updateState(HomeMapState.improvise);
        expect(notifier.state, HomeMapState.improvise);
      });

      test('should update state to resume', () {
        notifier.updateState(HomeMapState.resume);
        expect(notifier.state, HomeMapState.resume);
      });

      test('should update state to trackingExploration', () {
        notifier.updateState(HomeMapState.trackingExploration);
        expect(notifier.state, HomeMapState.trackingExploration);
      });
    });

    group('State Transitions', () {
      test('should transition from explore to organise', () {
        expect(notifier.state, HomeMapState.explore);

        notifier.updateState(HomeMapState.organise);
        expect(notifier.state, HomeMapState.organise);
      });

      test('should transition from organise to improvise', () {
        notifier.updateState(HomeMapState.organise);
        expect(notifier.state, HomeMapState.organise);

        notifier.updateState(HomeMapState.improvise);
        expect(notifier.state, HomeMapState.improvise);
      });

      test('should transition from improvise to explore', () {
        notifier.updateState(HomeMapState.improvise);
        expect(notifier.state, HomeMapState.improvise);

        notifier.updateState(HomeMapState.explore);
        expect(notifier.state, HomeMapState.explore);
      });

      test('should transition from explore to resume', () {
        expect(notifier.state, HomeMapState.explore);

        notifier.updateState(HomeMapState.resume);
        expect(notifier.state, HomeMapState.resume);
      });

      test('should transition from resume to trackingExploration', () {
        notifier.updateState(HomeMapState.resume);
        expect(notifier.state, HomeMapState.resume);

        notifier.updateState(HomeMapState.trackingExploration);
        expect(notifier.state, HomeMapState.trackingExploration);
      });

      test('should handle multiple consecutive state changes', () async {
        final states = <HomeMapState>[];
        final subscription = notifier.stream.listen((state) => states.add(state));

        notifier.updateState(HomeMapState.organise);
        await Future.delayed(Duration.zero);
        notifier.updateState(HomeMapState.improvise);
        await Future.delayed(Duration.zero);
        notifier.updateState(HomeMapState.resume);
        await Future.delayed(Duration.zero);
        notifier.updateState(HomeMapState.explore);
        await Future.delayed(Duration.zero);

        expect(states, [
          HomeMapState.organise,
          HomeMapState.improvise,
          HomeMapState.resume,
          HomeMapState.explore,
        ]);

        await subscription.cancel();
      });

      test('should maintain current state when updated to same state', () {
        notifier.updateState(HomeMapState.explore);
        expect(notifier.state, HomeMapState.explore);

        notifier.updateState(HomeMapState.explore);
        expect(notifier.state, HomeMapState.explore);
      });
    });

    group('State Listening', () {
      test('should emit state changes through stream', () async {
        final states = <HomeMapState>[];
        final subscription = notifier.stream.listen((state) => states.add(state));

        notifier.updateState(HomeMapState.organise);
        await Future.delayed(Duration.zero);

        notifier.updateState(HomeMapState.improvise);
        await Future.delayed(Duration.zero);

        expect(states, [
          HomeMapState.organise,
          HomeMapState.improvise,
        ]);

        await subscription.cancel();
      });

      test('should allow multiple listeners', () async {
        final states1 = <HomeMapState>[];
        final states2 = <HomeMapState>[];

        final subscription1 = notifier.stream.listen((state) => states1.add(state));
        final subscription2 = notifier.stream.listen((state) => states2.add(state));

        notifier.updateState(HomeMapState.organise);
        await Future.delayed(Duration.zero);

        expect(states1, [HomeMapState.organise]);
        expect(states2, [HomeMapState.organise]);

        await subscription1.cancel();
        await subscription2.cancel();
      });
    });

    group('All State Values', () {
      test('should support all enum values', () {
        final allStates = [
          HomeMapState.explore,
          HomeMapState.organise,
          HomeMapState.improvise,
          HomeMapState.resume,
          HomeMapState.trackingExploration,
        ];

        for (final state in allStates) {
          notifier.updateState(state);
          expect(notifier.state, state);
        }
      });
    });
  });
}
