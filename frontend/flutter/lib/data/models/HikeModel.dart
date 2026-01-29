import 'dart:convert';

class HikeModel {
  final PathPoint startPoint;
  final PathPoint? endPoint;
  final List<List<PathPoint>> paths; //Liste de path dans une rando (List<PathPoint> équivalent à une partie du trajet)


  HikeModel({
    required this.startPoint,
    this.endPoint,
    required this.paths,
  });


  Map<String, dynamic> toMap() {
    return {
      'startPoint': {
        'latitude': startPoint.latitude,
        'longitude': startPoint.longitude,
      },
      'endPoint': {
        'latitude': endPoint?.latitude,
        'longitude': endPoint?.longitude,
      },
      'paths': paths
          .map((path) => path
          .map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList()
      ).toList(),
    };
  }

  factory HikeModel.fromMap(Map<String, dynamic> map) {
    return HikeModel(
        startPoint: PathPoint(latitude: map['startPoint']['latitude'], longitude: map['startPoint']['longitude']),
        endPoint: PathPoint(longitude: map['endPoint']['latitude'], latitude: map['endPoint']['longitude']),
        paths: (map['paths'] as List)
            .map((path) => (path as List)
            .map((p) => PathPoint(
              latitude: p['latitude'],
              longitude: p['longitude'],
            )
          ).toList()
        ).toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory HikeModel.fromJson(String source) => HikeModel.fromMap(json.decode(source));
}

class PathPoint {
  final double latitude;
  final double longitude;

  PathPoint({required this.latitude, required this.longitude});
}