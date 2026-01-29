/// État de la boussole pour la gestion du heading du device
/// Extrait de HomeMapExplorerPage pour isoler la logique de compass
sealed class CompassState {
  final double? currentHeading;
  final double? previousHeading;

  const CompassState({
    required this.currentHeading,
    required this.previousHeading,
  });
}

/// Aucune écoute de la boussole active
class CompassIdle extends CompassState {
  const CompassIdle()
      : super(
          currentHeading: null,
          previousHeading: null,
        );
}

/// Boussole active avec mises à jour du heading
class CompassActive extends CompassState {
  const CompassActive({
    required super.currentHeading,
    required super.previousHeading,
  });

  CompassActive copyWith({
    double? currentHeading,
    double? previousHeading,
  }) {
    return CompassActive(
      currentHeading: currentHeading ?? this.currentHeading,
      previousHeading: previousHeading ?? this.previousHeading,
    );
  }
}
