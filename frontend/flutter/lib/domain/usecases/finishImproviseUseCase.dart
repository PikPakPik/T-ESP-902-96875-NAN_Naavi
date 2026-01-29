import 'package:geolocator/geolocator.dart' as gl;
import 'package:naavi/data/models/improvise_hike.dart';
import 'package:naavi/core/services/poi/poi_services.dart';
import 'package:naavi/core/services/statistics/statistics_service.dart';

class FinishImproviseUseCase {
  final StatisticsService statisticsService;
  final PoiService poiService;

  FinishImproviseUseCase({
    required this.statisticsService,
    required this.poiService,
  });

  ImproviseHike buildFinalHike(
    List<List<gl.Position>> segments, {
    Duration? duration,
  }) {
    // Utiliser la durée passée en paramètre si disponible, sinon celle du statisticsService
    var finalTime = duration;
    if (finalTime == null || finalTime == Duration.zero) {
      finalTime = statisticsService.getFinalTime() ?? Duration.zero;
    }

    var finalDistance = statisticsService.calculateTotalDistance(segments);
    var elevationData = statisticsService.calculateElevationGain(segments);

    var poiTypes = poiService.getPoiTypesImproviseHike();
    var pois = poiService.getHikePois(); // Récupérer la liste complète des POI

    ImproviseHike hike = ImproviseHike(
      distance: finalDistance.toString(),
      finalTime: finalTime,
      poiTypes: poiTypes,
      pois: pois,
      elevationGainPositive: elevationData['positive'],
      elevationGainNegative: elevationData['negative'],
    );

    return hike;
  }
}
