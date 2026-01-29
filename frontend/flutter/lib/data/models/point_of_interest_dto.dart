/// DTO pour les points d'intérêt depuis l'API
class PointOfInterestDto {
  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final List<String> categories;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PointOfInterestDto({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PointOfInterestDto.fromJson(Map<String, dynamic> json) {
    return PointOfInterestDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      categories: (json['categories'] as List).map((c) => c as String).toList(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Réponse paginée pour les points d'intérêt
class PaginatedPOIResponse {
  final List<PointOfInterestDto> items;
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int? nextPage;
  final int? previousPage;

  PaginatedPOIResponse({
    required this.items,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    this.nextPage,
    this.previousPage,
  });

  factory PaginatedPOIResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedPOIResponse(
      items: (json['items'] as List)
          .map(
            (item) => PointOfInterestDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalItems: json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      nextPage: json['nextPage'] as int?,
      previousPage: json['previousPage'] as int?,
    );
  }
}
