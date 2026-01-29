import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naavi/data/models/user_poi.dart';

/// Service pour gérer les POI créés par l'utilisateur
/// Sauvegarde et chargement via SharedPreferences
class UserPoiService {
  static const String _storageKey = 'user_pois';

  /// Récupérer tous les POI sauvegardés
  static Future<List<UserPOI>> getAllPOIs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final poisJson = prefs.getStringList(_storageKey);

      if (poisJson == null || poisJson.isEmpty) {
        return [];
      }

      return poisJson.map((json) => UserPOI.fromJsonString(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarder un nouveau POI
  static Future<bool> savePOI(UserPOI poi) async {
    try {
      final pois = await getAllPOIs();
      pois.add(poi);

      final prefs = await SharedPreferences.getInstance();
      final poisJson = pois.map((p) => p.toJsonString()).toList();

      await prefs.setStringList(_storageKey, poisJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprimer un POI
  static Future<bool> deletePOI(String poiId) async {
    try {
      final pois = await getAllPOIs();
      pois.removeWhere((p) => p.id == poiId);

      final prefs = await SharedPreferences.getInstance();
      final poisJson = pois.map((p) => p.toJsonString()).toList();

      await prefs.setStringList(_storageKey, poisJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mettre à jour un POI existant
  static Future<bool> updatePOI(UserPOI updatedPoi) async {
    try {
      final pois = await getAllPOIs();
      final index = pois.indexWhere((p) => p.id == updatedPoi.id);

      if (index == -1) {
        return false;
      }

      pois[index] = updatedPoi;

      final prefs = await SharedPreferences.getInstance();
      final poisJson = pois.map((p) => p.toJsonString()).toList();

      await prefs.setStringList(_storageKey, poisJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Effacer tous les POI
  static Future<bool> clearAllPOIs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les POI d'un type spécifique
  static Future<List<UserPOI>> getPOIsByType(String type) async {
    final allPois = await getAllPOIs();
    return allPois.where((poi) => poi.type.name == type).toList();
  }

  /// Récupérer les POI dans une zone géographique
  static Future<List<UserPOI>> getPOIsInArea({
    required double centerLat,
    required double centerLon,
    required double radiusKm,
  }) async {
    final allPois = await getAllPOIs();

    return allPois.where((poi) {
      final distance = _calculateDistance(
        centerLat,
        centerLon,
        poi.latitude,
        poi.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculer la distance entre deux points (formule de Haversine)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
