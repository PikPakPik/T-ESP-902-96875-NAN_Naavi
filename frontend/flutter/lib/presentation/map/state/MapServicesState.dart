// presentation/state/MapServicesState.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapServicesState {
  final gl.Position? currentPosition;
  final MapboxMap? mapboxMapController;
  final bool isMapReady;
  final bool isFirstPersonMode;

  MapServicesState({
    this.currentPosition,
    this.mapboxMapController,
    this.isMapReady = false,
    this.isFirstPersonMode = false,
  });

  MapServicesState copyWith({
    gl.Position? currentPosition,
    MapboxMap? mapboxMapController,
    bool? isMapReady,
    bool? isFirstPersonMode,
  }) {
    return MapServicesState(
      currentPosition: currentPosition ?? this.currentPosition,
      mapboxMapController: mapboxMapController ?? this.mapboxMapController,
      isMapReady: isMapReady ?? this.isMapReady,
      isFirstPersonMode: isFirstPersonMode ?? this.isFirstPersonMode,
    );
  }
}

class MapServicesNotifier extends StateNotifier<MapServicesState> {
  MapServicesNotifier() : super(MapServicesState());

  void setCurrentPosition(gl.Position position) {
    state = state.copyWith(currentPosition: position);
  }

  void setMapController(MapboxMap controller) {
    state = state.copyWith(mapboxMapController: controller, isMapReady: true);
  }

  void setFirstPersonMode(bool isFirstPersonMode) {
    state = state.copyWith(isFirstPersonMode: isFirstPersonMode);
  }
}

final mapServicesProvider = StateNotifierProvider<MapServicesNotifier, MapServicesState>((ref) {
  return MapServicesNotifier();
});
