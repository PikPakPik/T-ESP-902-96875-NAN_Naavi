import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// État du contrôleur de carte Mapbox
/// Extrait de HomeMapExplorerPage pour isoler la logique de carte
sealed class MapControllerState {
  const MapControllerState();
}

/// Carte en cours d'initialisation
class MapControllerLoading extends MapControllerState {
  const MapControllerLoading();
}

/// Carte prête à être utilisée
class MapControllerReady extends MapControllerState {
  final MapboxMap controller;
  final bool isMapReady;

  const MapControllerReady({
    required this.controller,
    this.isMapReady = true,
  });

  MapControllerReady copyWith({
    MapboxMap? controller,
    bool? isMapReady,
  }) {
    return MapControllerReady(
      controller: controller ?? this.controller,
      isMapReady: isMapReady ?? this.isMapReady,
    );
  }
}

/// Erreur lors de l'initialisation de la carte
class MapControllerError extends MapControllerState {
  final String message;

  const MapControllerError(this.message);
}

/// L'utilisateur interagit avec la carte (zoom, pan, etc.)
class MapControllerInteracting extends MapControllerState {
  final MapboxMap controller;
  final bool isUserInteracting;

  const MapControllerInteracting({
    required this.controller,
    this.isUserInteracting = true,
  });
}
