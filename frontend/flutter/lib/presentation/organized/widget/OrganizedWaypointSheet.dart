import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/presentation/common/widget/ImageCarousel.dart';
import '../../../core/resources/colors.dart';
import '../../../data/models/organized_hike_option.dart';
import '../../../data/models/organized_waypoint.dart';
import '../../../data/models/route_statistics.dart';

/// Bottom sheet affichant les détails d'une option avec statistiques
/// Correspond aux images 4, 5, 6, 7, 8 des maquettes
/// Affiche : distance, temps, dénivelé, POI, etc.
class OrganizedWaypointSheet extends ConsumerStatefulWidget {
  final OrganizedHikeOption option;
  final VoidCallback onAddDestination;
  final VoidCallback onSaveOption;
  final VoidCallback onClose;
  final void Function(int insertAtIndex)? onInsertWaypoint;

  const OrganizedWaypointSheet({
    super.key,
    required this.option,
    required this.onAddDestination,
    required this.onSaveOption,
    required this.onClose,
    this.onInsertWaypoint,
  });

  @override
  ConsumerState<OrganizedWaypointSheet> createState() =>
      _OrganizedWaypointSheetState();
}

class _OrganizedWaypointSheetState
    extends ConsumerState<OrganizedWaypointSheet> {
  /// États ouverts/fermés des tiroirs (par index de segment)
  final Map<int, bool> _expandedSegments = {};

  bool _isSegmentExpanded(int index) => _expandedSegments[index] ?? false;

  void _toggleSegment(int index) {
    setState(() {
      _expandedSegments[index] = !_isSegmentExpanded(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final waypoints = widget.option.waypoints;
    final statistics = widget.option.statistics;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Liste des waypoints avec carrousels et tiroirs de statistiques entre eux
              ..._buildWaypointsWithStats(waypoints, statistics),

              const SizedBox(height: 24),

              // Boutons d'action
              if (widget.option.isComplete)
                _buildActionButtonsRow()
              else
                _buildAddDestinationButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la liste des waypoints avec carrousels et tiroirs de statistiques entre chaque paire
  List<Widget> _buildWaypointsWithStats(
    List<OrganizedWaypoint> waypoints,
    RouteStatistics? statistics,
  ) {
    final widgets = <Widget>[];

    for (int i = 0; i < waypoints.length; i++) {
      final waypoint = waypoints[i];
      final isFirst = i == 0;
      final isLast = i == waypoints.length - 1;

      // Détermine le label et l'icône selon la position
      String label;
      IconData icon;
      if (isFirst) {
        label = 'Point de départ';
        icon = Icons.place;
      } else if (isLast) {
        label = 'Destination';
        icon = Icons.flag;
      } else {
        label = 'Étape $i';
        icon = Icons.location_on;
      }

      // Ajoute le waypoint
      widgets.add(
        _buildWaypointInfo(
          icon: icon,
          label: label,
          value: waypoint.name ?? 'Point ${i + 1}',
          color: Colors.white,
        ),
      );

      // Carrousel d'images du waypoint (mock si vide)
      final images = waypoint.imageUrls.isNotEmpty
          ? waypoint.imageUrls
          : const [
              "https://images.pexels.com/photos/10725550/pexels-photo-10725550.jpeg",
              "https://images.pexels.com/photos/15291519/pexels-photo-15291519.jpeg",
              "https://images.pexels.com/photos/1062249/pexels-photo-1062249.jpeg",
              "https://images.pexels.com/photos/3917809/pexels-photo-3917809.jpeg",
            ];
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        ImageCarousel(
          imageUrls: images,
          height: 160,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(12),
        ),
      );

      // Ajoute le tiroir de statistiques entre ce point et le suivant (sauf après le dernier)
      if (!isLast && statistics != null) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          _buildStatisticsDrawer(
            segmentIndex: i,
            statistics: statistics,
            segmentCount: waypoints.length - 1,
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
    }

    return widgets;
  }

  /// Tiroir de statistiques avec ligne pointillée
  Widget _buildStatisticsDrawer({
    required int segmentIndex,
    required RouteStatistics statistics,
    required int segmentCount,
  }) {
    final isExpanded = _isSegmentExpanded(segmentIndex);

    // Divise les statistiques par le nombre de segments (approximation simple)
    final segmentStats = RouteStatistics(
      distanceKm: statistics.distanceKm / segmentCount,
      elevationGainM: (statistics.elevationGainM / segmentCount).round(),
      estimatedDuration: Duration(
        seconds: statistics.estimatedDuration.inSeconds ~/ segmentCount,
      ),
    );

    return Column(
      children: [
        // Ligne pointillée avec bouton "Voir plus/moins" et bouton d'ajout d'étape
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              // Espace pour aligner avec les icônes des waypoints
              const SizedBox(width: 16),
              // Ligne pointillée verticale
              _buildDottedLine(),
              const SizedBox(width: 12),
              // Zone cliquable pour voir plus/moins
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleSegment(segmentIndex),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        isExpanded ? 'Voir moins' : 'Voir plus',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Lexend Deca',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              // Bouton pour ajouter une étape entre ces deux points
              if (widget.onInsertWaypoint != null)
                GestureDetector(
                  onTap: () => widget.onInsertWaypoint!(segmentIndex + 1),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_location_alt,
                      color: AppColors.secondaryColor,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Contenu du tiroir (statistiques)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 44.0, bottom: 8.0),
            child: _buildSegmentStats(segmentStats),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  /// Ligne pointillée verticale
  Widget _buildDottedLine() {
    return SizedBox(
      width: 2,
      height: 20,
      child: CustomPaint(
        painter: _DottedLinePainter(),
      ),
    );
  }

  /// Statistiques d'un segment
  Widget _buildSegmentStats(RouteStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMiniStatCard(
            icon: Icons.straighten,
            value: stats.formattedDistance,
            label: 'Distance',
          ),
          _buildMiniStatCard(
            icon: Icons.access_time,
            value: stats.formattedDuration,
            label: 'Durée',
          ),
          _buildMiniStatCard(
            icon: Icons.trending_up,
            value: '${stats.elevationGainM}m',
            label: 'Dénivelé',
          ),
        ],
      ),
    );
  }

  /// Carte de statistique mini
  Widget _buildMiniStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Lexend Deca',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Lexend Deca',
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Affiche les infos d'un waypoint
  Widget _buildWaypointInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Lexend Deca',
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lexend Deca',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bouton pour ajouter une destination (affiché seul avant d'avoir 2 points)
  Widget _buildAddDestinationButton() {
    return GestureDetector(
      onTap: widget.onAddDestination,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.tertiaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt,
                color: AppColors.secondaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Ajouter une destination',
              style: TextStyle(
                color: AppColors.secondaryColor,
                fontFamily: 'Lexend Deca',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Row avec bouton d'ajout d'étape + bouton sauvegarder (affiché quand 2 points sont définis)
  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        // Bouton icône pour ajouter une étape
        GestureDetector(
          onTap: widget.onAddDestination,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.tertiaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_location_alt,
              color: AppColors.secondaryColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton sauvegarder qui prend le reste de la largeur
        Expanded(
          child: GestureDetector(
            onTap: widget.onSaveOption,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.tertiaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: AppColors.secondaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sauvegarder le trajet',
                    style: TextStyle(
                      color: AppColors.secondaryColor,
                      fontFamily: 'Lexend Deca',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter pour la ligne pointillée verticale
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
