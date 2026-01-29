import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/core/resources/typography.dart';
import '../../../core/resources/colors.dart';
import '../../../core/di/MapProviders.dart';
import '../../../core/di/HomeMapProvider.dart';

/// Bottom sheet pour sélectionner le point de départ d'une option
class OrganizedStartSelectionSheet extends ConsumerWidget {
  final VoidCallback onClose;

  const OrganizedStartSelectionSheet({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationStateProvider);
    final currentPosition = locationState.currentPosition;

    // Vérifier si on a la position GPS
    final hasLocation = currentPosition != null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            Center(
              child: Text(
                'Sélectionner un point de départ sur la carte pour commencer votre aventure',
                style: AppTypography.body1.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("ou", style: AppTypography.body2.copyWith(color: AppColors.white)),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Boutons de sélection
            Row(
              children: [
                Expanded(
                  child: _buildLocationChoiceButton(
                    context: context,
                    ref: ref,
                    hasLocation: hasLocation,
                    buttonText: 'Placer manuellement',
                    icon: Icons.location_on,
                    onTap: () => ref.read(organizedHikeProvider.notifier).startManualStartSelection(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLocationChoiceButton(
                    context: context,
                    ref: ref,
                    hasLocation: hasLocation,
                    buttonText: 'Position actuelle',
                    icon: Icons.my_location,
                    onTap: () => _handleUseCurrentLocation(ref),
                  ),
                ),
              ],
            ),



            // Message si pas de GPS
            if (!hasLocation)
              const SizedBox(height: 16),
            if (!hasLocation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[300],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Position GPS non disponible. Vérifiez vos paramètres.',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontFamily: 'Lexend Deca',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Bouton pour utiliser la position actuelle
  Widget _buildLocationChoiceButton({
    required BuildContext context,
    required WidgetRef ref,
    bool? hasLocation = false,
    required String buttonText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              buttonText,
              style: AppTypography.body2.copyWith(
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Gère l'utilisation de la position actuelle
  Future<void> _handleUseCurrentLocation(WidgetRef ref) async {
    final currentPosition = ref.read(locationStateProvider).currentPosition;

    if (currentPosition == null) {
      return;
    }

    // Définir le point de départ
    await ref
        .read(organizedHikeProvider.notifier)
        .setStartPointFromCurrentLocation(currentPosition);
  }
}