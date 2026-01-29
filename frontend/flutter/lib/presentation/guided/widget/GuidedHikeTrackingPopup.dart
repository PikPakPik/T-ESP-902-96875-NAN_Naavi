import 'package:flutter/material.dart';
import 'package:naavi/core/resources/colors.dart';

/// Popup affichée pendant le suivi d'une randonnée guidée
/// Avec gesture de slide vers le bas pour minimiser et vers le haut pour ouvrir
class GuidedHikeTrackingPopup extends StatefulWidget {
  final int elapsedSeconds;
  final double distanceKm;
  final VoidCallback onFinish;
  final VoidCallback onAddPoi;
  final VoidCallback onPauseResume;
  final bool isExpanded;
  final bool isPaused;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<double>? onHeightChanged;

  const GuidedHikeTrackingPopup({
    super.key,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.onFinish,
    required this.onAddPoi,
    required this.onPauseResume,
    required this.isExpanded,
    required this.isPaused,
    required this.onExpandedChanged,
    this.onHeightChanged,
  });

  @override
  State<GuidedHikeTrackingPopup> createState() =>
      _GuidedHikeTrackingPopupState();
}

class _GuidedHikeTrackingPopupState extends State<GuidedHikeTrackingPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  double _dragOffset = 0.0;

  static const double _collapsedHeight = 60.0;
  static const double _expandedHeight = 280.0;

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
  void didUpdateWidget(GuidedHikeTrackingPopup oldWidget) {
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

    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}min';
    } else {
      return '${minutes}h${(seconds % 60).toString().padLeft(2, '0')}min';
    }
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    // Si on glisse vers le bas rapidement ou si on a glissé plus de 50px vers le bas
    if (velocity > 300 || _dragOffset > 50) {
      widget.onExpandedChanged(false);
    }
    // Si on glisse vers le haut rapidement ou si on a glissé plus de 50px vers le haut
    else if (velocity < -300 || _dragOffset < -50) {
      widget.onExpandedChanged(true);
    }

    setState(() {
      _dragOffset = 0;
    });
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
        final progress =
            (clampedHeight - _collapsedHeight) /
            (_expandedHeight - _collapsedHeight);

        // Notifier le parent de la hauteur actuelle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onHeightChanged?.call(clampedHeight);
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton de signalement (collé au-dessus de la popup)
            Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: widget.onAddPoi,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_location_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

            // Popup principale
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
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle indicator (toujours visible)
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Contenu minimisé (visible seulement quand la popup est fermée)
                        if (progress < 0.5)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDuration(widget.elapsedSeconds),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lexend Deca',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                _formatDistance(widget.distanceKm),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lexend Deca',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                        // Contenu expandé
                        if (progress > 0.5) ...[
                          const SizedBox(height: 20),

                          // Header avec titre
                          const Text(
                            "Votre parcours",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Lexend Deca',
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Stats row avec icônes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                icon: 'assets/icons/alarm.png',
                                value: _formatDuration(widget.elapsedSeconds),
                                label: "Durée",
                              ),
                              _buildStatCard(
                                icon: 'assets/icons/directions_walk.png',
                                value: _formatDistance(widget.distanceKm),
                                label: "Distance",
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Boutons Stopper et Arrêter
                          Row(
                            children: [
                              // Bouton Stopper/Reprendre
                              Expanded(
                                child: GestureDetector(
                                  onTap: widget.onPauseResume,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          widget.isPaused
                                              ? Icons.play_arrow
                                              : Icons.pause,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.isPaused
                                              ? "Reprendre"
                                              : "Stopper",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Lexend Deca',
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Bouton Arrêter
                              Expanded(
                                child: GestureDetector(
                                  onTap: widget.onFinish,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.stop,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Arrêter",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Lexend Deca',
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
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
                      ],
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

  Widget _buildStatCard({
    String? icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            width: 24,
            height: 24,
            child: icon != null
                ? Image.asset(icon, fit: BoxFit.contain)
                : const Icon(Icons.timer, color: Colors.white, size: 24),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend Deca',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Lexend Deca',
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
