
import 'package:naavi/data/models/HikeModel.dart';

class Hike {
  final PathPoint startPoint;
  final PathPoint? endPoint;
  final List<List<PathPoint>> paths;

  Hike({
    required this.startPoint,
    this.endPoint,
    required this.paths,
  });
}