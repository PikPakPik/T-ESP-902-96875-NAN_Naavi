import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Bouton flottant pour activer le mode drag & drop de destination
/// Apparaît quand la bottom sheet est minimisée en mode sélection
class OrganizedDestinationDragButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final String? customText; // Texte personnalisé pour l'instruction

  const OrganizedDestinationDragButton({
    super.key,
    required this.isVisible,
    this.onTap,
    this.onDismiss,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: isVisible ? 1.0 : 0.8,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !isVisible,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenu principal de la popup
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône de drag
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.touch_app,
                        color: AppColors.secondaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Texte d'instruction
                    Text(
                      customText != null ? customText! : 'Touchez la carte\npour choisir votre destination',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lexend Deca',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Indicateur pour toucher un POI
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ou sélectionnez un POI',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Lexend Deca',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bouton de fermeture (croix)
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
