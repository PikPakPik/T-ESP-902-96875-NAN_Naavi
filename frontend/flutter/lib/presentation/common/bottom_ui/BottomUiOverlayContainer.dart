import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/BottomUiProvider.dart';
import '../../guided/widget/navigation_info_card.dart';
import '../../../core/resources/colors.dart';
import '../../../core/di/MapProviders.dart';
import '../../../core/di/HomeMapProvider.dart';
import '../../../core/services/map/map_camera_service.dart';
import '../widget/action_buttons.dart';
import '../../map/state/MapServicesState.dart';

/// Widget orchestrateur pour les overlays de la zone UI bottom
/// Gère l'affichage des éléments qui peuvent coexister avec les états principaux
class BottomUiOverlayContainer extends ConsumerWidget {
  final VoidCallback? onCancelNavigation;
  final VoidCallback onOpenPoiTypeSelection;

  const BottomUiOverlayContainer({
    super.key,
    this.onCancelNavigation,
    required this.onOpenPoiTypeSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(bottomUiOverlayProvider);

    return Stack(
      children: [
        // Navigation Info Card (top)
        if (overlayState.showNavigationInfo &&
            overlayState.navigationDistanceKm != null)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: NavigationInfoCard(
              distanceKm: overlayState.navigationDistanceKm!,
              estimatedTimeMinutes: overlayState.navigationTimeMinutes,
              onClose: onCancelNavigation ?? () {},
              isNearStartPoint: overlayState.isNearStartPoint,
              onStartHike: overlayState.isNearStartPoint
                  ? () => _handleStartHike(ref)
                  : null,
            ),
          ),

        // Navigation Instruction Bar (top)
        if (overlayState.showNavigationInstructions &&
            overlayState.currentInstruction != null)
          Positioned(
            top: 140,
            left: 20,
            right: 20,
            child: _buildNavigationInstructionBar(
              overlayState.currentInstruction!,
              overlayState.distanceToNextPoint ?? 0,
            ),
          ),

        // Bouton de recentrage pendant navigation vers départ
        if (overlayState.showNavigationInfo)
          Positioned(
            bottom: 120,
            right: 20,
            child: CircleIconButton(
              onPressed: () => _handleRecenterDuringNavigation(ref),
              assetsPath: "assets/icons/location_icon.png",
              size: 50,
            ),
          ),

        // Bouton de recentrage pendant randonnée guidée
        if (overlayState.showNavigationInstructions)
          Positioned(
            bottom: 120,
            right: 20,
            child: CircleIconButton(
              onPressed: () => _handleRecenterDuringTracking(ref),
              assetsPath: "assets/icons/location_icon.png",
              size: 50,
            ),
          ),
      ],
    );
  }

  /// Recentre pendant la navigation vers le départ (vue normale)
  Future<void> _handleRecenterDuringNavigation(WidgetRef ref) async {
    final locationState = ref.read(locationStateProvider);
    final mapServices = ref.read(mapServicesProvider);
    final currentPosition = locationState.currentPosition;

    if (currentPosition == null || mapServices.mapboxMapController == null) {
      return;
    }

    await MapCameraService.moveToGeoPosition(
      mapServices.mapboxMapController!,
      position: currentPosition,
      zoom: 18.5, // Même zoom que le mode première personne
    );
  }

  /// Recentre pendant le tracking guidé (mode première personne)
  Future<void> _handleRecenterDuringTracking(WidgetRef ref) async {
    final locationState = ref.read(locationStateProvider);
    final cameraModeManager = ref.read(cameraModeManagerProvider);
    final trackingLocation = ref.read(trackingLocationProvider);
    final cameraNotifier = ref.read(cameraStateProvider.notifier);
    final currentPosition = locationState.currentPosition;

    if (currentPosition == null || cameraModeManager == null) {
      return;
    }

    await cameraModeManager.enableFirstPersonMode(currentPosition);
    trackingLocation.setUserExploring(false);
    cameraNotifier.setUserExploring(false);
  }

  /// Construit la barre d'instructions de navigation
  Widget _buildNavigationInstructionBar(String instruction, double distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.navigation, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend Deca',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (distance > 0)
                  Text(
                    '${distance.toStringAsFixed(0)} m',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Lexend Deca',
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gère le clic sur le bouton "Démarrer la randonnée"
  Future<void> _handleStartHike(WidgetRef ref) async {
    final mapServices = ref.read(mapServicesProvider);
    final mapboxMapController = mapServices.mapboxMapController;

    if (mapboxMapController == null) {
      return;
    }

    // Démarrer le tracking guidé depuis l'état "arrivé à proximité"
    await ref
        .read(hikeNavigationProvider.notifier)
        .startGuidedHikeFromNearStart(mapboxMapController);
  }
}
