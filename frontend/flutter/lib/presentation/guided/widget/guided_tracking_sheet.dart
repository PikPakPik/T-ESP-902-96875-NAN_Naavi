import 'package:flutter/material.dart';
import 'package:naavi/core/resources/colors.dart';

/// Popup affichée pendant le suivi d'une randonnée guidée
/// Avec gesture de slide vers le bas pour minimiser et vers le haut pour ouvrir
class GuidedTrackingSheet extends StatefulWidget {
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

  const GuidedTrackingSheet({
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
  State<GuidedTrackingSheet> createState() => _GuidedTrackingSheetState();
}

class _GuidedTrackingSheetState extends State<GuidedTrackingSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  double _dragOffset = 0.0;

  static const double _collapsedHeight = 120.0; // Stats seulement
  static const double _expandedHeight = 400.0; // Stats + boutons

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
  void didUpdateWidget(GuidedTrackingSheet oldWidget) {
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
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (days > 0) {
      return '${days}j ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${secs}s';
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
    final threshold = 30.0; // Seuil réduit pour une meilleure réactivité

    // Si on glisse vers le bas rapidement ou si on a glissé suffisamment vers le bas
    if (velocity > 200 || _dragOffset > threshold) {
      widget.onExpandedChanged(false);
    }
    // Si on glisse vers le haut rapidement ou si on a glissé suffisamment vers le haut
    else if (velocity < -200 || _dragOffset < -threshold) {
      widget.onExpandedChanged(true);
    }
    // Si on est déjà en mode collapsed et qu'on glisse vers le bas, rester fermé
    else if (!widget.isExpanded && _dragOffset > 0) {
      widget.onExpandedChanged(false);
    }
    // Si on est déjà en mode expanded et qu'on glisse vers le haut, rester ouvert
    else if (widget.isExpanded && _dragOffset < 0) {
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

                        // Stats grid (toujours visible)
                        _buildStatsGrid(),

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
                                icon: 'assets/icons/recap/alarm.png',
                                value: _formatDuration(widget.elapsedSeconds),
                                label: "Durée",
                              ),
                              _buildStatCard(
                                icon: 'assets/icons/recap/directions_walk.png',
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

                          const SizedBox(height: 12),

                          // Bouton Annuler
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.red, width: 2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Annuler la randonnée",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Lexend Deca',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                ? Image.asset(
                    icon,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback sur les icônes Material si l'image n'existe pas
                      return Icon(
                        label == "Durée"
                            ? Icons.access_time
                            : Icons.directions_walk,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  )
                : Icon(
                    label == "Durée"
                        ? Icons.access_time
                        : Icons.directions_walk,
                    color: Colors.white,
                    size: 24,
                  ),
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

  /// Grille de statistiques style Improvise (6 stats sur 2 lignes de 3)
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
}
