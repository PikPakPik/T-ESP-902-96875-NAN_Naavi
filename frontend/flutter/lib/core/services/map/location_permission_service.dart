import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as gl;

/// Service centralisé pour la gestion des permissions de localisation
/// Remplace _setupPermissionPositionTracking() dupliqué dans HomeMapExplorerPage et MapView
class LocationPermissionService {
  /// Vérifie et demande les permissions de localisation
  ///
  /// Lance des exceptions typées en cas d'échec :
  /// - [LocationServiceDisabledException] : Service GPS désactivé
  /// - [LocationPermissionDeniedException] : Permission refusée
  /// - [LocationPermissionDeniedForeverException] : Permission refusée définitivement
  static Future<void> checkAndRequestPermissions() async {
    // Vérifier si le service de localisation est activé
    bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw LocationServiceDisabledException('Location service disabled');
    }

    // Vérifier les permissions
    gl.LocationPermission permission = await gl.Geolocator.checkPermission();

    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();

      if (permission == gl.LocationPermission.denied) {
        throw LocationPermissionDeniedException('Permission de localisation refusée');
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException('Permission de localisation refusée définitivement');
    }

    if (kDebugMode) {
    }
  }

  /// Vérifie si les permissions sont accordées sans les demander
  static Future<bool> hasPermissions() async {
    final permission = await gl.Geolocator.checkPermission();
    return permission == gl.LocationPermission.always ||
        permission == gl.LocationPermission.whileInUse;
  }

  /// Vérifie si le service de localisation est activé
  static Future<bool> isServiceEnabled() async {
    return await gl.Geolocator.isLocationServiceEnabled();
  }
}

/// Exception levée quand le service GPS est désactivé
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);

  @override
  String toString() => 'LocationServiceDisabledException: $message';
}

/// Exception levée quand la permission est refusée
class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);

  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

/// Exception levée quand la permission est refusée définitivement
class LocationPermissionDeniedForeverException implements Exception {
  final String message;
  LocationPermissionDeniedForeverException(this.message);

  @override
  String toString() => 'LocationPermissionDeniedForeverException: $message';
}
