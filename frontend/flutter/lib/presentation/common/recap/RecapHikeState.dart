import '../../../data/models/improvise_hike.dart';

sealed class RecapHikeState {
  const RecapHikeState();
}

class RecapHikeStateLoading extends RecapHikeState {
  const RecapHikeStateLoading();
}

class RecapHikeStateHikeFetched extends RecapHikeState {
  final ImproviseHike hike;
  const RecapHikeStateHikeFetched(this.hike);
}

class RecapHikeStateHikeNotFetched extends RecapHikeState {
  const RecapHikeStateHikeNotFetched();
}

class RecapHikeStateError extends RecapHikeState {
  final String message;
  const RecapHikeStateError(this.message);
}
