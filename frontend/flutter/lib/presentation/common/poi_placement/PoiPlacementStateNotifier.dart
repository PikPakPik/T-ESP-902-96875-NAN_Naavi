import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../data/models/user_poi.dart';
import '../../../core/services/poi/poi_services.dart';
import '../../../core/services/user_poi_service.dart';
import '../../../core/utils/poi_type.dart';
import 'PoiPlacementState.dart';

/// Gère le processus de placement de POI sur la carte
/// Extrait de HomeMapExplorerPage (~400 lignes)
class PoiPlacementStateNotifier extends StateNotifier<PoiPlacementState> {
  final PoiService poiService;

  PoiPlacementStateNotifier({
    required this.poiService,
  }) : super(const PoiPlacementIdle());

  /// Ouvre la sélection de type de POI
  void openTypeSelection({
    bool isSignalement = false,
    bool isCategory = false,
  }) {
    state = PoiPlacementSelectingType(
      showPoiTypeSelection: !isSignalement && !isCategory,
      showReportTypeSelection: isSignalement,
      showPoiCategorySelection: isCategory,
    );
  }

  /// Ferme la sélection de type
  void closeTypeSelection() {
    state = const PoiPlacementIdle();
  }

  /// Démarre le placement après sélection du type
  void startPlacement(PoiType type, Position initialPosition) {
    state = PoiPlacementActive(
      selectedType: type,
      markerPosition: initialPosition,
    );
  }

  /// Met à jour la position du marqueur (drag ou tap)
  void updateMarkerPosition(Position position, [ScreenCoordinate? screenPosition]) {
    if (state is! PoiPlacementActive) return;

    final currentState = state as PoiPlacementActive;
    state = currentState.copyWith(
      markerPosition: position,
      markerScreenPosition: screenPosition,
    );
  }

  /// Sauvegarde le POI à la position actuelle
  Future<void> savePoi({
    required double latitude,
    required double longitude,
    String? customName,
  }) async {
    if (state is! PoiPlacementActive) return;

    final currentState = state as PoiPlacementActive;
    final type = currentState.selectedType;

    try {
      // État : sauvegarde en cours
      state = PoiPlacementSaving(
        type: type,
        position: Position(longitude, latitude),
      );

      // Générer un ID unique
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      // Créer le POI
      final poi = UserPOI(
        id: id,
        name: customName ?? type.name,
        type: type,
        latitude: latitude,
        longitude: longitude,
        description: '',
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans SharedPreferences
      await UserPoiService.savePOI(poi);

      // Ajouter à la liste de la randonnée (si en cours)
      poiService.addHikePoi(poi);

      // État : succès
      state = PoiPlacementSuccess(poi.id);

      // Retour à idle après un court délai
      await Future.delayed(const Duration(milliseconds: 500));
      state = const PoiPlacementIdle();
    } catch (e) {
      state = PoiPlacementError('Erreur lors de la sauvegarde du POI: $e');

      // Retour à idle après 2 secondes
      await Future.delayed(const Duration(seconds: 2));
      state = const PoiPlacementIdle();
    }
  }

  /// Annule le placement en cours
  void cancelPlacement() {
    state = const PoiPlacementIdle();
  }

  /// Vérifie si on est en train de placer un POI
  bool get isPlacing => state is PoiPlacementActive || state is PoiPlacementSaving;

  /// Vérifie si on est en sélection de type
  bool get isSelectingType => state is PoiPlacementSelectingType;
}
