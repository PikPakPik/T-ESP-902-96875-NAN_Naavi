import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'MapControllerState.dart';

/// Gère le contrôleur de carte Mapbox et les interactions
/// Extrait de HomeMapExplorerPage (~150 lignes)
class MapControllerStateNotifier extends StateNotifier<MapControllerState> {
  Timer? _interactionTimer;

  MapControllerStateNotifier() : super(const MapControllerLoading());

  /// Initialise la carte après la création du widget Mapbox
  void onMapCreated(MapboxMap mapboxMap) {
    try {
      state = MapControllerReady(
        controller: mapboxMap,
        isMapReady: true,
      );
    } catch (e) {
      state = MapControllerError('Erreur lors de l\'initialisation de la carte: $e');
    }
  }

  /// Détecte le début d'une interaction utilisateur
  void onUserInteractionStart() {
    if (state is MapControllerReady) {
      final currentState = state as MapControllerReady;
      state = MapControllerInteracting(
        controller: currentState.controller,
        isUserInteracting: true,
      );
    }
  }

  /// Détecte la fin d'une interaction utilisateur (avec timer de 500ms)
  void onUserInteractionEnd() {
    // Annuler le timer précédent s'il existe
    _interactionTimer?.cancel();

    // Démarrer un nouveau timer pour détecter la fin de l'interaction
    _interactionTimer = Timer(const Duration(milliseconds: 500), () {
      if (state is MapControllerInteracting) {
        final currentState = state as MapControllerInteracting;
        state = MapControllerReady(
          controller: currentState.controller,
          isMapReady: true,
        );
      }
    });
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _interactionTimer?.cancel();
    super.dispose();
  }

  /// Récupère le contrôleur si disponible
  MapboxMap? get controller {
    return switch (state) {
      MapControllerReady(controller: final ctrl) => ctrl,
      MapControllerInteracting(controller: final ctrl) => ctrl,
      _ => null,
    };
  }

  /// Vérifie si la carte est prête
  bool get isReady => state is MapControllerReady || state is MapControllerInteracting;

  /// Vérifie si l'utilisateur interagit actuellement
  bool get isUserInteracting => state is MapControllerInteracting;
}
