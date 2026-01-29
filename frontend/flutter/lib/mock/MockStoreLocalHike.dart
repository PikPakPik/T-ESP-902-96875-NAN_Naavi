import 'package:naavi/data/datasources/LocalStorageHikeDataSource.dart';
import 'package:naavi/data/models/HikeModel.dart';

class MockLocalStorageHikeDataSource extends LocalStorageHikeDataSource {
  final mockHikeModel = HikeModel(
    startPoint: PathPoint(latitude: 48.8566, longitude: 2.3522), // Paris centre
    paths: [
      [
        PathPoint(latitude: 48.8566, longitude: 2.3522), // départ
        PathPoint(latitude: 48.8570, longitude: 2.3530),
        PathPoint(latitude: 48.8580, longitude: 2.3540),
        PathPoint(latitude: 48.8590, longitude: 2.3550),
      ],
      [
        PathPoint(latitude: 48.8590, longitude: 2.3550),
        PathPoint(latitude: 48.8585, longitude: 2.3525),
        PathPoint(latitude: 48.8575, longitude: 2.3515),
        PathPoint(latitude: 48.8566, longitude: 2.3522), // retour au départ
      ],
    ],
  );

  @override
  Future<HikeModel?> getHike() async {
    return mockHikeModel;
  }
}
