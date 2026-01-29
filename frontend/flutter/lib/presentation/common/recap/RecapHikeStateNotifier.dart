import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/domain/usecases/finishImproviseUseCase.dart';
import 'package:geolocator/geolocator.dart' as gl;

import 'RecapHikeState.dart';

class RecapHikeStateNotifier extends StateNotifier<RecapHikeState> {
  final FinishImproviseUseCase finishImproviseUseCase;

  RecapHikeStateNotifier({required this.finishImproviseUseCase}): super (const RecapHikeStateLoading());

  Future<void> getFinalHike(List<List<gl.Position>> segments, {Duration? duration}) async {
    try {
      state = const RecapHikeStateLoading();
      final fetchedHike = finishImproviseUseCase.buildFinalHike(segments, duration: duration);
      state = RecapHikeStateHikeFetched(fetchedHike);
    } catch (e) {
      state = RecapHikeStateError(e.toString());
    }
  }
}