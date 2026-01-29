import 'package:naavi/data/models/HikeModel.dart';
import 'package:naavi/domain/entities/Hike.dart';
import 'package:naavi/domain/repertory/StoreHikingRepository.dart';
import '../datasources/LocalStorageHikeDataSource.dart';
import '../datasources/RemoteStorageHikingDataSource.dart';

class StoreHikingRepositoryImpl implements StoreHikingRepository {
  final RemoteStorageHikingDataSource remoteStorageHikingDataSource;
  final LocalStorageHikeDataSource localStorageHikeDataSource;
  StoreHikingRepositoryImpl({
    required this.localStorageHikeDataSource,
    required this.remoteStorageHikingDataSource,
  });

  @override
  Future<void> saveHikeLocally(Hike hike) async {
    final hikeModel = HikeModel(
      startPoint: PathPoint(
        latitude: hike.startPoint.latitude,
        longitude: hike.startPoint.longitude,
      ),
      paths: hike.paths,
    );
    try {
      await localStorageHikeDataSource.saveHike(hikeModel);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  @override
  Future<Hike?> getHike() async {
    final restoredHike = localStorageHikeDataSource.getHike();
    return restoredHike.then(
      (hikeModel) => Hike(
        startPoint: PathPoint(
          latitude: hikeModel!.startPoint.latitude,
          longitude: hikeModel.startPoint.longitude,
        ),
        paths: hikeModel.paths,
      ),
    );
  }

  @override
  Future<void> clearHike() async {
    try {
      await localStorageHikeDataSource.clearHike();
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  @override
  Future<void> saveCompletedHike(Hike hike) async {
    final hikeModel = HikeModel(
      startPoint: PathPoint(
        latitude: hike.startPoint.latitude,
        longitude: hike.startPoint.longitude,
      ),
      paths: hike.paths,
    );

    try {
      await remoteStorageHikingDataSource.saveCompletedHike(hikeModel);
    } catch (e) {
      // Intentionally empty catch block
    }
  }
}
