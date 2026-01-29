import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import '../../models/location_state.dart';

class LocationStateNotifier extends StateNotifier<LocationState> {
  StreamSubscription<gl.Position>? _positionSub;

  LocationStateNotifier() : super(const LocationState());

  /// Vérifie et demande les permissions (une seule fois)
  Future<bool> requestPermissions() async {
    try {
      final serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(error: 'Location services disabled');
        return false;
      }

      gl.LocationPermission permission = await gl.Geolocator.checkPermission();

      if (permission == gl.LocationPermission.denied) {
        permission = await gl.Geolocator.requestPermission();

        if (permission == gl.LocationPermission.denied) {
          state = state.copyWith(error: 'Location permissions denied');
          return false;
        }
      }

      if (permission == gl.LocationPermission.deniedForever) {
        state = state.copyWith(error: 'Location permissions denied forever');
        return false;
      }

      state = state.copyWith(hasPermission: true, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Démarre le tracking GPS
  Future<void> startTracking() async {
    if (state.isTracking) {
      return;
    }

    // Demander les permissions si pas encore fait
    if (!state.hasPermission) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    // Démarrer le stream
    _positionSub?.cancel();
    _positionSub =
        gl.Geolocator.getPositionStream(
          locationSettings: const gl.LocationSettings(
            accuracy: gl.LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
          (position) {
            // Mise à jour automatique de l'état → déclenche les listeners !
            state = state.copyWith(currentPosition: position);
            if (kDebugMode) {}
          },
          onError: (error) {
            state = state.copyWith(error: error.toString());
          },
          cancelOnError: false,
        );

    state = state.copyWith(isTracking: true);
  }

  /// Arrête le tracking GPS
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    state = state.copyWith(isTracking: false);
  }

  /// Récupère la position actuelle (one-shot)
  Future<gl.Position?> getCurrentPosition() async {
    if (!state.hasPermission) {
      final granted = await requestPermissions();
      if (!granted) return null;
    }

    try {
      // Essayer d'abord la dernière position connue (instantané)
      try {
        final lastKnown = await gl.Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          // Vérifier que la position n'est pas trop ancienne (< 30 secondes)
          final age = DateTime.now().difference(lastKnown.timestamp);
          if (age.inSeconds < 30) {
            state = state.copyWith(currentPosition: lastKnown);
            return lastKnown;
          } else {}
        }
      } catch (e) {
        // Cache read errors are silently ignored
      }

      // Si pas de cache ou trop ancien, récupérer une nouvelle position

      final position =
          await gl.Geolocator.getCurrentPosition(
            locationSettings: const gl.LocationSettings(
              accuracy: gl.LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () async {
              // Fallback avec précision medium si timeout
              return await gl.Geolocator.getCurrentPosition(
                locationSettings: const gl.LocationSettings(
                  accuracy: gl.LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 3),
                ),
              );
            },
          );

      state = state.copyWith(currentPosition: position);
      return position;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
