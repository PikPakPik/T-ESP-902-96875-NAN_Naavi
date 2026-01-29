import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider pour notifier les changements de POI
/// Permet de synchroniser les POI entre la page profil et la carte
final poiRefreshProvider = StateNotifierProvider<PoiRefreshNotifier, int>((ref) {
  return PoiRefreshNotifier();
});

class PoiRefreshNotifier extends StateNotifier<int> {
  PoiRefreshNotifier() : super(0);

  /// Déclenche un rafraîchissement des POI
  void refresh() {
    state = state + 1;
  }
}

