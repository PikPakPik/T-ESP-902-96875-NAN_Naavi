import 'package:flutter/material.dart';

/// Section des points d'intérêt
class POISection extends StatelessWidget {
  final Map<String, int> counts;

  const POISection({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Colonne gauche
        Expanded(
          child: Column(
            children: [
              _POIItem(category: 'PARKING', count: counts['PARKING'] ?? 0),
              const SizedBox(height: 16),
              _POIItem(
                category: 'MUST_SEE_SPOT',
                count: counts['MUST_SEE_SPOT'] ?? 0,
              ),
            ],
          ),
        ),
        // Ligne verticale de séparation
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.white.withValues(alpha: 0.3),
        ),
        // Colonne droite
        Expanded(
          child: Column(
            children: [
              _POIItem(category: 'WATER', count: counts['WATER'] ?? 0),
              const SizedBox(height: 16),
              _POIItem(category: 'TOILET', count: counts['TOILET'] ?? 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _POIItem extends StatelessWidget {
  final String category;
  final int count;

  const _POIItem({required this.category, required this.count});

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'PARKING':
        return 'Parking';
      case 'TOILET':
        return 'Toilette';
      case 'WATER':
        return 'Point d\'eau';
      case 'MUST_SEE_SPOT':
      case 'MONUMENT':
        return 'Signalement';
      default:
        return category;
    }
  }

  Widget _getPOIIcon(String category) {
    Widget imageWidget;
    switch (category) {
      case 'PARKING':
        imageWidget = Image.asset(
          'assets/icons/report/parking.png',
          width: 32,
          height: 32,
        );
        break;
      case 'WATER':
        imageWidget = Image.asset(
          'assets/icons/poi/water.png',
          width: 32,
          height: 32,
        );
        break;
      case 'TOILET':
        imageWidget = Image.asset(
          'assets/icons/poi/toilets.png',
          width: 32,
          height: 32,
        );
        break;
      case 'MUST_SEE_SPOT':
        imageWidget = Image.asset(
          'assets/icons/report/hazard.png',
          width: 32,
          height: 32,
        );
        break;
      default:
        return const Icon(Icons.place, color: Colors.white, size: 32);
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icône
        _getPOIIcon(category),
        const SizedBox(width: 12),
        // Label et count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getCategoryDisplayName(category),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lexend Deca',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lexend Deca',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
