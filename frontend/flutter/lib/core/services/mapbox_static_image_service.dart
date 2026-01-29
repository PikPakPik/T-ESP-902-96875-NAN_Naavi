import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/models/hike_dto.dart';
import '../utils/utils.dart';

/// Service pour générer des URLs de cartes statiques Mapbox
class MapboxStaticImageService {
  static const String _baseUrl =
      'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/static';

  /// Génère une URL de carte statique Mapbox pour le tracé de la randonnée
  ///
  /// Retourne null si le token Mapbox n'est pas disponible ou si le wkbGeometry est null
  static String? generateHikeThumbnailUrl(
    HikeDto hike, {
    int width = 199,
    int height = 135,
  }) {
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (accessToken == null || hike.wkbGeometry == null) {
      return null;
    }

    try {
      // Décoder le WKB en LineString
      final lineString = decodeWKBFromString(hike.wkbGeometry!);

      if (lineString.chain.positionCount == 0) {
        // Si pas de points, utiliser une carte centrée sur le point de départ
        return _generateCenteredMapUrl(
          hike.startingPointLongitude,
          hike.startingPointLatitude,
          width: width,
          height: height,
        );
      }

      // Extraire les coordonnées [lon, lat]
      final coordinates = <List<double>>[];
      for (int i = 0; i < lineString.chain.positionCount; i++) {
        final pos = lineString.chain[i];
        coordinates.add([pos.x, pos.y]);
      }

      // Encoder en polyline
      final encodedPolyline = _encodePolyline(coordinates);

      // Encoder l'URL (percent-encoding)
      final encodedPath = Uri.encodeComponent(encodedPolyline);

      // Créer l'overlay path avec style (largeur 4px, couleur verte primaire, opacité 0.8)
      // Utilisation de la couleur secondaire (vert foncé #324943) pour le tracé
      final pathOverlay = 'path-4+324943-0.8($encodedPath)';

      // Utiliser "auto" pour centrer automatiquement sur le tracé
      return '$_baseUrl/$pathOverlay/auto/${width}x$height?access_token=$accessToken';
    } catch (e) {
      // En cas d'erreur, retourner une carte centrée sur le point de départ
      return _generateCenteredMapUrl(
        hike.startingPointLongitude,
        hike.startingPointLatitude,
        width: width,
        height: height,
      );
    }
  }

  /// Génère une URL de carte statique centrée sur des coordonnées
  static String? _generateCenteredMapUrl(
    double longitude,
    double latitude, {
    int zoom = 13,
    int width = 199,
    int height = 135,
  }) {
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (accessToken == null) {
      return null;
    }

    return '$_baseUrl/$longitude,$latitude,$zoom,0/${width}x$height?access_token=$accessToken';
  }

  /// Encode une liste de coordonnées en polyline (algorithme Google Maps/Mapbox)
  ///
  /// Les coordonnées doivent être au format [longitude, latitude]
  static String _encodePolyline(List<List<double>> coordinates) {
    if (coordinates.isEmpty) return '';

    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLon = 0;

    for (final coord in coordinates) {
      final lat = (coord[1] * 1e5).round();
      final lon = (coord[0] * 1e5).round();

      final dLat = lat - prevLat;
      final dLon = lon - prevLon;

      _encodeValue(buffer, dLat);
      _encodeValue(buffer, dLon);

      prevLat = lat;
      prevLon = lon;
    }

    return buffer.toString();
  }

  /// Encode une valeur pour le polyline
  static void _encodeValue(StringBuffer buffer, int value) {
    var encoded = value < 0 ? ~(value << 1) : value << 1;
    while (encoded >= 0x20) {
      buffer.writeCharCode((0x20 | (encoded & 0x1f)) + 63);
      encoded >>= 5;
    }
    buffer.writeCharCode(encoded + 63);
  }
}
