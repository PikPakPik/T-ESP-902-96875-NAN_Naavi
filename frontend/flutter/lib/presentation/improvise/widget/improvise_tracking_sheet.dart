import 'package:flutter/material.dart';
import 'package:naavi/core/resources/colors.dart';

/// Popup affichée pendant le suivi d'une randonnée improvisée
/// Design inspiré de l'Organized trip avec 6 stats et 2 boutons
class ImproviseTrackingSheet extends StatefulWidget {
  final int elapsedSeconds;
  final double distanceKm;
  final double currentSpeedKmh;
  final double elevationM;
  final double averageSpeedKmh;
  final double currentAltitudeM;
  final VoidCallback onFinish;
  final VoidCallback onPauseResume;
  final VoidCallback onCancel;
  final bool isExpanded;
  final bool isPaused;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<double>? onHeightChanged;

  const ImproviseTrackingSheet({
    super.key,
    required this.elapsedSeconds,
    required this.distanceKm,
    this.currentSpeedKmh = 0.0,
    this.elevationM = 0.0,
    this.averageSpeedKmh = 0.0,
    this.currentAltitudeM = 0.0,
    required this.onFinish,
    required this.onPauseResume,
    required this.onCancel,
    required this.isExpanded,
    required this.isPaused,
    required this.onExpandedChanged,
    this.onHeightChanged,
  });

  @override
  State<ImproviseTrackingSheet> createState() => _ImproviseTrackingSheetState();
}

class _ImproviseTrackingSheetState extends State<ImproviseTrackingSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  double _dragOffset = 0.0;

  static const double _collapsedHeight = 120.0; // Stats seulement
  static const double _expandedHeight = 200.0; // Stats + boutons

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnimation =
        Tween<double>(begin: _collapsedHeight, end: _expandedHeight).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ImproviseTrackingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min ${secs.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}min ${secs.toString().padLeft(2, '0')}s';
    } else {
      return '${secs}s';
    }
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()}m';
    }
    return '${km.toStringAsFixed(2)}km';
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    // Calculer la hauteur actuelle et la convertir en valeur d'animation (0-1)
    final currentHeight = (_heightAnimation.value - _dragOffset).clamp(
      _collapsedHeight,
      _expandedHeight,
    );
    final currentAnimationValue =
        (currentHeight - _collapsedHeight) /
        (_expandedHeight - _collapsedHeight);

    // Mettre à jour l'AnimationController à la position actuelle AVANT de lancer l'animation
    _animationController.value = currentAnimationValue;

    // Remettre le dragOffset à 0 maintenant que l'AnimationController est à jour
    setState(() {
      _dragOffset = 0;
    });

    // Déterminer la cible basée sur la velocity ou la position actuelle
    bool shouldExpand;
    if (velocity > 200) {
      // Swipe vers le bas rapide -> fermer
      shouldExpand = false;
    } else if (velocity < -200) {
      // Swipe vers le haut rapide -> ouvrir
      shouldExpand = true;
    } else {
      // Pas de swipe rapide, basculer selon la position (seuil à 50%)
      shouldExpand = currentAnimationValue >= 0.5;
    }

    // Si l'état ne change pas, on doit quand même animer vers la position cible
    if (shouldExpand == widget.isExpanded) {
      // L'état reste le même, mais on doit animer pour revenir à la position
      if (shouldExpand) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    } else {
      // L'état change, didUpdateWidget déclenchera l'animation
      widget.onExpandedChanged(shouldExpand);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        final currentHeight = _heightAnimation.value - _dragOffset;
        final clampedHeight = currentHeight.clamp(
          _collapsedHeight,
          _expandedHeight,
        );

        // Notifier le parent de la hauteur actuelle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onHeightChanged?.call(clampedHeight);
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              onTap: () {
                if (!widget.isExpanded) {
                  widget.onExpandedChanged(true);
                }
              },
              child: Container(
                width: double.infinity,
                height: clampedHeight,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: OverflowBox(
                  maxHeight: _expandedHeight,
                  alignment: Alignment.topCenter,
                  child: ClipRect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle indicator
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Stats grid (toujours visible)
                          _buildStatsGrid(),

                          // Boutons (toujours présents, clippés par la hauteur)
                          const SizedBox(height: 12),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Grille de statistiques style Organized trip (6 stats sur 2 lignes de 3)
  Widget _buildStatsGrid() {
    return Column(
      children: [
        // Première ligne : Temps écoulé, Distance parcourue, Altitude actuelle
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'Temps écoulé',
                value: _formatDuration(widget.elapsedSeconds),
              ),
            ),
            Container(width: 1, height: 32, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Distance parcourue',
                value: _formatDistance(widget.distanceKm),
              ),
            ),
            Container(width: 1, height: 32, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Altitude actuelle',
                value: _formatAltitude(widget.currentAltitudeM),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Deuxième ligne : Dénivelé, Vitesse actuelle, Vitesse moyenne
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'Dénivelé',
                value: _formatElevation(widget.elevationM),
              ),
            ),
            Container(width: 1, height: 32, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Vitesse actuelle',
                value: _formatSpeed(widget.currentSpeedKmh),
              ),
            ),
            Container(width: 1, height: 32, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Vitesse moyenne',
                value: _formatSpeed(widget.averageSpeedKmh),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formate l'altitude actuelle en mètres
  String _formatAltitude(double meters) {
    return '${meters.toInt()}m';
  }

  /// Formate le dénivelé en mètres
  String _formatElevation(double meters) {
    return '${meters.toInt()}m';
  }

  /// Formate la vitesse en km/h
  String _formatSpeed(double kmh) {
    return '${kmh.toStringAsFixed(1)}km/h';
  }

  /// Item de statistique individuel
  Widget _buildStatItem({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'Lexend Deca',
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Lexend Deca',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Boutons d'action
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Ligne de séparation
        Container(
          width: double.infinity,
          height: 1,
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white24,
        ),

        // Boutons Mettre en pause / Terminer
        Row(
          children: [
            // Bouton Mettre en pause / Reprendre
            Expanded(
              child: GestureDetector(
                onTap: widget.onPauseResume,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: AppColors.secondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isPaused ? 'Reprendre' : 'Mettre en pause',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Lexend Deca',
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Bouton Terminer la randonnée
            Expanded(
              child: GestureDetector(
                onTap: widget.onFinish,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: AppColors.secondaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Terminer',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Lexend Deca',
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
