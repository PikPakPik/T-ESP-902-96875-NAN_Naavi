import 'package:geolocator/geolocator.dart' as gl;

/// État de la randonnée en mode improvisation (randonnée libre)
/// Extrait de HomeMapExplorerPage pour isoler la logique d'improvise mode
sealed class ImproviseHikeState {
  const ImproviseHikeState();
}

/// Aucune randonnée improvisation en cours
class ImproviseHikeIdle extends ImproviseHikeState {
  const ImproviseHikeIdle();
}

/// Démarrage de la randonnée en cours (activation GPS, caméra, etc.)
class ImproviseHikeStarting extends ImproviseHikeState {
  const ImproviseHikeStarting();
}

/// Randonnée improvisation active
class ImproviseHikeActive extends ImproviseHikeState {
  final gl.Position startPoint;
  final DateTime startTime;
  final Duration accumulatedTime; // Temps accumulé avant la dernière pause
  final DateTime? pausedAt; // Timestamp de pause (null si pas en pause)

  const ImproviseHikeActive({
    required this.startPoint,
    required this.startTime,
    this.accumulatedTime = Duration.zero,
    this.pausedAt,
  });

  /// Calcule le temps écoulé en tenant compte des pauses
  Duration get elapsedTime {
    if (pausedAt != null) {
      // En pause : retourner le temps accumulé
      return accumulatedTime;
    }
    // En cours : temps accumulé + temps depuis la dernière reprise
    final timeSinceLastResume = DateTime.now().difference(startTime);
    return accumulatedTime + timeSinceLastResume - _getInitialOffset();
  }

  Duration _getInitialOffset() {
    // Si on a du temps accumulé, startTime a été mis à jour à la reprise
    if (accumulatedTime > Duration.zero) {
      return Duration.zero;
    }
    return Duration.zero;
  }

  /// Crée un état en pause
  ImproviseHikeActive pause() {
    return ImproviseHikeActive(
      startPoint: startPoint,
      startTime: startTime,
      accumulatedTime: elapsedTime, // Sauvegarde le temps actuel
      pausedAt: DateTime.now(),
    );
  }

  /// Crée un état repris après une pause
  ImproviseHikeActive resume() {
    return ImproviseHikeActive(
      startPoint: startPoint,
      startTime: DateTime.now(), // Nouveau point de départ pour le calcul
      accumulatedTime: accumulatedTime, // Garde le temps accumulé
      pausedAt: null, // Plus en pause
    );
  }

  bool get isPaused => pausedAt != null;
}

/// Randonnée improvisation terminée (prête pour le récapitulatif)
class ImproviseHikeFinished extends ImproviseHikeState {
  final gl.Position startPoint;
  final gl.Position? endPoint;
  final DateTime startTime;
  final DateTime endTime;
  final List<List<gl.Position>> segments;
  final double distanceKm;
  final Duration duration; // Durée calculée correctement avec les pauses

  const ImproviseHikeFinished({
    required this.startPoint,
    this.endPoint,
    required this.startTime,
    required this.endTime,
    required this.segments,
    required this.distanceKm,
    required this.duration,
  });
}

/// Erreur lors du démarrage de la randonnée
class ImproviseHikeError extends ImproviseHikeState {
  final String message;
  final List<String> reasons;

  const ImproviseHikeError({required this.message, this.reasons = const []});
}
