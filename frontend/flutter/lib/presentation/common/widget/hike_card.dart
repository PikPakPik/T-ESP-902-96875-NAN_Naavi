import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Carte réutilisable pour afficher les informations d'une randonnée
/// Correspond au design de la carte de recherche avec image, statistiques et icônes
class HikeCard extends StatelessWidget {
  /// URL ou asset de l'image principale de la randonnée
  final String? imageUrl;

  /// URL ou asset de la miniature de carte (affichée en overlay sur l'image)
  final String? mapThumbnailUrl;

  /// Titre de la randonnée (peut être sur plusieurs lignes)
  final String title;

  /// Localisation de la randonnée (ex: "Nantes - Pays de la Loire")
  final String location;

  /// Note de la randonnée (ex: 4.8)
  final double? rating;

  /// Distance de la randonnée (ex: "18km")
  final String? distance;

  /// Difficulté de la randonnée (ex: "Facile", "Moyen", "Difficile")
  final String? difficulty;

  /// Élévation de la randonnée (ex: "120m")
  final String? elevation;

  /// Nombre d'avertissements/points d'attention
  final int? warningsCount;

  /// Nombre de photos disponibles
  final int? photosCount;

  /// Nombre de points d'eau
  final int? waterPointsCount;

  /// Nombre de parkings disponibles
  final int? parkingCount;

  /// Nombre de personnes ayant fait cette randonnée
  final int? toiletsCount;

  /// Callback appelé lors du clic sur la carte
  final VoidCallback? onTap;

  /// Largeur de la carte (par défaut 157)
  final double? width;

  const HikeCard({
    super.key,
    this.imageUrl,
    this.mapThumbnailUrl,
    required this.title,
    required this.location,
    this.rating,
    this.distance,
    this.difficulty,
    this.elevation,
    this.warningsCount,
    this.photosCount,
    this.waterPointsCount,
    this.parkingCount,
    this.toiletsCount,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 199,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section image avec overlay de carte
            _buildImageSection(),
            // Section informations textuelles
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image principale
        Container(
          height: 135,
          decoration: BoxDecoration(
            color: AppColors.tertiaryColor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImagePlaceholder(),
                  ),
                )
              : _buildImagePlaceholder(),
        ),
        // Miniature de carte en overlay (bas gauche)
        if (mapThumbnailUrl != null)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              width: 50,
              height: 35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  mapThumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.map, size: 18),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.image,
        size: 48,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre (toujours 2 lignes pour uniformiser la hauteur)
          SizedBox(
            height: 32, // Hauteur fixe pour 2 lignes (13px * 2 + line height)
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2, // Line height
              ),
              maxLines: 2,

              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          // Localisation
          Text(
            location,
            style: TextStyle(
              fontFamily: 'Lexend Deca',
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          // Statistiques principales (note, distance, difficulté, élévation)
          _buildMainStats(),
          const SizedBox(height: 4),
          // Icônes avec compteurs
          _buildIconStats(),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    final List<Widget> stats = [];

    // Note
    if (rating != null) {
      stats.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 3),
            Text(
              rating!.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    // Distance
    if (distance != null) {
      if (stats.isNotEmpty) {
        stats.add(
          Text(
            ' - ',
            style: TextStyle(
              fontFamily: 'Lexend Deca',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        );
      }
      stats.add(
        Text(
          distance!,
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    // Difficulté
    if (difficulty != null) {
      if (stats.isNotEmpty) {
        stats.add(
          Text(
            ' - ',
            style: TextStyle(
              fontFamily: 'Lexend Deca',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        );
      }
      stats.add(
        Text(
          difficulty!,
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    // Élévation
    if (elevation != null) {
      if (stats.isNotEmpty) {
        stats.add(
          Text(
            ' - ',
            style: TextStyle(
              fontFamily: 'Lexend Deca',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        );
      }
      stats.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.landscape, size: 14, color: Colors.white),
            const SizedBox(width: 1),
            Text(
              elevation!,
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(spacing: 0, children: stats);
  }

  Widget _buildIconStats() {
    final List<Widget> iconStats = [];

    // Avertissements
    if (warningsCount != null && warningsCount! > 0) {
      iconStats.add(_buildIconStat(Icons.warning, warningsCount!));
    }

    // Photos
    if (photosCount != null && photosCount! > 0) {
      iconStats.add(_buildIconStat(Icons.camera_alt, photosCount!));
    }

    // Points d'eau
    if (waterPointsCount != null && waterPointsCount! > 0) {
      iconStats.add(_buildIconStat(Icons.water_drop, waterPointsCount!));
    }

    // Parking
    if (parkingCount != null && parkingCount! > 0) {
      iconStats.add(_buildIconStat(Icons.local_parking, parkingCount!));
    }

    // Randonneurs
    if (toiletsCount != null && toiletsCount! > 0) {
      iconStats.add(_buildIconStat(Icons.wc, toiletsCount!));
    }

    if (iconStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 15, runSpacing: 3, children: iconStats);
  }

  Widget _buildIconStat(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
