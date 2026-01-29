import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../data/models/hike_dto.dart';
import '../../data/models/point_of_interest_dto.dart';
import '../utils/http_client.dart';

/// Service pour récupérer les randonnées depuis l'API
class HikesApiService {
  final http.Client? authenticatedClient;

  HikesApiService({this.authenticatedClient});

  String? get _baseUrl => dotenv.env['API_BASE_URL'];

  /// Client HTTP pour les requêtes non authentifiées
  http.Client get _httpClient => authenticatedClient ?? CustomHttpClient.client;

  /// Récupère les randonnées dans un rayon donné
  ///
  /// [latitude] : Latitude du point central
  /// [longitude] : Longitude du point central
  /// [radius] : Rayon de recherche en kilomètres (défaut: 20)
  /// [page] : Numéro de page (défaut: 1)
  /// [limit] : Nombre d'éléments par page (défaut: 100)
  Future<PaginatedHikesResponse?> getHikes({
    required double latitude,
    required double longitude,
    int radius = 20,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      if (_baseUrl == null) {
        return null;
      }

      // Construire l'URL avec les paramètres de query
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl/hike/hikes',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginatedHikesResponse.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Récupère les points d'intérêt dans un rayon donné
  ///
  /// [latitude] : Latitude du point central
  /// [longitude] : Longitude du point central
  /// [radius] : Rayon de recherche en kilomètres (défaut: 5)
  /// [page] : Numéro de page (défaut: 1)
  /// [limit] : Nombre d'éléments par page (défaut: 100)
  Future<PaginatedPOIResponse?> getPointsOfInterest({
    required double latitude,
    required double longitude,
    int radius = 5,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      if (_baseUrl == null) {
        return null;
      }

      // Construire l'URL avec les paramètres de query
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl/hike/pois',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginatedPOIResponse.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
