import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/data/models/partner_dto.dart';
import 'package:naavi/presentation/common/FullScreenImagePage.dart';
import 'package:naavi/presentation/hike/widget/partners_section.dart';
import 'package:naavi/presentation/hike/widget/poi_section.dart';
import 'package:naavi/presentation/hike/widget/hike_map_widget.dart';

/// Page de détail d'une randonnée
class HikeDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> hikeInfo;
  final VoidCallback? onStart;

  const HikeDetailPage({super.key, required this.hikeInfo, this.onStart});

  @override
  ConsumerState<HikeDetailPage> createState() => _HikeDetailPageState();
}

class _HikeDetailPageState extends ConsumerState<HikeDetailPage> {
  late bool _showMapFullScreen;

  // Partenaires (pour l'instant en dur, à remplacer par un appel API)
  final List<PartnerDto> _partners = [
    PartnerDto(
      id: 1,
      name: 'Hoka',
      category: 'Matériel de sport',
      address: '1 rue de la Jolie Montagne',
      testimonial: 'Service très agréable et superbe vu sur les montagnes !',
      logoText: 'HOKA',
    ),
    PartnerDto(
      id: 2,
      name: 'Decathlon',
      category: 'Équipement sportif',
      address: '15 avenue des Sports',
      testimonial: 'Excellent rapport qualité-prix pour vos randonnées !',
      logoText: 'DEC',
    ),
    PartnerDto(
      id: 3,
      name: 'La Montagne',
      category: 'Restaurant',
      address: '8 chemin des Crêtes',
      testimonial: 'Repas délicieux après une belle randonnée !',
      logoText: 'MTG',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Si pas d'image, afficher directement la carte en plein écran
    _showMapFullScreen = widget.hikeInfo['imagePath'] == null;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.hikeInfo['name'] ?? 'Randonnée';
    final region =
        widget.hikeInfo['region'] ?? widget.hikeInfo['location'] ?? '';
    final distance = widget.hikeInfo['distance'] ?? '?';
    final duree = widget.hikeInfo['duree'] ?? '?';
    final denivele = widget.hikeInfo['denivele'] ?? '?';
    final source = widget.hikeInfo['source'];
    final isOfficial = source == 'OFFICIAL';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: Stack(
          children: [
            // Contenu scrollable avec image et détails
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Zone image/carte en haut (scrollable)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: HikeMapWidget(
                      wkb: widget.hikeInfo['wkb'] as String?,
                      startLat: widget.hikeInfo['startLat'] as double?,
                      startLon: widget.hikeInfo['startLon'] as double?,
                      showMapFullScreen: _showMapFullScreen,
                      onMapFullScreenChanged: (value) {
                        setState(() {
                          _showMapFullScreen = value;
                        });
                      },
                      imagePath: widget.hikeInfo['imagePath'] as String?,
                      onFullScreenImage: widget.hikeInfo['imagePath'] != null
                          ? () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => FullScreenImagePage(
                                        imagePath:
                                            widget.hikeInfo['imagePath']
                                                as String,
                                      ),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),

                  // Contenu détaillé
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auteur (en haut)
                        Row(
                          children: [
                            if (isOfficial) ...[
                              // Logo Naavi (placeholder - à remplacer par le vrai logo)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Officiel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Lexend Deca',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else ...[
                              // Avatar créateur (placeholder)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'John Doe', // TODO: Récupérer le nom du créateur depuis l'API
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Lexend Deca',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Titre et note
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Lexend Deca',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Note (placeholder pour l'instant)
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: AppColors.greenMedium,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.8', // TODO: Récupérer depuis l'API
                                  style: TextStyle(
                                    color: AppColors.greenMedium,
                                    fontFamily: 'Lexend Deca',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        if (region.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            region,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontFamily: 'Lexend Deca',
                              fontSize: 14,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Infos : distance - durée - dénivelé
                        Text(
                          '${distance}km - $duree - Dénivelé : ${denivele}m',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Lexend Deca',
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Points d'intérêt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Points d\'intérêts',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Lexend Deca',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // TODO: Naviguer vers la page détaillée des POI
                              },
                              child: Text(
                                'Voir plus',
                                style: TextStyle(
                                  color: AppColors.greenMedium,
                                  fontFamily: 'Lexend Deca',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        POISection(
                          counts: const {
                            'PARKING': 0,
                            'WATER': 0,
                            'TOILET': 0,
                            'MUST_SEE_SPOT': 0,
                          },
                        ),

                        const SizedBox(height: 32),

                        // Ligne de séparation (90% de largeur)
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section Partenaires
                        PartnersSection(partners: _partners),

                        const SizedBox(
                          height: 80,
                        ), // Espace pour le bouton flottant
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bouton retour (fixe en haut)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Bouton Démarrer flottant
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  if (widget.onStart != null) {
                    widget.onStart!();
                  }
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation, color: Colors.black87, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Démarrer',
                        style: TextStyle(
                          color: Colors.black87,
                          fontFamily: 'Lexend Deca',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
