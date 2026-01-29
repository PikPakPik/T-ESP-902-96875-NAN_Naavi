import 'dart:async';

import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Service pour gérer la caméra Mapbox avec différents modes de vue
class CameraHandlerService {
  final MapboxMap _mapboxMap;
  Function(bool isUserInteracting)? onUserInteractionChanged;

  Timer? _interactionTimer;

  // Constantes de configuration pour le mode première personne (style Waze)
  static const double _firstPersonZoom = 17.0;
  static const double _firstPersonPitch = 55.0;
  static const int _firstPersonPaddingTop = 200; // Padding du haut
  static const int _firstPersonPaddingBottom =
      450; // Compensation pour le panneau du bas
  static const int _firstPersonAnimationDuration =
      600; // Durée pour l'activation initiale (réduite pour fluidité)

  // Constantes pour la vue normale
  static const double _normalZoom = 15.0;
  static const int _normalAnimationDuration = 600;

  // Constantes pour la mise à jour de position
  static const double _updatePositionZoom = 17.0;

  CameraHandlerService({required MapboxMap mapboxMap}) : _mapboxMap = mapboxMap;

  /// Padding pour le mode première personne (point GPS visible au-dessus du panneau)
  MbxEdgeInsets get _firstPersonPadding => MbxEdgeInsets(
    top: _firstPersonPaddingTop.toDouble(),
    left: 0,
    bottom: _firstPersonPaddingBottom.toDouble(),
    right: 0,
  );

  /// Déplace la caméra vers une position avec des paramètres personnalisables
  Future<void> moveTo(
    gl.Position position, {
    double zoom = _normalZoom,
    double pitch = 0.0,
    double bearing = 0.0,
    int duration = _normalAnimationDuration,
    MbxEdgeInsets? padding,
  }) async {
    await _mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
        padding: padding,
      ),
      MapAnimationOptions(duration: duration, startDelay: 0),
    );
  }

  /// Active le mode première personne (vue inclinée avec point GPS en bas)
  Future<void> enableFirstPersonMode(
    gl.Position position,
    double heading, {
    double zoom = _firstPersonZoom,
    double pitch = _firstPersonPitch,
    int duration = _firstPersonAnimationDuration,
  }) async {
    await moveTo(
      position,
      zoom: zoom,
      pitch: pitch,
      bearing: heading,
      duration: duration,
      padding: _firstPersonPadding,
    );
  }

  /// Active le mode première personne instantanément sans animation
  Future<void> enableFirstPersonModeInstant(
    gl.Position position,
    double heading, {
    double zoom = _firstPersonZoom,
    double pitch = _firstPersonPitch,
  }) async {
    await _mapboxMap.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: zoom,
        pitch: pitch,
        bearing: heading,
        padding: _firstPersonPadding,
      ),
    );
  }

  /// Active le mode première personne avec une animation courte et fluide
  Future<void> enableFirstPersonModeSmooth(
    gl.Position position,
    double heading, {
    double zoom = _firstPersonZoom,
    double pitch = _firstPersonPitch,
  }) async {
    await _mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: zoom,
        pitch: pitch,
        bearing: heading,
        padding: _firstPersonPadding,
      ),
      MapAnimationOptions(duration: 500, startDelay: 0),
    );
  }

  /// Active le mode première personne SANS changer le bearing
  /// Le bearing sera mis à jour par le compas ensuite
  /// Animation fluide et naturelle (400ms)
  Future<void> enableFirstPersonModeWithoutBearing(
    gl.Position position, {
    double zoom = _firstPersonZoom,
    double pitch = _firstPersonPitch,
  }) async {
    // Récupérer le bearing actuel de la caméra
    final currentCamera = await _mapboxMap.getCameraState();
    final currentBearing = currentCamera.bearing;

    // Animation fluide et naturelle pour une transition douce
    await _mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: zoom,
        pitch: pitch,
        bearing: currentBearing, // Garder le bearing actuel
        padding: _firstPersonPadding,
      ),
      MapAnimationOptions(duration: 400, startDelay: 0),
    );
  }

  /// Met à jour uniquement le bearing (orientation) en préservant le padding
  /// Utilise setCamera pour des mises à jour instantanées ultra-fluides
  Future<void> updateBearing(double bearing) async {
    try {
      await _mapboxMap.setCamera(
        CameraOptions(bearing: bearing, padding: _firstPersonPadding),
      );
    } catch (e) {
      // Silently ignore camera update errors
    }
  }

  /// Réinitialise la caméra en vue normale (vue de dessus)
  Future<void> resetToNormalView(
    gl.Position position, {
    double zoom = _normalZoom,
    int duration = _normalAnimationDuration,
  }) async {
    await moveTo(
      position,
      zoom: zoom,
      pitch: 0.0,
      bearing: 0.0,
      duration: duration,
    );
  }

  /// Met à jour la position de la caméra (sans animation de pitch/bearing)
  /// Utilise setCamera pour des mises à jour instantanées sans saccades
  Future<void> updatePosition(
    gl.Position position, {
    double zoom = _updatePositionZoom,
  }) async {
    await _mapboxMap.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: zoom,
      ),
    );
  }

  /// Récupère l'état actuel de la caméra
  Future<CameraState> getCurrentCamera() async {
    return await _mapboxMap.getCameraState();
  }

  /// Notifie que l'utilisateur a commencé à interagir avec la carte
  void onUserInteractionStart() {
    onUserInteractionChanged?.call(true);

    _interactionTimer?.cancel();

    _interactionTimer = Timer(const Duration(milliseconds: 500), () {
      onUserInteractionChanged?.call(false);
    });
  }

  /// Notifie que l'utilisateur a terminé d'interagir avec la carte
  void onUserInteractionEnd() {
    _interactionTimer?.cancel();
    onUserInteractionChanged?.call(false);
  }

  /// Nettoie les ressources
  void dispose() {
    _interactionTimer?.cancel();
  }
}
