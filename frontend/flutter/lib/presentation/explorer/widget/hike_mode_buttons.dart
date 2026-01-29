import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map/state/HomeMapState.dart';
import '../../../core/di/StorageHikingProvider.dart';
import '../../../core/di/MapProviders.dart';
import '../../map/state/MapControllerState.dart';
import '../../common/widget/action_buttons.dart';
import '../../map/state/HomeMapStateNotifier.dart';
import '../../common/poi_placement/PoiSelectionBottomSheet.dart';
import '../../../core/di/HomeMapProvider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show Position;

/// Widget affichant les boutons de sélection de mode de randonnée
/// Remplace les lignes 986-1011 de HomeMapExplorerPage.dart
///
/// Affiche deux boutons :
/// - "Organiser ma propre randonnée" : Passe en mode organized
/// - "Partir à l'improviste" : Démarre le mode improvisation
class HikeModeButtons extends ConsumerWidget {
  const HikeModeButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 50.0, right: 50.0, bottom: 54.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          // Boutons POI et Signalement côte à côte
          Row(
            children: [
              Expanded(
                child: _buildIconButton(
                  context: context,
                  ref: ref,
                  icon: Icons.place_rounded,
                  iconColor: Colors.blue,
                  text: "POI",
                  onPressed: () => _openPoiSelection(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildIconButton(
                  context: context,
                  ref: ref,
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.orange,
                  text: "Signalement",
                  onPressed: () => _openReportSelection(context, ref),
                ),
              ),
            ],
          ),

          // Boutons existants
          LargeButton(
            onPressed: () {
              ref.read(homeMapStateProvider.notifier).updateState(HomeMapState.organise);
              ref.read(organizedHikeProvider.notifier).startNewOption();
            },
            text: "Organiser ma propre randonnée",
            //disabled: true,
          ),
          LargeButton(
            onPressed: () async {
              await _startImprovising(ref);
            },
            text: "Partir à l'improviste",
          ),
        ],
      ),
    );
  }

  /// Construit un bouton avec icône
  Widget _buildIconButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Lexend Deca',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre le bottom sheet de sélection de POI
  Future<void> _openPoiSelection(BuildContext context, WidgetRef ref) async {
    final selectedType = await PoiSelectionBottomSheet.showPoiTypes(context);

    if (selectedType != null) {
      final currentPosition = ref.read(locationStateProvider).currentPosition;
      if (currentPosition != null) {
        ref
            .read(poiPlacementProvider.notifier)
            .startPlacement(
              selectedType,
              Position(currentPosition.longitude, currentPosition.latitude),
            );
      } else {}
    }
  }

  /// Ouvre le bottom sheet de sélection de signalement
  Future<void> _openReportSelection(BuildContext context, WidgetRef ref) async {
    final selectedType = await PoiSelectionBottomSheet.showReportTypes(context);

    if (selectedType != null) {
      final currentPosition = ref.read(locationStateProvider).currentPosition;
      if (currentPosition != null) {
        ref
            .read(poiPlacementProvider.notifier)
            .startPlacement(
              selectedType,
              Position(currentPosition.longitude, currentPosition.latitude),
            );
      } else {}
    }
  }

  /// Démarre le mode improvisation
  Future<void> _startImprovising(WidgetRef ref) async {
    // Read all notifiers and states BEFORE any async operations
    // to avoid using ref after widget disposal
    final homeMapNotifier = ref.read(homeMapStateProvider.notifier);
    final isMapReady = ref.read(isMapReadyProvider);
    final mapControllerState = ref.read(mapControllerProvider);
    final improviseNotifier = ref.read(improviseHikeProvider.notifier);
    final storageNotifier = ref.read(storageHikingProvider.notifier);
    final cameraNotifier = ref.read(cameraStateProvider.notifier);
    final locationStateNotifier = ref.read(locationStateProvider.notifier);

    // S'assurer que le tracking GPS est démarré
    if (!ref.read(locationStateProvider).isTracking) {
      await locationStateNotifier.startTracking();
      // Attendre seulement si aucune position n'est disponible
      if (ref.read(locationStateProvider).currentPosition == null) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // Changer l'état de la carte
    homeMapNotifier.updateState(HomeMapState.improvise);

    // Temporairement activer le suivi pour le centrage initial
    // Sera désactivé par ImproviseHikeStateNotifier après le centrage
    cameraNotifier.setUserExploring(false);

    // Vérifier que la carte est prête
    if (mapControllerState is MapControllerReady) {
      // Démarrer l'improvisation via le provider
      await improviseNotifier.startHike(
        mapboxMap: mapControllerState.controller,
        isMapReady: isMapReady,
      );

      // Garder la rotation du compas active après le centrage initial
      // isUserExploring = false signifie que le bouton "Recentrer" n'apparaît pas
      // car l'utilisateur n'a pas encore bougé la carte manuellement
      cameraNotifier.setUserExploring(false);
    }

    // Démarrer le tracking via le storage provider
    storageNotifier.startHike();

    // Démarrer la boussole pour le mode première personne
    ref.read(compassProvider.notifier).startListening();
  }
}
