import '../../core/services/network/check_network_service.dart';
import '../../data/models/HikeModel.dart';
import '../entities/Hike.dart';
import '../repertory/StoreHikingRepository.dart';

class StoreHikingUseCase {
  final StoreHikingRepository storeHikingRepository;
  final CheckNetworkService checkNetworkService;
  StoreHikingUseCase({
    required this.storeHikingRepository,
    required this.checkNetworkService,
  });

  Future<void> saveHikeLocally(
    double startPointLat,
    double startPointLng,
    paths,
  ) async {
    Hike hike = Hike(
      startPoint: PathPoint(latitude: startPointLat, longitude: startPointLng),
      paths: paths,
    );

    await storeHikingRepository.saveHikeLocally(hike);
  }

  Future<void> saveCompletedHike(List<List<PathPoint>> paths) async {
    //checker la connexion pour savoir si on peut synchroniser les données
    var connectivityState = await checkNetworkService.checkConnection();

    var completedHike = Hike(
      startPoint: PathPoint(
        latitude: paths.first.first.latitude,
        longitude: paths.first.first.longitude,
      ),
      endPoint: PathPoint(
        latitude: paths.last.last.latitude,
        longitude: paths.last.last.longitude,
      ),
      paths: paths,
    );

    if (connectivityState == ConnectivityState.offline) {
      await saveHikeLocally(
        completedHike.startPoint.latitude,
        completedHike.startPoint.longitude,
        completedHike.paths,
      );
      return;
    }
    if (connectivityState == ConnectivityState.online) {}
  }

  Future<Hike?> getLocalHike() async {
    return await storeHikingRepository.getHike();
  }

  Future<void> clearLocalHike() async {
    await storeHikingRepository.clearHike();
  }
}
