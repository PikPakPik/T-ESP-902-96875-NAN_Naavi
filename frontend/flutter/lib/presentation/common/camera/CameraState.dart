import 'package:geolocator/geolocator.dart' as gl;

/// État de la caméra et de la vue première personne
/// Extrait de HomeMapExplorerPage pour isoler la logique de caméra
sealed class CameraState {
  final bool isFirstPersonMode;
  final bool isUserExploring;
  final gl.Position? currentPosition;

  const CameraState({
    required this.isFirstPersonMode,
    required this.isUserExploring,
    this.currentPosition,
  });
}

/// État initial : caméra en mode normal
class CameraInitial extends CameraState {
  const CameraInitial()
    : super(isFirstPersonMode: false, isUserExploring: false);
}

/// Caméra en mode première personne (suivi GPS actif)
class CameraFirstPersonMode extends CameraState {
  const CameraFirstPersonMode({
    required super.currentPosition,
    required super.isUserExploring,
  }) : super(isFirstPersonMode: true);
}

/// Caméra en mode normal (vue de dessus)
class CameraNormalMode extends CameraState {
  const CameraNormalMode({super.currentPosition})
    : super(isFirstPersonMode: false, isUserExploring: false);
}

/// L'utilisateur explore manuellement (désactive le suivi auto)
class CameraUserExploring extends CameraState {
  const CameraUserExploring({
    required super.isFirstPersonMode,
    super.currentPosition,
  }) : super(isUserExploring: true);
}
