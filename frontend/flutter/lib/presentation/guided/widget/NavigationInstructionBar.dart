import 'package:flutter/material.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/presentation/guided/state/GuidedHikeTrackingState.dart';

/// Barre d'instructions de navigation affichée en haut de l'écran
/// pendant le suivi d'une randonnée guidée
class NavigationInstructionBar extends StatelessWidget {
  final String instruction;
  final double? distanceToNextPoint;  // en mètres
  final String? nextStreetName;
  final DirectionType directionType;

  const NavigationInstructionBar({
    super.key,
    required this.instruction,
    this.distanceToNextPoint,
    this.nextStreetName,
    this.directionType = DirectionType.straight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Direction icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDirectionIcon(),
                  color: AppColors.tertiaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Instruction text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (distanceToNextPoint != null)
                      Text(
                        _formatDistance(distanceToNextPoint!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Lexend Deca',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      instruction,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Lexend Deca',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress indicator or additional info
          if (nextStreetName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nextStreetName!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'Lexend Deca',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getDirectionIcon() {
    switch (directionType) {
      case DirectionType.straight:
        return Icons.arrow_upward;
      case DirectionType.slightRight:
        return Icons.turn_slight_right;
      case DirectionType.right:
        return Icons.turn_right;
      case DirectionType.sharpRight:
        return Icons.turn_sharp_right;
      case DirectionType.uTurn:
        return Icons.u_turn_left;
      case DirectionType.sharpLeft:
        return Icons.turn_sharp_left;
      case DirectionType.left:
        return Icons.turn_left;
      case DirectionType.slightLeft:
        return Icons.turn_slight_left;
      case DirectionType.arrived:
        return Icons.flag;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

