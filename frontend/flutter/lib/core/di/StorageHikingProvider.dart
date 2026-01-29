import '../../data/datasources/LocalStorageHikeDataSource.dart';
import '../../data/datasources/RemoteStorageHikingDataSource.dart';
import '../../data/repertories/StoreHikingRepertoryImpl.dart';
import '../../domain/repertory/StoreHikingRepository.dart';
import '../../domain/usecases/storeHikingUseCase.dart';
import '../../presentation/improvise/state/StorageHikingStateNotifier.dart';
import '../../presentation/improvise/state/StorageHikingState.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/network/check_network_service.dart';


final localHikeDataSourceProvider = Provider<LocalStorageHikeDataSource>((ref) {
  return LocalStorageHikeDataSource();
});

final remoteHikeDataSourceProvider = Provider<RemoteStorageHikingDataSource>((ref) {
  return RemoteStorageHikingDataSource();
});

final storeHikingRepositoryProvider = Provider<StoreHikingRepository>((ref) {
  final localHikeDataSource = ref.watch(localHikeDataSourceProvider);
  final remoteHikeDataSource = ref.watch(remoteHikeDataSourceProvider);

  return StoreHikingRepositoryImpl(
      localStorageHikeDataSource: localHikeDataSource,
      remoteStorageHikingDataSource: remoteHikeDataSource
  );
});

final checkNetworkServiceProvider = Provider<CheckNetworkService>((ref) {
  return CheckNetworkService();
});

final storeHikingUseCaseProvider = Provider<StoreHikingUseCase>((ref) {
  return StoreHikingUseCase(
      storeHikingRepository: ref.read(storeHikingRepositoryProvider),
      checkNetworkService: ref.read(checkNetworkServiceProvider));
});

final storageHikingProvider = StateNotifierProvider<StorageHikingStateNotifier, StorageHikingState>((ref){
  final storeHikingUseCase = ref.watch(storeHikingUseCaseProvider);
  return StorageHikingStateNotifier(storeHikingUseCase: storeHikingUseCase);
});

