import 'package:geolocator/geolocator.dart' as gl;
import '../../../core/utils/poi_type.dart';
import '../../organized/state/OrganizedHikeState.dart';

/// État unifié pour la zone UI bottom de HomeMapExplorerPage
/// Utilise une sealed class pour garantir l'exhaustivité des cas
sealed class BottomUiState {
  const BottomUiState();
}

/// État initial - aucun widget affiché en bottom
class BottomUiIdle extends BottomUiState {
  const BottomUiIdle();
}

/// Affiche le popup de détail d'une randonnée
class BottomUiShowingHikeDetail extends BottomUiState {
  final Map<String, dynamic> hikeInfo;
  final double? distanceToStart;
  final bool isNearby;

  const BottomUiShowingHikeDetail({
    required this.hikeInfo,
    this.distanceToStart,
    required this.isNearby,
  });
}

/// Affiche le popup de suivi de randonnée guidée
class BottomUiShowingGuidedTracking extends BottomUiState {
  final int elapsedSeconds;
  final double distanceKm;
  final bool isPaused;
  final String currentDirection;
  final double distanceToNextWaypointMeters;
  final double currentSpeedKmh; // Vitesse actuelle en km/h
  final double elevationM; // Dénivelé cumulé en mètres
  final double averageSpeedKmh; // Vitesse moyenne en km/h
  final double currentAltitudeM; // Altitude actuelle en mètres

  const BottomUiShowingGuidedTracking({
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.isPaused,
    required this.currentDirection,
    required this.distanceToNextWaypointMeters,
    this.currentSpeedKmh = 0.0,
    this.elevationM = 0.0,
    this.averageSpeedKmh = 0.0,
    this.currentAltitudeM = 0.0,
  });
}

/// Affiche les boutons de sélection de mode (organiser/improviser)
class BottomUiShowingHikeModeButtons extends BottomUiState {
  const BottomUiShowingHikeModeButtons();
}

/// Affiche les contrôles de randonnée improvisée
class BottomUiShowingImproviseControls extends BottomUiState {
  final gl.Position? currentPosition;

  const BottomUiShowingImproviseControls({this.currentPosition});
}

/// Affiche le récapitulatif de fin de randonnée
class BottomUiShowingRecap extends BottomUiState {
  final List<List<gl.Position>> segments;
  final bool fromGuidedHike;
  final Duration? duration; // Durée calculée correctement avec les pauses

  const BottomUiShowingRecap({
    required this.segments,
    required this.fromGuidedHike,
    this.duration,
  });
}

/// Affiche le dialogue de placement de POI
class BottomUiPlacingPoi extends BottomUiState {
  final PoiType selectedType;
  final double initialLatitude;
  final double initialLongitude;

  const BottomUiPlacingPoi({
    required this.selectedType,
    required this.initialLatitude,
    required this.initialLongitude,
  });
}

// Ajouter un nouvel état pour organized mode
class BottomUiShowingOrganizedHike extends BottomUiState {
  final OrganizedHikeState organizedState;

  const BottomUiShowingOrganizedHike({required this.organizedState});
}

/// États overlay (peuvent coexister avec les états principaux)
class BottomUiOverlayState {
  final bool showNavigationInfo;
  final double? navigationDistanceKm;
  final double? navigationTimeMinutes;

  final bool showNavigationInstructions;
  final String? currentInstruction;
  final double? distanceToNextPoint;

  final bool showPoiButton;

  final bool showStartHikeButton;
  final bool isNearStartPoint;

  const BottomUiOverlayState({
    this.showNavigationInfo = false,
    this.navigationDistanceKm,
    this.navigationTimeMinutes,
    this.showNavigationInstructions = false,
    this.currentInstruction,
    this.distanceToNextPoint,
    this.showPoiButton = false,
    this.showStartHikeButton = false,
    this.isNearStartPoint = false,
  });

  BottomUiOverlayState copyWith({
    bool? showNavigationInfo,
    double? navigationDistanceKm,
    double? navigationTimeMinutes,
    bool? showNavigationInstructions,
    String? currentInstruction,
    double? distanceToNextPoint,
    bool? showPoiButton,
    bool? showStartHikeButton,
    bool? isNearStartPoint,
  }) {
    return BottomUiOverlayState(
      showNavigationInfo: showNavigationInfo ?? this.showNavigationInfo,
      navigationDistanceKm: navigationDistanceKm ?? this.navigationDistanceKm,
      navigationTimeMinutes:
          navigationTimeMinutes ?? this.navigationTimeMinutes,
      showNavigationInstructions:
          showNavigationInstructions ?? this.showNavigationInstructions,
      currentInstruction: currentInstruction ?? this.currentInstruction,
      distanceToNextPoint: distanceToNextPoint ?? this.distanceToNextPoint,
      showPoiButton: showPoiButton ?? this.showPoiButton,
      showStartHikeButton: showStartHikeButton ?? this.showStartHikeButton,
      isNearStartPoint: isNearStartPoint ?? this.isNearStartPoint,
    );
  }
}
