import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import '../../../core/services/tracking/camera_mode_service.dart';
import 'CameraState.dart';

/// Gère l'état de la caméra et les transitions entre modes
/// Extrait de HomeMapExplorerPage (~200 lignes)
class CameraStateNotifier extends StateNotifier<CameraState> {
  final CameraModeManager? cameraModeManager;

  CameraStateNotifier({this.cameraModeManager}) : super(const CameraInitial());

  /// Active le mode première personne
  Future<void> enableFirstPersonMode(gl.Position position) async {
    if (cameraModeManager == null) {
      return;
    }

    try {
      await cameraModeManager!.enableFirstPersonMode(position);
      state = CameraFirstPersonMode(
        currentPosition: position,
        isUserExploring: false,
      );
    } catch (e) {
      // En cas d'erreur, on reste en mode normal
      state = CameraNormalMode(currentPosition: position);
    }
  }

  /// Désactive le mode première personne
  Future<void> disableFirstPersonMode() async {
    if (cameraModeManager == null) {
      return;
    }

    try {
      await cameraModeManager!.disableFirstPersonMode();
      state = CameraNormalMode(currentPosition: state.currentPosition);
    } catch (e) {
      // Ignore l'erreur, on considère qu'on est en mode normal
    }
  }

  /// L'utilisateur commence à explorer manuellement (désactive le suivi auto)
  void setUserExploring(bool isExploring) {
    if (isExploring) {
      // Désactiver la rotation du compas quand l'utilisateur explore
      cameraModeManager?.disableCompassRotation();
      state = CameraUserExploring(
        isFirstPersonMode: state.isFirstPersonMode,
        currentPosition: state.currentPosition,
      );
    } else {
      // Réactiver la rotation du compas
      cameraModeManager?.enableCompassRotation();
      // Retour au mode automatique
      if (state.isFirstPersonMode && state.currentPosition != null) {
        state = CameraFirstPersonMode(
          currentPosition: state.currentPosition!,
          isUserExploring: false,
        );
      } else {
        state = CameraNormalMode(currentPosition: state.currentPosition);
      }
    }
  }

  /// Met à jour la position actuelle (appelé par le stream GPS)
  void updatePosition(gl.Position position) {
    final newState = switch (state) {
      CameraFirstPersonMode() => CameraFirstPersonMode(
        currentPosition: position,
        isUserExploring: state.isUserExploring,
      ),
      CameraUserExploring() => CameraUserExploring(
        isFirstPersonMode: state.isFirstPersonMode,
        currentPosition: position,
      ),
      CameraNormalMode() => CameraNormalMode(currentPosition: position),
      _ => state,
    };

    state = newState;
  }

  /// Recentre la caméra sur la position actuelle
  Future<void> recenter() async {
    if (state.currentPosition != null && state.isFirstPersonMode) {
      await enableFirstPersonMode(state.currentPosition!);
      setUserExploring(false);
    }
  }
}
