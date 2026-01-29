/// DTO pour les randonnées depuis l'API
class HikeDto {
  final int id;
  final String name;
  final double startingPointLatitude;
  final double startingPointLongitude;
  final int startingElevation;
  final double arrivalPointLatitude;
  final double arrivalPointLongitude;
  final int arrivalElevation;
  final String? wkbGeometry;
  final String? wkbWaypoints;
  final int distance;
  final int duration;
  final String location;
  final HikeDifficulty difficulty;
  final HikeStatus status;
  final List<HikeSeason> seasons;
  final HikeSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  HikeDto({
    required this.id,
    required this.name,
    required this.startingPointLatitude,
    required this.startingPointLongitude,
    required this.startingElevation,
    required this.arrivalPointLatitude,
    required this.arrivalPointLongitude,
    required this.arrivalElevation,
    this.wkbGeometry,
    this.wkbWaypoints,
    required this.distance,
    required this.duration,
    required this.location,
    required this.difficulty,
    required this.status,
    required this.seasons,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HikeDto.fromJson(Map<String, dynamic> json) {
    return HikeDto(
      id: json['id'] as int,
      name: json['name'] as String,
      startingPointLatitude: (json['startingPointLatitude'] as num).toDouble(),
      startingPointLongitude: (json['startingPointLongitude'] as num)
          .toDouble(),
      startingElevation: json['startingElevation'] as int,
      arrivalPointLatitude: (json['arrivalPointLatitude'] as num).toDouble(),
      arrivalPointLongitude: (json['arrivalPointLongitude'] as num).toDouble(),
      arrivalElevation: json['arrivalElevation'] as int,
      wkbGeometry: json['wkbGeometry'] as String?,
      wkbWaypoints: json['wkbWaypoints'] as String?,
      distance: json['distance'] as int,
      duration: json['duration'] as int,
      location: json['location'] as String,
      difficulty: HikeDifficulty.fromString(json['difficulty'] as String),
      status: HikeStatus.fromString(json['status'] as String),
      seasons: (json['seasons'] as List)
          .map((s) => HikeSeason.fromString(s as String))
          .toList(),
      source: HikeSource.fromString(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Retourne la durée formatée (ex: "2h 30min" ou "45min")
  String get formattedDuration {
    if (duration <= 0) {
      return '?';
    }

    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}min';
      } else {
        return '${hours}h';
      }
    } else {
      return '${minutes}min';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startingPointLatitude': startingPointLatitude,
      'startingPointLongitude': startingPointLongitude,
      'startingElevation': startingElevation,
      'arrivalPointLatitude': arrivalPointLatitude,
      'arrivalPointLongitude': arrivalPointLongitude,
      'arrivalElevation': arrivalElevation,
      'wkbGeometry': wkbGeometry,
      'wkbWaypoints': wkbWaypoints,
      'distance': distance,
      'duration': duration,
      'location': location,
      'difficulty': difficulty.value,
      'status': status.value,
      'seasons': seasons.map((s) => s.value).toList(),
      'source': source.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

enum HikeDifficulty {
  easy('EASY'),
  medium('MEDIUM'),
  hard('HARD');

  final String value;
  const HikeDifficulty(this.value);

  static HikeDifficulty fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EASY':
        return HikeDifficulty.easy;
      case 'MEDIUM':
        return HikeDifficulty.medium;
      case 'HARD':
        return HikeDifficulty.hard;
      default:
        return HikeDifficulty.easy;
    }
  }
}

enum HikeStatus {
  draft('DRAFT'),
  unpublished('UNPUBLISHED'),
  published('PUBLISHED'),
  deleted('DELETED');

  final String value;
  const HikeStatus(this.value);

  static HikeStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return HikeStatus.draft;
      case 'UNPUBLISHED':
        return HikeStatus.unpublished;
      case 'PUBLISHED':
        return HikeStatus.published;
      case 'DELETED':
        return HikeStatus.deleted;
      default:
        return HikeStatus.published;
    }
  }
}

enum HikeSeason {
  spring('SPRING'),
  summer('SUMMER'),
  fall('FALL'),
  winter('WINTER');

  final String value;
  const HikeSeason(this.value);

  static HikeSeason fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SPRING':
        return HikeSeason.spring;
      case 'SUMMER':
        return HikeSeason.summer;
      case 'FALL':
        return HikeSeason.fall;
      case 'WINTER':
        return HikeSeason.winter;
      default:
        return HikeSeason.spring;
    }
  }
}

enum HikeSource {
  official('OFFICIAL'),
  community('COMMUNITY');

  final String value;
  const HikeSource(this.value);

  static HikeSource fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OFFICIAL':
        return HikeSource.official;
      case 'COMMUNITY':
        return HikeSource.community;
      default:
        return HikeSource.official;
    }
  }
}

/// Réponse paginée pour les randonnées
class PaginatedHikesResponse {
  final List<HikeDto> items;
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int? nextPage;
  final int? previousPage;

  PaginatedHikesResponse({
    required this.items,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    this.nextPage,
    this.previousPage,
  });

  factory PaginatedHikesResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedHikesResponse(
      items: (json['items'] as List)
          .map((item) => HikeDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      nextPage: json['nextPage'] as int?,
      previousPage: json['previousPage'] as int?,
    );
  }
}
