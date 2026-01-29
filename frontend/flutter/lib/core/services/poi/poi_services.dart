import 'package:flutter/foundation.dart';
import '../../../data/models/user_poi.dart';
import '../../utils/poi_type.dart';

class PoiService {
  // Liste des POI placés pendant la randonnée actuelle
  List<UserPOI> hikePois = [];

  List<UserPOI> getHikePois() {
    if (kDebugMode) {
    }
    return hikePois;
  }

  void clearHikePois() {
    hikePois.clear();
  }

  void addHikePoi(UserPOI poi) {
    if (kDebugMode) {
    }
    hikePois.add(poi);
  }

  // Ancienne méthode conservée pour compatibilité
  List<PoiType> getPoiTypesImproviseHike() {
    // Retourner les types uniques des POI de la randonnée
    Set<PoiType> uniqueTypes = {};
    for (var poi in hikePois) {
      uniqueTypes.add(poi.type);
    }
    return uniqueTypes.toList();
  }

  void setPoiTypesImproviseHike() {
    // Méthode conservée pour compatibilité
  }
}
