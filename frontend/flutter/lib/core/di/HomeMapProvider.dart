import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tracking/location_service.dart';
import '../services/tracking/tracking_location_service.dart';
import '../models/location_state.dart';
import '../services/tracking/location_state_notifier.dart';

// Provider singleton pour TrackingLocationService
// keepAlive = true signifie que l'instance ne sera jamais détruite
final trackingLocationProvider = Provider<TrackingLocationService>((ref) {
  final service = TrackingLocationService();

  // Garder le service en vie même si plus personne ne l'utilise
  ref.keepAlive();

  // Optionnel: logger la création
  if (kDebugMode) {
  }

  return service;
});

/// Provider d'état GPS (StateNotifier) - NOUVEAU
/// Remplace locationServiceProvider pour une meilleure réactivité Riverpod
final locationStateProvider =
    StateNotifierProvider<LocationStateNotifier, LocationState>((ref) {
      return LocationStateNotifier();
    });

// Provider singleton pour LocationService - DEPRECATED
// Utiliser locationStateProvider à la place
@Deprecated('Utiliser locationStateProvider à la place')
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();

  // Garder le service en vie
  ref.keepAlive();

  // Ne PAS démarrer automatiquement le tracking ici
  // Le tracking sera démarré après l'obtention des permissions
  // dans GpsTrackingService ou après la demande de permissions

  if (kDebugMode) {
  }

  return service;
});
