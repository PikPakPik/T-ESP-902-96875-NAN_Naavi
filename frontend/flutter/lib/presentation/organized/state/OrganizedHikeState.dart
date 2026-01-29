import '../../../data/models/organized_hike_option.dart';

/// État du système d'organisation de randonnée
/// Gère la création, modification et sélection d'options
sealed class OrganizedHikeState {
  const OrganizedHikeState();
}

/// Idle - Aucune organisation en cours
class OrganizedHikeIdle extends OrganizedHikeState {
  const OrganizedHikeIdle();
}

/// Sélection du point de départ pour une option
class OrganizedHikeSelectingStart extends OrganizedHikeState {
  final int optionIndex; // Index de l'option en cours d'édition (0-3)
  final List<OrganizedHikeOption> existingOptions; // Options déjà créées
  final bool isSelectingManually; // True si on sélectionne manuellement sur la carte
  final double? previewLatitude; // Coordonnées de prévisualisation du point de départ
  final double? previewLongitude;

  const OrganizedHikeSelectingStart({
    required this.optionIndex,
    this.existingOptions = const [],
    this.isSelectingManually = false,
    this.previewLatitude,
    this.previewLongitude,
  });

  /// Nombre d'options déjà créées
  int get optionCount => existingOptions.length;

  /// Peut-on créer une nouvelle option ? (max 4)
  bool get canAddOption => optionCount < 4;

  /// Indique si un point de départ est en prévisualisation
  bool get hasPreviewStart => previewLatitude != null && previewLongitude != null;

  /// Crée une copie avec les modifications
  OrganizedHikeSelectingStart copyWith({
    bool? isSelectingManually,
    double? previewLatitude,
    double? previewLongitude,
    bool clearPreview = false,
  }) {
    return OrganizedHikeSelectingStart(
      optionIndex: optionIndex,
      existingOptions: existingOptions,
      isSelectingManually: isSelectingManually ?? this.isSelectingManually,
      previewLatitude: clearPreview ? null : (previewLatitude ?? this.previewLatitude),
      previewLongitude: clearPreview ? null : (previewLongitude ?? this.previewLongitude),
    );
  }
}

/// Sélection d'une destination/waypoint
class OrganizedHikeSelectingDestination extends OrganizedHikeState {
  final int optionIndex;
  final OrganizedHikeOption currentOption; // Option en cours d'édition
  final List<OrganizedHikeOption> allOptions; // Toutes les options
  final int? insertAtIndex; // Index où insérer le nouveau waypoint (null = à la fin)
  final bool isSheetMinimized; // True si la bottom sheet est minimisée (mode drag & drop actif)
  final double? previewLatitude; // Coordonnées de prévisualisation de la destination
  final double? previewLongitude;

  const OrganizedHikeSelectingDestination({
    required this.optionIndex,
    required this.currentOption,
    required this.allOptions,
    this.insertAtIndex,
    this.isSheetMinimized = false,
    this.previewLatitude,
    this.previewLongitude,
  });

  /// Indique si on insère un waypoint intermédiaire
  bool get isInsertingIntermediate => insertAtIndex != null;

  /// Indique si une destination est en prévisualisation
  bool get hasPreviewDestination => previewLatitude != null && previewLongitude != null;

  /// Crée une copie avec la sheet minimisée/expandée et/ou les coordonnées de prévisualisation
  OrganizedHikeSelectingDestination copyWith({
    bool? isSheetMinimized,
    double? previewLatitude,
    double? previewLongitude,
    bool clearPreview = false,
  }) {
    return OrganizedHikeSelectingDestination(
      optionIndex: optionIndex,
      currentOption: currentOption,
      allOptions: allOptions,
      insertAtIndex: insertAtIndex,
      isSheetMinimized: isSheetMinimized ?? this.isSheetMinimized,
      previewLatitude: clearPreview ? null : (previewLatitude ?? this.previewLatitude),
      previewLongitude: clearPreview ? null : (previewLongitude ?? this.previewLongitude),
    );
  }
}

/// Calcul d'itinéraire en cours
class OrganizedHikeCalculatingRoute extends OrganizedHikeState {
  final int optionIndex;
  final OrganizedHikeOption option;
  final List<OrganizedHikeOption> allOptions;

  const OrganizedHikeCalculatingRoute({
    required this.optionIndex,
    required this.option,
    required this.allOptions,
  });
}

/// Option complète (itinéraire calculé, stats disponibles)
/// L'utilisateur peut voir les détails et créer une autre option
class OrganizedHikeOptionComplete extends OrganizedHikeState {
  final int currentOptionIndex; // Option actuellement affichée
  final List<OrganizedHikeOption> allOptions; // Toutes les options créées

  const OrganizedHikeOptionComplete({
    required this.currentOptionIndex,
    required this.allOptions,
  });

  /// Option actuellement affichée
  OrganizedHikeOption get currentOption => allOptions[currentOptionIndex];

  /// Peut-on créer une autre option ?
  bool get canAddOption => allOptions.length < 4;

  /// Y a-t-il plusieurs options (afficher les onglets) ?
  bool get hasMultipleOptions => allOptions.length > 1;

  /// Nombre total d'options
  int get optionCount => allOptions.length;
}

/// Erreur (calcul échoué, GPS non disponible, etc.)
class OrganizedHikeError extends OrganizedHikeState {
  final String message;
  final List<String> reasons;
  final List<OrganizedHikeOption>? existingOptions; // Options déjà créées

  const OrganizedHikeError({
    required this.message,
    this.reasons = const [],
    this.existingOptions,
  });
}