/*import 'package:flutter/material.dart';
import 'package:naavi/core/di/RecapHikeProvider.dart';
import 'package:naavi/core/models/improvise_hike.dart';
import 'package:naavi/core/models/user_poi.dart';
import 'package:naavi/core/utils/poi_type.dart';
import 'package:naavi/presentation/common/widget/TextButton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;

import '../common/recap/RecapHikeState.dart';


class RecapHike extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final List<List<gl.Position>> segments;
  final Function(UserPOI poi)? onNavigateToPoi;

  const RecapHike({
    super.key,
    required this.onClose,
    required this.segments,
    this.onNavigateToPoi,
  });

  @override
  ConsumerState<RecapHike> createState() => _RecapHikeState();
}
class _RecapHikeState extends ConsumerState<RecapHike> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recapHikeProvider.notifier).getFinalHike(widget.segments);
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
            child: RecapData(hike),
          ),
          if (hike.pois.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: RecapReport(hike.pois),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: actionButton(
              onPressed: widget.onClose,
              text: "Terminé",
            ),
          ),
        ],
      );
    }

    if (state is RecapHikeStateHikeNotFetched) {
      return const Center(
        child: Text("Impossible de récupérer la randonnée"),
      );
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

  Widget RecapData(ImproviseHike hike) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Text("Votre parcours",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Lexend Deca',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 16,
          children: [
            // Durée
            _buildStatCard(
              icon: 'assets/icons/recap/alarm.png',
              value: "${hike.finalTime.inHours}h${hike.finalTime.inMinutes.remainder(60)}min",
              label: "Durée",
            ),
            // Distance
            _buildStatCard(
              icon: 'assets/icons/recap/directions_walk.png',
              value: "${hike.distance} km",
              label: "Distance",
            ),
            // Dénivelé positif
            if (hike.elevationGainPositive != null && hike.elevationGainPositive! > 0)
              _buildStatCard(
                iconWidget: Icon(Icons.arrow_upward, color: Colors.white, size: 24),
                value: "${hike.elevationGainPositive!.toInt()} m",
                label: "D+",
              ),
            // Dénivelé négatif
            if (hike.elevationGainNegative != null && hike.elevationGainNegative! > 0)
              _buildStatCard(
                iconWidget: Icon(Icons.arrow_downward, color: Colors.white, size: 24),
                value: "${hike.elevationGainNegative!.toInt()} m",
                label: "D-",
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    String? icon,
    Widget? iconWidget,
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
            child: iconWidget ?? Image.asset(icon!, fit: BoxFit.contain),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend Deca',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Lexend Deca',
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget RecapReport(List<UserPOI> pois) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text("Signalements placés",
            style: TextStyle(
                fontSize: 14,
                fontFamily: 'Lexend Deca',
                fontWeight: FontWeight.bold,
                color: Colors.white
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
                child: PoiCard(
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

  Widget PoiCard({
    required UserPOI poi,
    Function(UserPOI poi)? onNavigate,
  }) {
    return Container(
      width: 200, // Largeur fixe pour le scroll horizontal
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: poi.type.color.withOpacity(0.15),
        border: Border.all(
          color: poi.type.color.withOpacity(0.3),
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
                    color: poi.type.color.withOpacity(0.2),
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
}*/
