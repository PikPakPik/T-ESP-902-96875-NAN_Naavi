import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/utils/poi_type.dart';

/// État du placement de POI sur la carte
/// Extrait de HomeMapExplorerPage pour isoler la logique de placement de POI
sealed class PoiPlacementState {
  const PoiPlacementState();
}

/// Aucun placement en cours
class PoiPlacementIdle extends PoiPlacementState {
  const PoiPlacementIdle();
}

/// Sélection du type de POI (bottom sheet)
class PoiPlacementSelectingType extends PoiPlacementState {
  final bool showPoiTypeSelection;
  final bool showReportTypeSelection;
  final bool showPoiCategorySelection;

  const PoiPlacementSelectingType({
    this.showPoiTypeSelection = false,
    this.showReportTypeSelection = false,
    this.showPoiCategorySelection = false,
  });

  PoiPlacementSelectingType copyWith({
    bool? showPoiTypeSelection,
    bool? showReportTypeSelection,
    bool? showPoiCategorySelection,
  }) {
    return PoiPlacementSelectingType(
      showPoiTypeSelection: showPoiTypeSelection ?? this.showPoiTypeSelection,
      showReportTypeSelection: showReportTypeSelection ?? this.showReportTypeSelection,
      showPoiCategorySelection: showPoiCategorySelection ?? this.showPoiCategorySelection,
    );
  }
}

/// Placement actif : marqueur draggable visible
class PoiPlacementActive extends PoiPlacementState {
  final PoiType selectedType;
  final Position? markerPosition; // Position GPS du marqueur
  final ScreenCoordinate? markerScreenPosition; // Position pixel du marqueur

  const PoiPlacementActive({
    required this.selectedType,
    this.markerPosition,
    this.markerScreenPosition,
  });

  PoiPlacementActive copyWith({
    PoiType? selectedType,
    Position? markerPosition,
    ScreenCoordinate? markerScreenPosition,
  }) {
    return PoiPlacementActive(
      selectedType: selectedType ?? this.selectedType,
      markerPosition: markerPosition ?? this.markerPosition,
      markerScreenPosition: markerScreenPosition ?? this.markerScreenPosition,
    );
  }
}

/// Sauvegarde du POI en cours
class PoiPlacementSaving extends PoiPlacementState {
  final PoiType type;
  final Position position;

  const PoiPlacementSaving({
    required this.type,
    required this.position,
  });
}

/// POI sauvegardé avec succès
class PoiPlacementSuccess extends PoiPlacementState {
  final String poiId;

  const PoiPlacementSuccess(this.poiId);
}

/// Erreur lors du placement/sauvegarde
class PoiPlacementError extends PoiPlacementState {
  final String message;

  const PoiPlacementError(this.message);
}
