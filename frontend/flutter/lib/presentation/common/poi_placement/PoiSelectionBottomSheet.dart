import 'package:flutter/material.dart';
import '../../../core/utils/poi_type.dart';

/// Bottom sheet de sélection du type de POI
/// Extrait de HomeMapExplorerPage (~150 lignes)
///
/// Structure :
/// 1. Choix initial : Signalements vs Points d'intérêt
/// 2. Grille de types spécifiques
class PoiSelectionBottomSheet {
  /// Affiche le choix initial : Signalements ou Points d'intérêt
  static Future<String?> showInitialChoice(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color.fromRGBO(36, 25, 19, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Que souhaitez-vous placer ?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildChoiceButton(
              context,
              'Signalements',
              'Dangers, passages inaccessibles',
              Icons.warning_amber_rounded,
              Colors.orange,
              'signalement',
            ),
            const SizedBox(height: 12),
            _buildChoiceButton(
              context,
              'Points d\'intérêt',
              'Parkings, toilettes, eau, camping',
              Icons.place_rounded,
              Colors.blue,
              'poi',
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche la grille de types de signalements
  static Future<PoiType?> showReportTypes(BuildContext context) {
    final types = [PoiType.hazard];
    return _showTypeGrid(context, 'Signalements', types);
  }

  /// Affiche la grille de types de POI
  static Future<PoiType?> showPoiTypes(BuildContext context) {
    final types = [
      PoiType.parking,
      PoiType.toilets,
      PoiType.water,
      PoiType.camping,
      PoiType.animals,
    ];
    return _showTypeGrid(context, 'Points d\'intérêt', types);
  }

  /// Grille de sélection de type
  static Future<PoiType?> _showTypeGrid(
    BuildContext context,
    String title,
    List<PoiType> types,
  ) {
    return showModalBottomSheet<PoiType>(
      context: context,
      backgroundColor: const Color.fromRGBO(36, 25, 19, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: types.length,
              itemBuilder: (context, index) {
                return _buildTypeCard(context, types[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton de choix initial
  static Widget _buildChoiceButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String choice,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, choice),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  /// Carte de type de POI
  static Widget _buildTypeCard(BuildContext context, PoiType type) {
    return InkWell(
      onTap: () => Navigator.pop(context, type),
      child: Container(
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: type.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            type.icon(size: 32),
            const SizedBox(height: 8),
            Text(
              type.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
