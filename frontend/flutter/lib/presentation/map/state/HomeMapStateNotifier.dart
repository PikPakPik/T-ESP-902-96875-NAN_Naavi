// presentation/state/HomeMapStateNotifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'HomeMapState.dart';

class HomeMapStateNotifier extends StateNotifier<HomeMapState> {
  HomeMapStateNotifier() : super(HomeMapState.explore);

  void updateState(HomeMapState newState) {
    state = newState;
  }
}

final homeMapStateProvider = StateNotifierProvider<HomeMapStateNotifier, HomeMapState>((ref) {
  return HomeMapStateNotifier();
});
