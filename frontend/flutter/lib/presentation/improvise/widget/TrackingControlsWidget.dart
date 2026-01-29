import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/resources/colors.dart';
import '../state/StorageHikingState.dart';
import '../../common/widget/TextButton.dart';

/// Widget des contrôles de tracking pendant une randonnée improvisée
/// Extrait de HomeMapExplorerPage (~200 lignes)
///
/// Affiche :
/// - Bouton "Finish"
/// - Bouton "Pause" / "Reprendre" (selon état)
/// - Bouton de recentrage (icône localisation)
/// - Bouton d'ajout de POI
class TrackingControlsWidget extends ConsumerWidget {
  final VoidCallback onFinish;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRecenter;
  final VoidCallback onAddPoi;
  final StorageHikingState hikingState;
  final String? Function()? locationIconAssetPath;

  const TrackingControlsWidget({
    super.key,
    required this.onFinish,
    required this.onPause,
    required this.onResume,
    required this.onRecenter,
    required this.onAddPoi,
    required this.hikingState,
    this.locationIconAssetPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 24,
      left: 28,
      child: Row(
        children: [
          // Bouton Finish
          actionButton(
            isLoading: false,
            onPressed: onFinish,
            text: "Finish",
          ),

          // Bouton Pause / Reprendre (switch selon état)
          _buildPauseResumeButton(),

          const SizedBox(width: 8),

          // Bouton recentrage
          _circleIconButton(
            onRecenter,
            locationIconAssetPath?.call() ?? "assets/icons/location_icon.png",
            40,
          ),

          const SizedBox(width: 8),

          // Bouton ajout POI
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onAddPoi,
              icon: const Icon(
                Icons.add_location_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton pause/reprendre qui change selon l'état
  Widget _buildPauseResumeButton() {
    return switch (hikingState) {
      StorageHikingStateIdle() => actionButton(
          isLoading: false,
          onPressed: () {},
        ),
      StorageHikingStateTracking() => actionButton(
          isLoading: false,
          onPressed: onPause,
          text: "Pause",
        ),
      StorageHikingStateLoading() => actionButton(
          isLoading: true,
        ),
      StorageHikingStatePaused() => actionButton(
          isLoading: false,
          onPressed: onResume,
          text: "Reprendre",
        ),
      StorageHikingStateError() => actionButton(
          isLoading: false,
          onPressed: () {},
          text: "Réessayer",
        ),
      StorageHikingStateSyncronized() => actionButton(
          isLoading: false,
          onPressed: () {},
          text: "OK",
        ),
    };
  }

  /// Bouton circulaire avec icône
  Widget _circleIconButton(VoidCallback? onPressed, String assetPath, double size) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromRGBO(36, 25, 19, 1),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: size * 0.5,
            height: size * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
