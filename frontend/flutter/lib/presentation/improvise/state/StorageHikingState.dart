import '../../../data/models/HikeModel.dart';

sealed class StorageHikingState {
  const StorageHikingState();
}

class StorageHikingStateIdle extends StorageHikingState {
  const StorageHikingStateIdle();
}

class StorageHikingStateTracking extends StorageHikingState {
  const StorageHikingStateTracking();
}

class StorageHikingStateLoading extends StorageHikingState {
  const StorageHikingStateLoading();
}

class StorageHikingStateSyncronized extends StorageHikingState {
  const StorageHikingStateSyncronized();
}

class StorageHikingStatePaused extends StorageHikingState {
  final double startLatitude;
  final double startLongitude;
  final List<List<PathPoint>> paths;

  const StorageHikingStatePaused({
    required this.startLatitude,
    required this.startLongitude,
    required this.paths,
  });
}

class StorageHikingStateError extends StorageHikingState {
  const StorageHikingStateError();
}