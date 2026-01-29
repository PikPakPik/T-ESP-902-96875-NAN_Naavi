import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/splash/state/SplashScreenState.dart';

void main() {
  group('SplashScreenState', () {
    test(
      'SplashScreenStateLoading should be instance of SplashScreenState',
      () {
        const state = SplashScreenStateLoading();
        expect(state, isA<SplashScreenState>());
      },
    );

    test(
      'SplashScreenStateHikeFetched should be instance of SplashScreenState',
      () {
        const state = SplashScreenStateHikeFetched();
        expect(state, isA<SplashScreenState>());
      },
    );

    test(
      'SplashScreenStateHikeNotFetched should be instance of SplashScreenState',
      () {
        const state = SplashScreenStateHikeNotFetched();
        expect(state, isA<SplashScreenState>());
      },
    );

    test('SplashScreenStateError should be instance of SplashScreenState', () {
      const state = SplashScreenStateError();
      expect(state, isA<SplashScreenState>());
    });
  });
}
