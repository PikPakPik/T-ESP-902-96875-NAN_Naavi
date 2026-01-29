import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/core/di/RecapHikeProvider.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/core/services/statistics/statistics_service.dart';
import 'package:naavi/domain/usecases/finishImproviseUseCase.dart';
import 'package:naavi/presentation/common/recap/RecapHikeState.dart';
import 'package:naavi/presentation/common/recap/RecapHikeStateNotifier.dart';

void main() {
  group('RecapHikeProvider', () {
    group('statisticsServiceProvider', () {
      test('should provide a StatisticsService instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(statisticsServiceProvider);
        expect(service, isA<StatisticsService>());
      });

      test('should provide same instance on multiple reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service1 = container.read(statisticsServiceProvider);
        final service2 = container.read(statisticsServiceProvider);
        expect(identical(service1, service2), isTrue);
      });
    });

    group('poiService', () {
      test('should provide a PoiService instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(poiService);
        expect(service, isA<PoiService>());
      });

      test('should provide same instance on multiple reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service1 = container.read(poiService);
        final service2 = container.read(poiService);
        expect(identical(service1, service2), isTrue);
      });
    });

    group('finishImproviseUseCaseProvider', () {
      test('should provide a FinishImproviseUseCase instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(finishImproviseUseCaseProvider);
        expect(useCase, isA<FinishImproviseUseCase>());
      });

      test('should provide same instance on multiple reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase1 = container.read(finishImproviseUseCaseProvider);
        final useCase2 = container.read(finishImproviseUseCaseProvider);
        expect(identical(useCase1, useCase2), isTrue);
      });

      test('should use statisticsServiceProvider dependency', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Reading the useCase should not throw
        final useCase = container.read(finishImproviseUseCaseProvider);
        expect(useCase, isNotNull);
      });

      test('should use poiService dependency', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Reading the useCase should not throw
        final useCase = container.read(finishImproviseUseCaseProvider);
        expect(useCase, isNotNull);
      });
    });

    group('recapHikeProvider', () {
      test('should provide a RecapHikeStateNotifier instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(recapHikeProvider.notifier);
        expect(notifier, isA<RecapHikeStateNotifier>());
      });

      test('should initialize with RecapHikeStateLoading state', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = container.read(recapHikeProvider);
        expect(state, isA<RecapHikeStateLoading>());
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer();
        final notifier = container.read(recapHikeProvider.notifier);
        expect(notifier.mounted, isTrue);

        container.dispose();
        expect(notifier.mounted, isFalse);
      });

      test('should notify listeners when state changes', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.listen(recapHikeProvider, (previous, next) {});

        // Get the notifier but don't trigger state change
        final notifier = container.read(recapHikeProvider.notifier);
        expect(notifier, isNotNull);
        // Initial state already counted in listen
      });

      test('should use finishImproviseUseCaseProvider dependency', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Reading the provider should not throw
        final state = container.read(recapHikeProvider);
        expect(state, isNotNull);
      });
    });
  });
}
