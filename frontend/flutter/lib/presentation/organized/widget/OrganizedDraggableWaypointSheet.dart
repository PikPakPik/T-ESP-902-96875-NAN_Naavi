import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/resources/colors.dart';
import '../../../core/di/MapProviders.dart' show organizedSheetHeightProvider;
import '../../../data/models/organized_hike_option.dart';
import 'OrganizedWaypointSheet.dart';
import 'OrganizedOptionTabs.dart';

/// Wrapper draggable pour OrganizedWaypointSheet
/// Permet de réduire la sheet pour afficher plus de carte
class OrganizedDraggableWaypointSheet extends ConsumerStatefulWidget {
  final OrganizedHikeOption option;
  final bool canAddOption;
  final VoidCallback onAddDestination;
  final VoidCallback onSaveOption;
  final VoidCallback? onAddNewOption;
  final VoidCallback onClose;
  final VoidCallback onQuit;
  final VoidCallback onBack;
  final void Function(int insertAtIndex)? onInsertWaypoint;

  // Pour gérer les onglets
  final int totalOptions;
  final int currentOptionIndex;
  final ValueChanged<int> onTabChanged;

  // Pour gérer le mode minimisé (drag & drop)
  final bool isMinimizedForSelection;
  final VoidCallback? onSheetExpanded;

  const OrganizedDraggableWaypointSheet({
    super.key,
    required this.option,
    required this.canAddOption,
    required this.onAddDestination,
    required this.onSaveOption,
    this.onAddNewOption,
    required this.onClose,
    required this.onQuit,
    required this.onBack,
    this.onInsertWaypoint,
    required this.totalOptions,
    required this.currentOptionIndex,
    required this.onTabChanged,
    this.isMinimizedForSelection = false,
    this.onSheetExpanded,
  });

  @override
  ConsumerState<OrganizedDraggableWaypointSheet> createState() =>
      _OrganizedDraggableWaypointSheetState();
}

class _OrganizedDraggableWaypointSheetState
    extends ConsumerState<OrganizedDraggableWaypointSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  bool _isMinimized = false;

  // Constantes pour les tailles de sheet
  static const double _onlyOptionSize = 0.15;      // Juste les onglets
  static const double _startPointOnlySize = 0.55;  // Départ sélectionné
  static const double _startAndEndSize = 0.90;     // Départ + Destination
  static const double _fullSize = 0.95;            // Avec étapes intermédiaires
  static const double _minSize = 0.12;             // Taille minimum (< snapSizes)

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleSheetSizeChange);
    // Animer vers la taille cible après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.isAttached) {
        _controller.animateTo(
          _getTargetSize(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant OrganizedDraggableWaypointSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animer vers la nouvelle taille si le nombre de waypoints change
    if (oldWidget.option.waypoints.length != widget.option.waypoints.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.isAttached) {
          _controller.animateTo(
            _getTargetSize(),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Si on passe en mode minimisé pour sélection, animer vers le minimum
    if (widget.isMinimizedForSelection && !oldWidget.isMinimizedForSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.isAttached) {
          _controller.animateTo(
            _minSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSheetSizeChange);
    _controller.dispose();
    super.dispose();
  }

  /// Calcule la taille cible selon le nombre de waypoints
  double _getTargetSize() {
    final waypointCount = widget.option.waypoints.length;
    if (waypointCount == 0) return _onlyOptionSize;
    if (waypointCount == 1) return _startPointOnlySize;
    if (waypointCount == 2) return _startAndEndSize;
    return _fullSize; // 3+ waypoints
  }

  /// Retourne les snap points selon l'état actuel
  /// Note: snapSizes doit être entre minChildSize et maxChildSize (exclus)
  List<double> _getSnapPoints() {
    final target = _getTargetSize();
    // Ne retourner que la taille cible si elle est différente de min/max
    if (target > _minSize && target < _fullSize) {
      return [target];
    }
    // Sinon retourner une valeur intermédiaire
    return [0.5];
  }

  /// Détecte si la sheet est minimisée ou expandée
  void _handleSheetSizeChange() {
    if (!_controller.isAttached) return;

    final size = _controller.size;
    final shouldBeMinimized = size < 0.20; // Seuil à 20%

    if (shouldBeMinimized != _isMinimized) {
      setState(() {
        _isMinimized = shouldBeMinimized;
      });

      // Si on était en mode sélection minimisé et qu'on expand la sheet,
      // notifier le parent pour masquer le bouton drag & drop
      if (!shouldBeMinimized && widget.isMinimizedForSelection) {
        widget.onSheetExpanded?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapPoints = _getSnapPoints();

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Mettre à jour la hauteur en pixels
        final sheetHeight = notification.extent * MediaQuery.of(context).size.height;
        ref.read(organizedSheetHeightProvider.notifier).state = sheetHeight;
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: 0.5, // Taille initiale fixe
        minChildSize: _minSize,
        maxChildSize: _fullSize,
        snap: true,
        snapSizes: snapPoints,
        builder: (context, scrollController) {
          // Initialiser la hauteur au premier build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.isAttached) {
              final screenHeight = MediaQuery.of(context).size.height;
              ref.read(organizedSheetHeightProvider.notifier).state =
                  screenHeight * _controller.size;
            }
          });
          return Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zone draggable (barre grise + onglets)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (!_controller.isAttached) return;
                  final delta = details.primaryDelta ?? 0;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final newSize = _controller.size - (delta / screenHeight);
                  _controller.jumpTo(newSize.clamp(_minSize, _fullSize));
                },
                onVerticalDragEnd: (details) {
                  if (!_controller.isAttached) return;
                  final currentSize = _controller.size;
                  // Snap vers la position la plus proche
                  double closestSnap = snapPoints.first;
                  double minDistance = (currentSize - closestSnap).abs();
                  for (final snap in snapPoints) {
                    final distance = (currentSize - snap).abs();
                    if (distance < minDistance) {
                      minDistance = distance;
                      closestSnap = snap;
                    }
                  }
                  _controller.animateTo(
                    closestSnap,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                },
                child: Column(
                  children: [
                    // Barre grise fixe
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Onglets toujours visibles
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: OrganizedOptionTabs(
                        currentIndex: widget.currentOptionIndex,
                        totalOptions: widget.totalOptions,
                        onTabChanged: widget.onTabChanged,
                        onQuit: widget.onQuit,
                        onBack: widget.onBack,
                        onAddOption: widget.onAddNewOption,
                        canAddOption: widget.canAddOption,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _isMinimized
                      ? _buildMinimizedContent()
                      : _buildExpandedContent(),
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  /// Contenu minimal : résumé du trajet
  Widget _buildMinimizedContent() {
    final startName = widget.option.startPoint?.name ?? 'Position actuelle';
    final destName = widget.option.destination?.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.place, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    startName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Lexend Deca',
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (destName != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white54, size: 14),
                  const SizedBox(width: 8),
                  const Icon(Icons.flag, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      destName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lexend Deca',
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// Contenu complet : tout le détail de l'option
  Widget _buildExpandedContent() {
    return OrganizedWaypointSheet(
      option: widget.option,
      onAddDestination: widget.onAddDestination,
      onSaveOption: widget.onSaveOption,
      onClose: widget.onClose,
      onInsertWaypoint: widget.onInsertWaypoint,
    );
  }
}
