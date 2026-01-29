import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/resources/colors.dart';
import '../../core/di/MapProviders.dart';
import '../../data/models/hike_dto.dart';
import '../map/state/MapServicesState.dart';
import '../common/widget/hike_card.dart';
import '../common/widget/quick_filters.dart';
import '../../core/services/mapbox_static_image_service.dart';
import '../hike/HikeDetailPage.dart';
import 'widget/filters_bottom_sheet.dart';

/// Page de recherche dédiée pour rechercher des parcours
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<int> _selectedFilterIndices = {
    0,
  }; // "Tous" est sélectionné par défaut

  List<HikeDto> _recommendedHikes = [];
  List<HikeDto> _communityHikes = [];
  bool _isLoading = true;

  // Filtres
  SortOption? _selectedSort;
  Set<DifficultyFilter> _selectedDifficulties = {};
  RangeValues? _distanceRange;

  @override
  void initState() {
    super.initState();
    // Écouter les changements dans le champ de recherche pour filtrer
    _searchController.addListener(_onSearchChanged);
    // Focus automatique sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _loadHikes();
    });
  }

  /// Appelé lorsque le texte de recherche change
  void _onSearchChanged() {
    setState(() {
      // Le setState déclenchera un rebuild avec les listes filtrées
    });
  }

  Future<void> _loadHikes() async {
    final mapServicesState = ref.read(mapServicesProvider);
    final hikesApiService = ref.read(hikesApiServiceProvider);
    final currentPosition = mapServicesState.currentPosition;

    if (currentPosition == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Récupérer toutes les randonnées
      final response = await hikesApiService.getHikes(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        radius: 20,
        limit: 20,
      );

      setState(() {
        if (response != null) {
          // Les recommandations sont les randonnées officielles
          _recommendedHikes = response.items
              .where((hike) => hike.source == HikeSource.official)
              .toList();
          // Les randonnées de la communauté
          _communityHikes = response.items
              .where((hike) => hike.source == HikeSource.community)
              .toList();
        } else {
          _recommendedHikes = [];
          _communityHikes = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Filtre les randonnées par nom ou localisation
  List<HikeDto> _filterHikes(List<HikeDto> hikes) {
    var filtered = hikes;

    // Filtre par texte de recherche
    final searchText = _searchController.text.toLowerCase().trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((hike) {
        final name = hike.name.toLowerCase();
        final location = hike.location.toLowerCase();
        return name.contains(searchText) || location.contains(searchText);
      }).toList();
    }

    // Filtre par difficulté (peut être multiple)
    if (_selectedDifficulties.isNotEmpty) {
      filtered = filtered.where((hike) {
        return _selectedDifficulties.any((difficulty) {
          switch (difficulty) {
            case DifficultyFilter.easy:
              return hike.difficulty == HikeDifficulty.easy;
            case DifficultyFilter.medium:
              return hike.difficulty == HikeDifficulty.medium;
            case DifficultyFilter.hard:
              return hike.difficulty == HikeDifficulty.hard;
          }
        });
      }).toList();
    }

    // Filtre par distance
    if (_distanceRange != null) {
      filtered = filtered.where((hike) {
        final distanceKm = hike.distance / 1000;
        return distanceKm >= _distanceRange!.start &&
            distanceKm <= _distanceRange!.end;
      }).toList();
    }

    // Tri
    if (_selectedSort != null) {
      switch (_selectedSort!) {
        case SortOption.closest:
          // Trier par distance (déjà trié par l'API normalement)
          filtered.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case SortOption.mostPopular:
          // TODO: Trier par popularité quand disponible dans HikeDto
          break;
      }
    }

    return filtered;
  }

  /// Retourne les randonnées recommandées filtrées
  List<HikeDto> get _filteredRecommendedHikes {
    return _filterHikes(_recommendedHikes);
  }

  /// Retourne les randonnées de la communauté filtrées
  List<HikeDto> get _filteredCommunityHikes {
    return _filterHikes(_communityHikes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.15,
                  right: 16,
                ),
                child: _buildSearchField(),
              ),
            ),
          ),
          title: const SizedBox.shrink(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Séparateur horizontal
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 1,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            // Filtres rapides scrollables
            _buildQuickFilters(),
            const SizedBox(height: 16),
            // Contenu scrollable
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 32,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.5),
            border: Border.all(color: Colors.black, width: 0.5),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(
              fontFamily: 'Lexend Deca',
              fontSize: 14,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher un parcours',
              hintStyle: TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.7),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 5),
                child: Icon(Icons.search, color: Colors.black, size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 20,
              ),
              suffixIcon: InkWell(
                onTap: () => _showFiltersBottomSheet(),
                borderRadius: BorderRadius.circular(15.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _hasActiveFilters()
                          ? AppColors.secondaryColor
                          : AppColors.tertiaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 0.5),
                    ),
                    child: Center(
                      child: Icon(
                        _hasActiveFilters() ? Icons.filter_alt : Icons.tune,
                        color: Colors.black,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(
                left: 0,
                right: 16,
                top: 9,
                bottom: 9,
              ),
            ),
            onSubmitted: (value) {
              // Le filtrage se fait automatiquement via le listener
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = [
      const QuickFilter(name: 'Tous', icon: Icons.public),
      const QuickFilter(name: 'Monument', icon: Icons.account_balance),
      const QuickFilter(name: 'Vue panoramique', icon: Icons.landscape),
      const QuickFilter(name: 'Balade forestière', icon: Icons.forest),
      const QuickFilter(name: 'Montagne', icon: Icons.terrain),
      const QuickFilter(name: 'Mer', icon: Icons.water),
    ];

    return QuickFilters(
      filters: filters,
      selectedIndices: _selectedFilterIndices,
      onFilterChanged: (index, isSelected) {
        setState(() {
          if (isSelected) {
            // Sélectionner
            if (index == 0) {
              // Si on sélectionne "Tous", on désélectionne toutes les autres
              _selectedFilterIndices.clear();
              _selectedFilterIndices.add(0);
            } else {
              // Si on sélectionne un autre filtre, on désélectionne "Tous"
              _selectedFilterIndices.remove(0);
              _selectedFilterIndices.add(index);
            }
          } else {
            // Désélectionner
            _selectedFilterIndices.remove(index);
            // Si on désélectionne tout, on réactive "Tous"
            if (_selectedFilterIndices.isEmpty) {
              _selectedFilterIndices.add(0);
            }
          }
        });
        // TODO: Filtrer par filtre rapide
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final filteredRecommended = _filteredRecommendedHikes;
    final filteredCommunity = _filteredCommunityHikes;

    // Si aucun résultat après filtrage
    if (filteredRecommended.isEmpty && filteredCommunity.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            _searchController.text.trim().isEmpty
                ? 'Aucune randonnée disponible'
                : 'Aucune randonnée trouvée pour "${_searchController.text}"',
            style: const TextStyle(
              fontFamily: 'Lexend Deca',
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Section "Nos recommandations"
        if (filteredRecommended.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionTitle('Nos recommandations'),
          ),
          const SizedBox(height: 16),
          _buildRecommendationsList(filteredRecommended),
          const SizedBox(height: 32),
        ],
        // Section "Par la communauté"
        if (filteredCommunity.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionTitle('Par la communauté'),
          ),
          const SizedBox(height: 16),
          _buildRecommendationsList(filteredCommunity),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Lexend Deca',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRecommendationsList(List<HikeDto> hikes) {
    if (hikes.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 243,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: hikes.length,
        itemBuilder: (context, index) {
          return _buildRecommendationCard(hikes[index]);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(HikeDto hike) {
    // Convertir la distance de mètres en km
    final distanceKm = (hike.distance / 1000).toStringAsFixed(1);

    // Convertir la difficulté
    String difficultyText;
    switch (hike.difficulty) {
      case HikeDifficulty.easy:
        difficultyText = 'Facile';
        break;
      case HikeDifficulty.medium:
        difficultyText = 'Moyen';
        break;
      case HikeDifficulty.hard:
        difficultyText = 'Difficile';
        break;
    }

    // Calculer l'élévation (différence entre arrivée et départ)
    final elevation = (hike.arrivalElevation - hike.startingElevation).abs();
    final elevationText = '${elevation}m';

    // Générer l'URL de la carte statique à partir du tracé
    final mapThumbnailUrl = MapboxStaticImageService.generateHikeThumbnailUrl(
      hike,
    );

    return HikeCard(
      title: hike.name,
      location: hike.location,
      distance: '${distanceKm}km',
      difficulty: difficultyText,
      elevation: elevationText,
      mapThumbnailUrl: mapThumbnailUrl,
      onTap: () {
        _navigateToHikeDetails(hike);
      },
    );
  }

  /// Convertit un HikeDto en Map pour HikeDetailPage et navigue vers la page de détails
  void _navigateToHikeDetails(HikeDto hike) {
    // Convertir la distance en km
    final distanceKm = (hike.distance / 1000).toStringAsFixed(1);

    // Calculer le dénivelé
    final elevation = (hike.arrivalElevation - hike.startingElevation).abs();
    final elevationText = '${elevation}m';

    // Créer le Map avec les informations attendues par HikeDetailPage
    final hikeInfo = <String, dynamic>{
      'name': hike.name,
      'location': hike.location,
      'region': hike.location, // Fallback pour region
      'distance': '${distanceKm}km',
      'denivele': elevationText,
      'duree': hike.formattedDuration,
      'wkb': hike.wkbGeometry,
      'startLat': hike.startingPointLatitude,
      'startLon': hike.startingPointLongitude,
      'id': hike.id, // Garder l'ID pour référence
      'source': hike.source.value, // Source (OFFICIAL ou COMMUNITY)
    };

    // Naviguer vers la page de détails
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HikeDetailPage(hikeInfo: hikeInfo)),
    );
  }

  /// Vérifie si des filtres sont actifs (hors tri par défaut et filtres rapides)
  bool _hasActiveFilters() {
    // Vérifier si un tri autre que "Le plus proche" est sélectionné
    if (_selectedSort != null && _selectedSort != SortOption.closest) {
      return true;
    }
    // Vérifier si des difficultés sont sélectionnées
    if (_selectedDifficulties.isNotEmpty) {
      return true;
    }
    // Vérifier si la distance a été modifiée (pas la valeur par défaut 0-180)
    if (_distanceRange != null &&
        (_distanceRange!.start != 0 || _distanceRange!.end != 180)) {
      return true;
    }
    return false;
  }

  /// Affiche la bottom sheet des filtres
  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FiltersBottomSheet(
        initialSort: _selectedSort,
        initialDifficulties: _selectedDifficulties,
        initialDistance: _distanceRange,
        onApply: (sort, difficulties, distance) {
          setState(() {
            _selectedSort = sort;
            _selectedDifficulties = difficulties;
            _distanceRange = distance;
          });
        },
      ),
    );
  }
}
