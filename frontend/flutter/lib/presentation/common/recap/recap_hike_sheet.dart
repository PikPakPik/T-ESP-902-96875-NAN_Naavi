import 'package:flutter/material.dart';
import 'package:naavi/core/di/RecapHikeProvider.dart';
import 'package:naavi/data/models/improvise_hike.dart';
import 'package:naavi/data/models/user_poi.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/presentation/common/widget/TextButton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;

import 'RecapHikeState.dart';

class RecapHikeSheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final List<List<gl.Position>> segments;
  final Duration? duration; // Durée calculée correctement avec les pauses
  final Function(UserPOI poi)? onNavigateToPoi;

  const RecapHikeSheet({
    super.key,
    required this.onClose,
    required this.segments,
    this.duration,
    this.onNavigateToPoi,
  });

  @override
  ConsumerState<RecapHikeSheet> createState() => _RecapHikeSheetState();
}

class _RecapHikeSheetState extends ConsumerState<RecapHikeSheet> {
  /// Formate une durée de manière lisible
  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}j ${hours}h${minutes}min';
    } else if (hours > 0) {
      return '${hours}h${minutes}min';
    } else if (minutes > 0) {
      return '${minutes}min${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(recapHikeProvider.notifier)
          .getFinalHike(widget.segments, duration: widget.duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recapHikeProvider);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(36, 25, 19, 1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: _buildContent(state),
      ),
    );
  }

  Widget _buildContent(RecapHikeState state) {
    if (state is RecapHikeStateLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is RecapHikeStateHikeFetched) {
      final hike = state.hike;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: recapData(hike),
          ),
          if (hike.pois.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: recapReport(hike.pois),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: actionButton(onPressed: widget.onClose, text: "Terminé"),
          ),
        ],
      );
    }

    if (state is RecapHikeStateHikeNotFetched) {
      return const Center(child: Text("Impossible de récupérer la randonnée"));
    }

    if (state is RecapHikeStateError) {
      return Center(
        child: Text(
          "Erreur : ${state.message}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget recapData(ImproviseHike hike) {
    // Calculer les stats
    final distanceKm = double.tryParse(hike.distance) ?? 0.0;
    final durationSeconds = hike.finalTime.inSeconds;
    final elevationGain = (hike.elevationGainPositive ?? 0.0);

    // Vitesse moyenne (km/h)
    final averageSpeedKmh = durationSeconds > 0
        ? (distanceKm / durationSeconds) * 3600
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Titre
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Text(
            "Votre parcours",
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Lexend Deca',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Grille de stats (6 stats sur 2 lignes de 3)
        _buildStatsGrid(
          duration: hike.finalTime,
          distanceKm: distanceKm,
          elevationGain: elevationGain,
          elevationLoss: hike.elevationGainNegative ?? 0.0,
          averageSpeedKmh: averageSpeedKmh,
        ),
      ],
    );
  }

  /// Grille de statistiques (6 stats sur 2 lignes de 3)
  Widget _buildStatsGrid({
    required Duration duration,
    required double distanceKm,
    required double elevationGain,
    required double elevationLoss,
    required double averageSpeedKmh,
  }) {
    return Column(
      children: [
        // Première ligne : Durée, Distance, Dénivelé +
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'Durée',
                value: _formatDuration(duration),
                icon: Icons.access_time_rounded,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Distance',
                value: _formatDistance(distanceKm),
                icon: Icons.straighten_rounded,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Dénivelé +',
                value: '${elevationGain.toInt()}m',
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Deuxième ligne : Dénivelé -, Vitesse moy, (placeholder ou autre stat)
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                label: 'Dénivelé -',
                value: '${elevationLoss.toInt()}m',
                icon: Icons.trending_down_rounded,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Vitesse moy.',
                value: '${averageSpeedKmh.toStringAsFixed(1)}km/h',
                icon: Icons.speed_rounded,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildStatItem(
                label: 'Allure moy.',
                value: _formatPace(averageSpeedKmh),
                icon: Icons.directions_walk_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formate la distance
  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()}m';
    }
    return '${km.toStringAsFixed(2)}km';
  }

  /// Formate l'allure (min/km)
  String _formatPace(double speedKmh) {
    if (speedKmh <= 0) return '--:--';
    final paceMinPerKm = 60 / speedKmh;
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '$minutes\'${seconds.toString().padLeft(2, '0')}"/km';
  }

  /// Item de statistique individuel avec icône
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // Icône
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          // Valeur
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Lexend Deca',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'Lexend Deca',
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget recapReport(List<UserPOI> pois) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            "Signalements placés",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Lexend Deca',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // Liste horizontale scrollable
        SizedBox(
          height: 120, // Hauteur fixe pour les cartes
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pois.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < pois.length - 1 ? 12.0 : 0,
                ),
                child: poiCard(
                  poi: pois[index],
                  onNavigate: widget.onNavigateToPoi,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget poiCard({required UserPOI poi, Function(UserPOI poi)? onNavigate}) {
    return Container(
      width: 200, // Largeur fixe pour le scroll horizontal
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: poi.type.color.withValues(alpha: 0.15),
        border: Border.all(
          color: poi.type.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Icône + Nom
            Row(
              children: [
                // Icône du POI
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: poi.type.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: poi.type.icon(size: 18),
                ),
                const SizedBox(width: 8),
                // Nom du POI
                Expanded(
                  child: Text(
                    poi.type.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Lexend Deca',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bouton pour voir sur la carte
            GestureDetector(
              onTap: () {
                // Naviguer vers le POI sans fermer le modal
                onNavigate?.call(poi);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: poi.type.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Voir sur la carte',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Lexend Deca',
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
