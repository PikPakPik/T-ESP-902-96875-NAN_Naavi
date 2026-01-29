import 'dart:convert';
import '../../core/utils/poi_type.dart';

/// Modèle pour représenter un POI créé par l'utilisateur
class UserPOI {
  final String id;
  final String name;
  final PoiType type; // Type de POI (enum)
  final double latitude;
  final double longitude;
  final String description;
  final DateTime createdAt;

  UserPOI({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.description = '',
    required this.createdAt,
  });

  /// Convertir en JSON string pour le stockage
  String toJsonString() {
    return jsonEncode(toMap());
  }

  /// Créer depuis un JSON string
  factory UserPOI.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserPOI.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.key, // Convertir l'enum en string anglais pour sérialisation
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserPOI.fromMap(Map<String, dynamic> map) {
    return UserPOI(
      id: map['id'] as String,
      name: map['name'] as String,
      type: _parsePoiType(map['type'] as String), // Convertir le string en enum
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Convertir un string en PoiType
  static PoiType _parsePoiType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'parking':
        return PoiType.parking;
      case 'hazard':
      case 'danger':
        return PoiType.hazard;
      case 'toilets':
      case 'toilettes':
        return PoiType.toilets;
      case 'water':
      case 'eau':
        return PoiType.water;
      case 'camping':
        return PoiType.camping;
      case 'animals':
      case 'animaux':
        return PoiType.animals;
      default:
        return PoiType.hazard; // Par défaut
    }
  }
}
