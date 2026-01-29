import 'package:flutter/material.dart';

enum PoiType {
  parking,
  hazard,
  toilets,
  water,
  camping,
  animals,
}

extension PoiIconTypeExtension on PoiType {
  Widget icon({double size = 24}) {
    switch (this) {
      case PoiType.parking:
        return PoiIcons.parking(size: size);
      case PoiType.hazard:
        return PoiIcons.hazard(size: size);
      case PoiType.toilets:
        return PoiIcons.toilets(size: size);
      case PoiType.water:
        return PoiIcons.water(size: size);
      case PoiType.camping:
        return PoiIcons.camping(size: size);
      case PoiType.animals:
        return PoiIcons.animals(size: size);
    }
  }

  /// Returns the English key for serialization
  String get key {
    switch (this) {
      case PoiType.parking:
        return 'parking';
      case PoiType.hazard:
        return 'hazard';
      case PoiType.toilets:
        return 'toilets';
      case PoiType.water:
        return 'water';
      case PoiType.camping:
        return 'camping';
      case PoiType.animals:
        return 'animals';
    }
  }

  String get name {
    switch (this) {
      case PoiType.parking:
        return 'Parking';
      case PoiType.hazard:
        return 'Danger';
        case PoiType.toilets:
        return 'Toilettes';
        case PoiType.water:
        return 'Source d\'eau';
        case PoiType.camping:
        return 'Camping';
        case PoiType.animals:
        return 'Passage d\'animaux';
    }
  }

  Color get color {
    switch (this) {
      case PoiType.parking:
        return const Color(0xFF6A89CC);
      case PoiType.hazard:
        return const Color(0xFFE45039);
      case PoiType.toilets:
        return const Color(0xFF42A5F5);
      case PoiType.water:
        return const Color(0xFF29B6F6);
      case PoiType.camping:
        return const Color(0xFF66BB6A);
      case PoiType.animals:
        return const Color(0xFFFF9800);
    }
  }

  String get assetPath {
    switch (this) {
      case PoiType.parking:
        return 'assets/icons/report/parking.png';
      case PoiType.hazard:
        return 'assets/icons/report/hazard.png';
      case PoiType.toilets:
        return 'assets/icons/poi/toilets.png';
      case PoiType.water:
        return 'assets/icons/poi/water.png';
      case PoiType.camping:
        return 'assets/icons/poi/camping.png';
      case PoiType.animals:
        return 'assets/icons/poi/pets.png';
    }
  }
}

class PoiIcons {
  static const String _basePath = 'assets/icons/';

  static Image parking({double size = 24}) =>
      Image.asset('${_basePath}report/parking.png', width: size, height: size);

  static Image hazard({double size = 24}) =>
      Image.asset('${_basePath}report/hazard.png', width: size, height: size);

  static Image toilets({double size = 24}) =>
      Image.asset('${_basePath}poi/toilets.png', width: size, height: size);

  static Image water({double size = 24}) =>
      Image.asset('${_basePath}poi/water.png', width: size, height: size);

  static Image camping({double size = 24}) =>
      Image.asset('${_basePath}poi/camping.png', width: size, height: size);

  static Image animals({double size = 24}) =>
      Image.asset('${_basePath}poi/pets.png', width: size, height: size);
}
