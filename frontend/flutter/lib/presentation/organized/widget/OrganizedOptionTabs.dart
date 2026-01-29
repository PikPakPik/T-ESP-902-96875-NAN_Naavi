import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Onglets pour switcher entre les options
/// Affiche: bouton quit (X) | bouton back (<-) | tabs numériques | bouton +
class OrganizedOptionTabs extends StatelessWidget {
  final int currentIndex;
  final int totalOptions;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onQuit;
  final VoidCallback onBack;
  final VoidCallback? onAddOption;
  final bool canAddOption;

  const OrganizedOptionTabs({
    super.key,
    required this.currentIndex,
    required this.totalOptions,
    required this.onTabChanged,
    required this.onQuit,
    required this.onBack,
    this.onAddOption,
    this.canAddOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bouton quitter (X) à gauche
        GestureDetector(
          onTap: onQuit,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Bouton retour (<-) pour supprimer le dernier waypoint
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Tabs numériques alignés à gauche et scrollables
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(totalOptions, (index) {
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () => onTabChanged(index),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: EdgeInsets.only(
                      right: index < totalOptions - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.tertiaryColor
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Option ${index + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.secondaryColor
                              : Colors.white70,
                          fontFamily: 'Lexend Deca',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Bouton + à droite
        GestureDetector(
          onTap: canAddOption ? onAddOption : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: canAddOption
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add,
              color: canAddOption ? Colors.white : Colors.white38,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}