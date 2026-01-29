import 'package:geolocator/geolocator.dart' as gl;
import 'dart:async';
import 'package:flutter/foundation.dart';

class LocationService {
  gl.Position? _currentPosition;
  StreamSubscription<gl.Position>? _positionSub;

  final void Function(gl.Position position)? onPositionChanged;

  LocationService({this.onPositionChanged});

  gl.Position? get currentPosition => _currentPosition;

  Future<gl.Position?> getCurrentPosition() async {
    try {

      // Vérifier d'abord si les services de localisation sont activés
      bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      // Vérifier les permissions
      gl.LocationPermission permission = await gl.Geolocator.checkPermission();

      if (permission == gl.LocationPermission.denied) {
        permission = await gl.Geolocator.requestPermission();

        if (permission == gl.LocationPermission.denied) {
          return null;
        }
      }

      if (permission == gl.LocationPermission.deniedForever) {
        return null;
      }

      // Récupérer la position avec un timeout
      _currentPosition = await gl.Geolocator.getCurrentPosition(
        locationSettings: const gl.LocationSettings(
          accuracy: gl.LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('GPS timeout');
        },
      );

      if (kDebugMode) {
      }
      return _currentPosition;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }

  /// Démarre le suivi de position
  void startTracking({int distanceFilter = 5}) {
    // Annuler le tracking précédent si existe
    _positionSub?.cancel();

    _positionSub = gl.Geolocator.getPositionStream(
      locationSettings: gl.LocationSettings(
        accuracy: gl.LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        _currentPosition = position;
        onPositionChanged?.call(position);
        if (kDebugMode) {
        }
      },
      onError: (error) {
        // Gérer les erreurs du stream de position
        if (kDebugMode) {
        }
        // Ne pas crash l'app, juste logger l'erreur
        // Le GPS peut avoir des erreurs temporaires (perte de signal, etc.)
      },
      cancelOnError: false, // Continue d'écouter même après une erreur
    );

    if (kDebugMode) {
    }
  }

  /// Arrête le suivi de position
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void dispose() {
    stopTracking();
  }
}