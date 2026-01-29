import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Widget affichant un dégradé en bas de la carte
/// Remplace les lignes 646-664 de HomeMapExplorerPage.dart
///
/// Crée un effet visuel de transition entre la carte et les boutons du bas
class MapGradientOverlay extends StatelessWidget {
  const MapGradientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.primaryColor.withValues(alpha: 0.35),
              AppColors.primaryColor.withValues(alpha: 0.70),
            ],
            stops: const [0.0, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}
