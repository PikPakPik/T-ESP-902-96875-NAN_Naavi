/*import 'package:flutter/material.dart';
import 'package:naavi/core/resources/colors.dart';

/// Popup de détail d'une randonnée avec slide pour fermer
class HikeDetailPopup extends StatefulWidget {
  final Map<String, dynamic> hikeInfo;
  final bool isNearby;
  final VoidCallback onClose;
  final VoidCallback onLaunch;
  final VoidCallback onAddPoi;
  final VoidCallback onShowDetails;
  final double? distance; // Distance en km

  const HikeDetailPopup({
    super.key,
    required this.hikeInfo,
    required this.isNearby,
    required this.onClose,
    required this.onLaunch,
    required this.onAddPoi,
    required this.onShowDetails,
    this.distance,
  });

  @override
  State<HikeDetailPopup> createState() => _HikeDetailPopupState();
}

class _HikeDetailPopupState extends State<HikeDetailPopup>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  static const double _closeThreshold = 100.0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset > _closeThreshold || velocity > 300) {
      widget.onClose();
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: Matrix4.translationValues(0, _dragOffset, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton signalement au-dessus de la popup
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
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header : Handle + bouton fermer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Handle indicator centré
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Bouton fermer à droite
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Carrousel d'images
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      children: [
                        _buildImageCard('assets/images/hike_1.jpg', Icons.landscape),
                        _buildImageCard('assets/images/hike_2.jpg', Icons.terrain),
                        _buildImageCard('assets/images/hike_3.jpg', Icons.nature, isLast: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Titre avec flèche pour voir les détails
                  GestureDetector(
                    onTap: widget.onShowDetails,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.hikeInfo['name'] ?? 'Randonnée',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Lexend Deca',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Infos en une ligne
                  Text(
                    '${widget.hikeInfo['distance'] ?? '?'}km  -  ${widget.hikeInfo['duree'] ?? '?'}  -  Dénivelé : ${widget.hikeInfo['denivele'] ?? '?'}m',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Lexend Deca',
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Séparateur
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),

                  const SizedBox(height: 16),

                  // Message d'avertissement si trop loin
                  if (!widget.isNearby)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.orange[300],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.distance != null
                                ? 'Trop loin (${widget.distance!.toStringAsFixed(1)} km). Rapprochez-vous (< 5 km)'
                                : 'Rapprochez-vous du point de départ (< 5 km)',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontFamily: 'Lexend Deca',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bouton Lancer la randonnée
                  GestureDetector(
                    onTap: widget.isNearby ? widget.onLaunch : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: widget.isNearby ? Colors.white : Colors.grey[700],
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Lancer la randonnée',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.isNearby ? Colors.black : Colors.grey[500],
                          fontFamily: 'Lexend Deca',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String assetPath, IconData fallbackIcon, {bool isLast = false}) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(right: isLast ? 0 : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(fallbackIcon, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
*/