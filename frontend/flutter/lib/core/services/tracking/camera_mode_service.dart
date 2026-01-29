import 'package:geolocator/geolocator.dart' as gl;
import 'camera_handler_service.dart';
import 'compass_service.dart';

class CameraModeManager {
  final CameraHandlerService _cameraService;
  final CompassService _compassService;

  bool _isFirstPersonMode = false;

  /// Indique si la rotation du compas est active
  /// Désactivée quand l'utilisateur interagit avec la carte (zoom/pan)
  bool _isCompassRotationEnabled = false;

  gl.Position? _currentPosition;

  CameraModeManager({
    required CameraHandlerService cameraService,
    required CompassService compassService,
  }) : _cameraService = cameraService,
       _compassService = compassService {
    _compassService.onHeadingChanged = _onHeadingChanged;
  }

  bool get isFirstPersonMode => _isFirstPersonMode;
  bool get isCompassRotationEnabled => _isCompassRotationEnabled;

  Future<void> enableFirstPersonMode(gl.Position position) async {
    _currentPosition = position;
    _isFirstPersonMode = true;
    _isCompassRotationEnabled = true; // Activer la rotation du compas

    // Démarrer l'écoute du compas immédiatement
    _compassService.startListening();

    // Attendre un heading fiable du compas (avec timeout court)
    final heading = await _compassService.getStableHeading();

    // Animation fluide directement vers la bonne orientation
    await _cameraService.enableFirstPersonModeSmooth(position, heading);
  }

  Future<void> disableFirstPersonMode() async {
    _isFirstPersonMode = false;
    _isCompassRotationEnabled = false;
    _compassService.stopListening();

    if (_currentPosition != null) {
      await _cameraService.resetToNormalView(_currentPosition!);
    }
  }

  Future<void> enableExploreMode() async {
    _isFirstPersonMode = false;
    _isCompassRotationEnabled =
        false; // Désactiver la rotation quand l'utilisateur explore
    _compassService.stopListening();
  }

  /// Désactive la rotation du compas (quand l'utilisateur zoome/dézoome/pan)
  void disableCompassRotation() {
    _isCompassRotationEnabled = false;
  }

  /// Réactive la rotation du compas (après recentrage)
  void enableCompassRotation() {
    _isCompassRotationEnabled = true;
  }

  void updateCurrentPosition(gl.Position position) {
    _currentPosition = position;
  }

  void _onHeadingChanged(double heading) {
    // Mettre à jour le bearing SEULEMENT si la rotation du compas est activée
    if (_isFirstPersonMode &&
        _isCompassRotationEnabled &&
        _currentPosition != null) {
      _cameraService.updateBearing(heading);
    }
  }

  Future<void> updateCamera(gl.Position position) async {
    updateCurrentPosition(position);

    if (_isFirstPersonMode) {
      final heading = _compassService.currentHeading ?? 0.0;
      // Utiliser des mises à jour instantanées pour éviter les saccades
      await _cameraService.enableFirstPersonMode(
        position,
        heading,
        duration: 0, // Pas d'animation pour éviter les saccades
      );
    } else {
      await _cameraService.updatePosition(position);
    }
  }

  void dispose() {
    _compassService.dispose();
  }
}
