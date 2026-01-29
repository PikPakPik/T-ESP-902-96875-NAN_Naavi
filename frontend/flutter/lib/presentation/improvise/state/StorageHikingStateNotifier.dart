import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/data/models/HikeModel.dart';
import '../../../domain/usecases/storeHikingUseCase.dart';
import 'StorageHikingState.dart';

class StorageHikingStateNotifier extends StateNotifier<StorageHikingState> {
  final StoreHikingUseCase storeHikingUseCase;

  StorageHikingStateNotifier({required this.storeHikingUseCase}): super(const StorageHikingStateIdle());

  void startHike() {
    state = const StorageHikingStateTracking();
  }

  void pauseHike() {
    state = const StorageHikingStatePaused(
      startLatitude: 0,
      startLongitude: 0,
      paths: [],
    );
  }

  Future<void> pausedHike(double startPointLat, double startPointLng, List<List<PathPoint>>paths) async {
    try {
      state = const StorageHikingStateLoading();
      await storeHikingUseCase.saveHikeLocally(startPointLat, startPointLng, paths);
      state = const StorageHikingStatePaused(
        startLatitude: 0,
        startLongitude: 0,
        paths: [],
      );
    } catch (e) {
      state = const StorageHikingStateError();
    }
  }

  Future<void> finishedHike(double endPointLat, double endPointLng, List<List<PathPoint>> paths) async {
    try {
      state = const StorageHikingStateLoading();
      await storeHikingUseCase.saveCompletedHike(paths);
    } catch (e) {
      state = const StorageHikingStateError();
    }
  }

  Future<void> syncronizeHike() async {

  }
}