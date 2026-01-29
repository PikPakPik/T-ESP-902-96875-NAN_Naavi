import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/domain/usecases/finishImproviseUseCase.dart';

import '../../presentation/common/recap/RecapHikeState.dart';
import '../../presentation/common/recap/RecapHikeStateNotifier.dart';
import '../services/statistics/statistics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

final poiService = Provider<PoiService>((ref) => PoiService());

final finishImproviseUseCaseProvider = Provider<FinishImproviseUseCase>((ref) {
  return FinishImproviseUseCase(
      statisticsService: ref.read(statisticsServiceProvider),
      poiService: ref.read(poiService));
});

final recapHikeProvider = StateNotifierProvider<RecapHikeStateNotifier, RecapHikeState>((ref) {
  final finishImproviseUseCase = ref.watch(finishImproviseUseCaseProvider);
  return RecapHikeStateNotifier(finishImproviseUseCase: finishImproviseUseCase);
});