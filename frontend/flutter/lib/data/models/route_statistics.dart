/// Statistiques calculées pour un itinéraire organisé
/// Inclut distance, temps, dénivelé et POI à proximité
class RouteStatistics {
  final double distanceKm;
  final int elevationGainM; // Dénivelé positif
  final Duration estimatedDuration;
  final int dangerCount;
  final int waterPointCount;
  final int signageCount;
  final int poiCount;

  RouteStatistics({
    required this.distanceKm,
    required this.elevationGainM,
    required this.estimatedDuration,
    this.dangerCount = 0,
    this.waterPointCount = 0,
    this.signageCount = 0,
    this.poiCount = 0,
  });

  /// Formatte la distance pour l'affichage
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toInt()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Formatte la durée pour l'affichage
  String get formattedDuration {
    final hours = estimatedDuration.inHours;
    final minutes = estimatedDuration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}min';
  }

  /// Copie avec modifications
  RouteStatistics copyWith({
    double? distanceKm,
    int? elevationGainM,
    Duration? estimatedDuration,
    int? dangerCount,
    int? waterPointCount,
    int? signageCount,
    int? poiCount,
  }) {
    return RouteStatistics(
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      dangerCount: dangerCount ?? this.dangerCount,
      waterPointCount: waterPointCount ?? this.waterPointCount,
      signageCount: signageCount ?? this.signageCount,
      poiCount: poiCount ?? this.poiCount,
    );
  }
}