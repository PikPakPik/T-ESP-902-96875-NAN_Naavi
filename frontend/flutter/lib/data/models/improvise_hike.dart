import 'package:naavi/data/models/user_poi.dart';
import 'package:naavi/core/utils/poi_type.dart';

class ImproviseHike {
  final String? title;
  final String distance;
  final Duration finalTime;
  final double? elevationGainPositive;
  final double? elevationGainNegative;

  final List<PoiType> poiTypes; // Types uniques (pour compatibilité)
  final List<UserPOI> pois; // Liste complète des POI avec localisation

  ImproviseHike({
    this.title,
    required this.distance,
    required this.finalTime,
    required this.poiTypes,
    required this.pois,
    this.elevationGainPositive,
    this.elevationGainNegative,
  });
}