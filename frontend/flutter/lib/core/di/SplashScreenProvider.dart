import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/mock/MockStoreLocalHike.dart';
import 'package:naavi/presentation/splash/state/SplashScreenState.dart';
import 'package:naavi/presentation/splash/state/SplashScreenStateNotifier.dart';

import '../../data/datasources/LocalStorageHikeDataSource.dart';
import '../../data/datasources/RemoteStorageHikingDataSource.dart';
import '../../data/repertories/StoreHikingRepertoryImpl.dart';
import '../../domain/repertory/StoreHikingRepository.dart';
import '../../domain/usecases/storeHikingUseCase.dart';
import '../services/network/check_network_service.dart';
import 'AuthProvider.dart'; // Import pour utiliser authServiceProvider

final localHikeDataSourceProvider = Provider<LocalStorageHikeDataSource>((ref) {
  return MockLocalStorageHikeDataSource();
});

final remoteHikeDataSourceProvider = Provider<RemoteStorageHikingDataSource>((
  ref,
) {
  return RemoteStorageHikingDataSource();
});

final storeHikingRepositoryProvider = Provider<StoreHikingRepository>((ref) {
  final localHikeDataSource = ref.watch(localHikeDataSourceProvider);
  final remoteHikeDataSource = ref.watch(remoteHikeDataSourceProvider);

  return StoreHikingRepositoryImpl(
    localStorageHikeDataSource: localHikeDataSource,
    remoteStorageHikingDataSource: remoteHikeDataSource,
  );
});

final checkNetworkServiceProvider = Provider<CheckNetworkService>((ref) {
  return CheckNetworkService();
});

final storeHikingUseCaseProvider = Provider<StoreHikingUseCase>((ref) {
  return StoreHikingUseCase(
    storeHikingRepository: ref.read(storeHikingRepositoryProvider),
    checkNetworkService: ref.read(checkNetworkServiceProvider),
  );
});

final splashScreenProvider =
    StateNotifierProvider<SplashScreenStateNotifier, SplashScreenState>((ref) {
      final storeHikingUseCase = ref.watch(storeHikingUseCaseProvider);
      final authService = ref.watch(authServiceProvider);
      return SplashScreenStateNotifier(
        storeHikingUseCase: storeHikingUseCase,
        authService: authService,
      );
    });
