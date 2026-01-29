/// DTO pour les partenaires
class PartnerDto {
  final int id;
  final String name;
  final String category;
  final String address;
  final String? testimonial;
  final String? logoUrl;
  final String? logoText; // Texte à afficher dans le logo si pas d'image

  PartnerDto({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.testimonial,
    this.logoUrl,
    this.logoText,
  });

  factory PartnerDto.fromJson(Map<String, dynamic> json) {
    return PartnerDto(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      address: json['address'] as String,
      testimonial: json['testimonial'] as String?,
      logoUrl: json['logoUrl'] as String?,
      logoText: json['logoText'] as String?,
    );
  }
}
