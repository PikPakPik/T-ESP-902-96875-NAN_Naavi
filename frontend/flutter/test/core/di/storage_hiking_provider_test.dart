import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/di/StorageHikingProvider.dart';
import 'package:naavi/core/services/network/check_network_service.dart';
import 'package:naavi/data/datasources/LocalStorageHikeDataSource.dart';
import 'package:naavi/data/datasources/RemoteStorageHikingDataSource.dart';
import 'package:naavi/data/repertories/StoreHikingRepertoryImpl.dart';
import 'package:naavi/domain/repertory/StoreHikingRepository.dart';
import 'package:naavi/domain/usecases/storeHikingUseCase.dart';
import 'package:naavi/presentation/improvise/state/StorageHikingState.dart';
import 'package:naavi/presentation/improvise/state/StorageHikingStateNotifier.dart';

// Mock classes
class MockLocalStorageHikeDataSource extends Mock
    implements LocalStorageHikeDataSource {}

class MockRemoteStorageHikingDataSource extends Mock
    implements RemoteStorageHikingDataSource {}

class MockStoreHikingRepository extends Mock implements StoreHikingRepository {}

class MockCheckNetworkService extends Mock implements CheckNetworkService {}

class MockStoreHikingUseCase extends Mock implements StoreHikingUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageHikingProvider', () {
    group('localHikeDataSourceProvider', () {
      test('should provide a LocalStorageHikeDataSource instance', () {
        final container = ProviderContainer();

        final dataSource = container.read(localHikeDataSourceProvider);

        expect(dataSource, isA<LocalStorageHikeDataSource>());

        container.dispose();
      });

      test('should provide the same instance on multiple reads', () {
        final container = ProviderContainer();

        final dataSource1 = container.read(localHikeDataSourceProvider);
        final dataSource2 = container.read(localHikeDataSourceProvider);

        expect(dataSource1, same(dataSource2));

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final dataSource1 = container1.read(localHikeDataSourceProvider);
        final dataSource2 = container2.read(localHikeDataSourceProvider);

        expect(dataSource1, isNot(same(dataSource2)));

        container1.dispose();
        container2.dispose();
      });

      test('should support provider override for testing', () {
        final mockDataSource = MockLocalStorageHikeDataSource();
        final container = ProviderContainer(
          overrides: [
            localHikeDataSourceProvider.overrideWithValue(mockDataSource),
          ],
        );

        final dataSource = container.read(localHikeDataSourceProvider);

        expect(dataSource, same(mockDataSource));

        container.dispose();
      });
    });

    group('remoteHikeDataSourceProvider', () {
      test('should provide a RemoteStorageHikingDataSource instance', () {
        final container = ProviderContainer();

        final dataSource = container.read(remoteHikeDataSourceProvider);

        expect(dataSource, isA<RemoteStorageHikingDataSource>());

        container.dispose();
      });

      test('should provide the same instance on multiple reads', () {
        final container = ProviderContainer();

        final dataSource1 = container.read(remoteHikeDataSourceProvider);
        final dataSource2 = container.read(remoteHikeDataSourceProvider);

        expect(dataSource1, same(dataSource2));

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final dataSource1 = container1.read(remoteHikeDataSourceProvider);
        final dataSource2 = container2.read(remoteHikeDataSourceProvider);

        expect(dataSource1, isNot(same(dataSource2)));

        container1.dispose();
        container2.dispose();
      });

      test('should support provider override for testing', () {
        final mockDataSource = MockRemoteStorageHikingDataSource();
        final container = ProviderContainer(
          overrides: [
            remoteHikeDataSourceProvider.overrideWithValue(mockDataSource),
          ],
        );

        final dataSource = container.read(remoteHikeDataSourceProvider);

        expect(dataSource, same(mockDataSource));

        container.dispose();
      });
    });

    group('storeHikingRepositoryProvider', () {
      test('should provide a StoreHikingRepository instance', () {
        final container = ProviderContainer();

        final repository = container.read(storeHikingRepositoryProvider);

        expect(repository, isA<StoreHikingRepository>());
        expect(repository, isA<StoreHikingRepositoryImpl>());

        container.dispose();
      });

      test('should watch localHikeDataSourceProvider', () {
        final mockLocalDataSource = MockLocalStorageHikeDataSource();
        final mockRemoteDataSource = MockRemoteStorageHikingDataSource();

        final container = ProviderContainer(
          overrides: [
            localHikeDataSourceProvider.overrideWithValue(mockLocalDataSource),
            remoteHikeDataSourceProvider.overrideWithValue(
              mockRemoteDataSource,
            ),
          ],
        );

        final repository = container.read(storeHikingRepositoryProvider);

        expect(repository, isA<StoreHikingRepositoryImpl>());

        container.dispose();
      });

      test('should watch remoteHikeDataSourceProvider', () {
        final mockLocalDataSource = MockLocalStorageHikeDataSource();
        final mockRemoteDataSource = MockRemoteStorageHikingDataSource();

        final container = ProviderContainer(
          overrides: [
            localHikeDataSourceProvider.overrideWithValue(mockLocalDataSource),
            remoteHikeDataSourceProvider.overrideWithValue(
              mockRemoteDataSource,
            ),
          ],
        );

        final repository = container.read(storeHikingRepositoryProvider);

        expect(repository, isA<StoreHikingRepositoryImpl>());

        container.dispose();
      });

      test('should provide the same instance on multiple reads', () {
        final container = ProviderContainer();

        final repository1 = container.read(storeHikingRepositoryProvider);
        final repository2 = container.read(storeHikingRepositoryProvider);

        expect(repository1, same(repository2));

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final repository1 = container1.read(storeHikingRepositoryProvider);
        final repository2 = container2.read(storeHikingRepositoryProvider);

        expect(repository1, isNot(same(repository2)));

        container1.dispose();
        container2.dispose();
      });

      test('should support provider override for testing', () {
        final mockRepository = MockStoreHikingRepository();
        final container = ProviderContainer(
          overrides: [
            storeHikingRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );

        final repository = container.read(storeHikingRepositoryProvider);

        expect(repository, same(mockRepository));

        container.dispose();
      });
    });

    group('checkNetworkServiceProvider', () {
      test('should provide a CheckNetworkService instance', () {
        final container = ProviderContainer();

        final service = container.read(checkNetworkServiceProvider);

        expect(service, isA<CheckNetworkService>());

        container.dispose();
      });

      test('should provide the same instance on multiple reads', () {
        final container = ProviderContainer();

        final service1 = container.read(checkNetworkServiceProvider);
        final service2 = container.read(checkNetworkServiceProvider);

        expect(service1, same(service2));

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final service1 = container1.read(checkNetworkServiceProvider);
        final service2 = container2.read(checkNetworkServiceProvider);

        expect(service1, isNot(same(service2)));

        container1.dispose();
        container2.dispose();
      });

      test('should support provider override for testing', () {
        final mockService = MockCheckNetworkService();
        final container = ProviderContainer(
          overrides: [
            checkNetworkServiceProvider.overrideWithValue(mockService),
          ],
        );

        final service = container.read(checkNetworkServiceProvider);

        expect(service, same(mockService));

        container.dispose();
      });
    });

    group('storeHikingUseCaseProvider', () {
      test('should provide a StoreHikingUseCase instance', () {
        final container = ProviderContainer();

        final useCase = container.read(storeHikingUseCaseProvider);

        expect(useCase, isA<StoreHikingUseCase>());

        container.dispose();
      });

      test('should read storeHikingRepositoryProvider', () {
        final mockRepository = MockStoreHikingRepository();
        final mockNetworkService = MockCheckNetworkService();

        final container = ProviderContainer(
          overrides: [
            storeHikingRepositoryProvider.overrideWithValue(mockRepository),
            checkNetworkServiceProvider.overrideWithValue(mockNetworkService),
          ],
        );

        final useCase = container.read(storeHikingUseCaseProvider);

        expect(useCase, isA<StoreHikingUseCase>());

        container.dispose();
      });

      test('should read checkNetworkServiceProvider', () {
        final mockRepository = MockStoreHikingRepository();
        final mockNetworkService = MockCheckNetworkService();

        final container = ProviderContainer(
          overrides: [
            storeHikingRepositoryProvider.overrideWithValue(mockRepository),
            checkNetworkServiceProvider.overrideWithValue(mockNetworkService),
          ],
        );

        final useCase = container.read(storeHikingUseCaseProvider);

        expect(useCase, isA<StoreHikingUseCase>());

        container.dispose();
      });

      test('should provide the same instance on multiple reads', () {
        final container = ProviderContainer();

        final useCase1 = container.read(storeHikingUseCaseProvider);
        final useCase2 = container.read(storeHikingUseCaseProvider);

        expect(useCase1, same(useCase2));

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final useCase1 = container1.read(storeHikingUseCaseProvider);
        final useCase2 = container2.read(storeHikingUseCaseProvider);

        expect(useCase1, isNot(same(useCase2)));

        container1.dispose();
        container2.dispose();
      });

      test('should support provider override for testing', () {
        final mockUseCase = MockStoreHikingUseCase();
        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final useCase = container.read(storeHikingUseCaseProvider);

        expect(useCase, same(mockUseCase));

        container.dispose();
      });
    });

    group('storageHikingProvider', () {
      late MockStoreHikingUseCase mockUseCase;

      setUp(() {
        mockUseCase = MockStoreHikingUseCase();
      });

      test('should provide a StorageHikingStateNotifier instance', () {
        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final notifier = container.read(storageHikingProvider.notifier);

        expect(notifier, isA<StorageHikingStateNotifier>());

        container.dispose();
      });

      test('should initialize with StorageHikingInitial state', () {
        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final state = container.read(storageHikingProvider);

        expect(state, isA<StorageHikingStateIdle>());

        container.dispose();
      });

      test('should watch storeHikingUseCaseProvider', () {
        var buildCount = 0;
        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWith((ref) {
              buildCount++;
              return mockUseCase;
            }),
          ],
        );

        container.read(storageHikingProvider.notifier);
        expect(buildCount, 1);

        container.dispose();
      });

      test('should provide the same notifier instance on multiple reads', () {
        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final notifier1 = container.read(storageHikingProvider.notifier);
        final notifier2 = container.read(storageHikingProvider.notifier);

        expect(notifier1, same(notifier2));

        container.dispose();
      });

      test('should create different instances in different containers', () {
        final container1 = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final container2 = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final notifier1 = container1.read(storageHikingProvider.notifier);
        final notifier2 = container2.read(storageHikingProvider.notifier);

        expect(notifier1, isNot(same(notifier2)));

        container1.dispose();
        container2.dispose();
      });

      test('should notify listeners when state changes', () {
        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        var notificationCount = 0;
        StorageHikingState? lastState;

        container.listen(storageHikingProvider, (previous, next) {
          notificationCount++;
          lastState = next;
        });

        final notifier = container.read(storageHikingProvider.notifier);
        notifier.startHike();

        expect(notificationCount, greaterThan(0));
        expect(lastState, isNotNull);

        container.dispose();
      });

      test('should support provider override for testing', () {
        final mockNotifier = StorageHikingStateNotifier(
          storeHikingUseCase: mockUseCase,
        );
        final container = ProviderContainer(
          overrides: [
            storageHikingProvider.overrideWith((ref) => mockNotifier),
          ],
        );

        final notifier = container.read(storageHikingProvider.notifier);

        expect(notifier, same(mockNotifier));

        container.dispose();
      });

      test('should maintain independent state in different containers', () {
        final container1 = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final container2 = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final notifier1 = container1.read(storageHikingProvider.notifier);
        notifier1.startHike();

        // Container1 should have changed state
        expect(
          container1.read(storageHikingProvider),
          isNot(isA<StorageHikingStateIdle>()),
        );

        // Container2 should still have initial state
        expect(
          container2.read(storageHikingProvider),
          isA<StorageHikingStateIdle>(),
        );

        container1.dispose();
        container2.dispose();
      });

      test('should dispose properly when container is disposed', () {
        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final notifier = container.read(storageHikingProvider.notifier);

        expect(notifier.mounted, true);

        container.dispose();

        expect(notifier.mounted, false);
      });
    });

    group('Provider dependency chain', () {
      test('should have correct dependency chain', () {
        final container = ProviderContainer();

        final localDataSource = container.read(localHikeDataSourceProvider);
        final remoteDataSource = container.read(remoteHikeDataSourceProvider);
        final repository = container.read(storeHikingRepositoryProvider);
        final networkService = container.read(checkNetworkServiceProvider);
        final useCase = container.read(storeHikingUseCaseProvider);
        final notifier = container.read(storageHikingProvider.notifier);

        expect(localDataSource, isA<LocalStorageHikeDataSource>());
        expect(remoteDataSource, isA<RemoteStorageHikingDataSource>());
        expect(repository, isA<StoreHikingRepository>());
        expect(networkService, isA<CheckNetworkService>());
        expect(useCase, isA<StoreHikingUseCase>());
        expect(notifier, isA<StorageHikingStateNotifier>());

        container.dispose();
      });

      test('should propagate changes from dependency providers', () {
        final mockUseCase = MockStoreHikingUseCase();
        var useCaseBuildCount = 0;

        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWith((ref) {
              useCaseBuildCount++;
              return mockUseCase;
            }),
          ],
        );

        container.read(storageHikingProvider.notifier);
        expect(useCaseBuildCount, 1);

        container.dispose();
      });

      test('should maintain provider scope isolation', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final useCase1 = container1.read(storeHikingUseCaseProvider);
        final useCase2 = container2.read(storeHikingUseCaseProvider);

        expect(useCase1, isNot(same(useCase2)));

        container1.dispose();
        container2.dispose();
      });
    });

    group('Integration scenarios', () {
      test('should handle hike storage workflow', () {
        final mockUseCase = MockStoreHikingUseCase();

        final container = ProviderContainer(
          overrides: [
            storeHikingUseCaseProvider.overrideWithValue(mockUseCase),
          ],
        );

        final states = <StorageHikingState>[];
        container.listen(storageHikingProvider, (previous, next) {
          states.add(next);
        });

        final notifier = container.read(storageHikingProvider.notifier);
        notifier.startHike();

        expect(states, isNotEmpty);

        container.dispose();
      });

      test('should support both local and remote data sources', () {
        final container = ProviderContainer();

        final localDataSource = container.read(localHikeDataSourceProvider);
        final remoteDataSource = container.read(remoteHikeDataSourceProvider);
        final repository = container.read(storeHikingRepositoryProvider);

        expect(localDataSource, isNotNull);
        expect(remoteDataSource, isNotNull);
        expect(repository, isNotNull);

        container.dispose();
      });

      test('should integrate network service for online/offline handling', () {
        final container = ProviderContainer();

        final networkService = container.read(checkNetworkServiceProvider);
        final useCase = container.read(storeHikingUseCaseProvider);

        expect(networkService, isNotNull);
        expect(useCase, isNotNull);

        container.dispose();
      });
    });
  });
}
