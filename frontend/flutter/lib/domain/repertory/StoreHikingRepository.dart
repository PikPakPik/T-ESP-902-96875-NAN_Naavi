import '../entities/Hike.dart';

abstract class StoreHikingRepository {
  Future<void> saveHikeLocally(Hike hike);
  Future<Hike?> getHike();
  Future<void> clearHike();
  Future<void> saveCompletedHike(Hike hike);
}