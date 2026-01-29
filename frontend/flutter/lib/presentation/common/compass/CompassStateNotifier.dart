import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'CompassState.dart';

/// Gère l'écoute de la boussole et les mises à jour du heading
/// Extrait de HomeMapExplorerPage (~40 lignes)
class CompassStateNotifier extends StateNotifier<CompassState> {
  final double headingThreshold; // Seuil de changement significatif en degrés
  final void Function(double heading)? onHeadingChanged;

  StreamSubscription<CompassEvent>? _compassSubscription;

  CompassStateNotifier({this.headingThreshold = 5.0, this.onHeadingChanged})
    : super(const CompassIdle());

  /// Démarre l'écoute de la boussole
  void startListening() {
    if (_compassSubscription != null) {
      return;
    }

    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading == null) return;

      final currentState = state;
      final newHeading = event.heading!;

      // Premier événement : initialiser
      if (currentState is CompassIdle) {
        state = CompassActive(
          currentHeading: newHeading,
          previousHeading: newHeading,
        );
        onHeadingChanged?.call(newHeading);
        return;
      }

      // États suivants : vérifier le seuil
      if (currentState is CompassActive) {
        final previousHeading = currentState.previousHeading;
        if (previousHeading == null) return;

        // Seulement si le changement est significatif (> seuil)
        final headingDiff = (newHeading - previousHeading).abs();
        if (headingDiff > headingThreshold) {
          state = currentState.copyWith(
            currentHeading: newHeading,
            previousHeading: newHeading,
          );
          onHeadingChanged?.call(newHeading);
        }
      }
    });
  }

  /// Arrête l'écoute de la boussole
  void stopListening() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    state = const CompassIdle();
  }

  /// Vérifie si la boussole est en écoute
  bool get isListening => state is CompassActive;

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
