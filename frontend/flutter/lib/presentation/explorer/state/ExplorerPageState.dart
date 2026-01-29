import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// État de la page Explorer
/// Gère le cycle de vie et l'état de la carte principale
sealed class ExplorerPageState {
  const ExplorerPageState();
}

/// État initial - page non initialisée
class ExplorerPageInitial extends ExplorerPageState {
  const ExplorerPageInitial();
}

/// Initialisation en cours (permissions, GPS, routes)
class ExplorerPageInitializing extends ExplorerPageState {
  final String step;

  const ExplorerPageInitializing({this.step = 'Initialisation...'});
}

/// Page prête avec carte et position
class ExplorerPageReady extends ExplorerPageState {
  final MapboxMap mapController;
  final gl.Position? currentPosition;
  final bool hasCenteredOnInitialPosition;

  const ExplorerPageReady({
    required this.mapController,
    this.currentPosition,
    this.hasCenteredOnInitialPosition = false,
  });

  ExplorerPageReady copyWith({
    MapboxMap? mapController,
    gl.Position? currentPosition,
    bool? hasCenteredOnInitialPosition,
  }) {
    return ExplorerPageReady(
      mapController: mapController ?? this.mapController,
      currentPosition: currentPosition ?? this.currentPosition,
      hasCenteredOnInitialPosition:
          hasCenteredOnInitialPosition ?? this.hasCenteredOnInitialPosition,
    );
  }
}

/// Erreur lors de l'initialisation
class ExplorerPageError extends ExplorerPageState {
  final String message;
  final List<String> details;

  const ExplorerPageError({
    required this.message,
    this.details = const [],
  });
}
