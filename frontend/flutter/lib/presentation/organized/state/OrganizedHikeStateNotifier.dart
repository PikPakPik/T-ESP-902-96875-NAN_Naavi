import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/services/mapbox_directions_service.dart';
import '../../../core/services/geometry/geometry_calculation_service.dart';
import '../../../data/models/organized_hike_option.dart';
import '../../../data/models/organized_waypoint.dart';
import '../../../data/models/route_statistics.dart';
import 'OrganizedHikeState.dart';

/// Gère la création et la modification des options de randonnée organisée
/// Maximum 4 options simultanées
class OrganizedHikeStateNotifier extends StateNotifier<OrganizedHikeState> {
  OrganizedHikeStateNotifier() : super(const OrganizedHikeIdle());

  /// Démarre la création d'une nouvelle option
  /// Si c'est la première option, index = 0, sinon index = nombre d'options existantes
  void startNewOption() {
    final currentState = state;

    // Récupérer les options existantes selon l'état
    final existingOptions = switch (currentState) {
      OrganizedHikeOptionComplete(allOptions: final opts) => opts,
      OrganizedHikeSelectingStart(existingOptions: final opts) => opts,
      OrganizedHikeSelectingDestination(allOptions: final opts) => opts,
      OrganizedHikeCalculatingRoute(allOptions: final opts) => opts,
      OrganizedHikeError(existingOptions: final opts) => opts ?? [],
      _ => <OrganizedHikeOption>[],
    };

    // Vérifier qu'on ne dépasse pas 4 options
    if (existingOptions.length >= 4) {
      state = OrganizedHikeError(
        message: 'Maximum 4 options',
        reasons: ['Vous avez déjà créé 4 options'],
        existingOptions: existingOptions,
      );
      return;
    }

    // Passer en mode sélection de départ pour la nouvelle option
    state = OrganizedHikeSelectingStart(
      optionIndex: existingOptions.length,
      existingOptions: existingOptions,
    );
  }

  /// Définit le point de départ depuis la position GPS actuelle
  Future<void> setStartPointFromCurrentLocation(
    gl.Position currentPosition,
  ) async {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingStart) {
      return;
    }

    try {
      // Créer le waypoint de départ
      final startWaypoint = OrganizedWaypoint.fromCurrentLocation(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      // Créer la nouvelle option
      final newOption = OrganizedHikeOption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Option ${currentState.optionIndex + 1}',
        waypoints: [startWaypoint],
      );

      // Passer en mode sélection de destination
      final allOptions = [...currentState.existingOptions, newOption];
      state = OrganizedHikeSelectingDestination(
        optionIndex: currentState.optionIndex,
        currentOption: newOption,
        allOptions: allOptions,
      );
    } catch (e) {
      state = OrganizedHikeError(
        message: 'Erreur lors de la définition du point de départ',
        reasons: [e.toString()],
        existingOptions: currentState.existingOptions,
      );
    }
  }

  /// Active le mode sélection manuelle du point de départ
  void startManualStartSelection() {
    final currentState = state;

    if (currentState is OrganizedHikeSelectingStart) {
      state = currentState.copyWith(isSelectingManually: true);
    }
  }

  /// Annule le mode sélection manuelle (réaffiche la bottom sheet)
  void cancelManualStartSelection() {
    final currentState = state;

    if (currentState is OrganizedHikeSelectingStart) {
      state = currentState.copyWith(
        isSelectingManually: false,
        clearPreview: true,
      );
    }
  }

  /// Prévisualise un point de départ sur la carte (sans le valider)
  void previewStartPoint({
    required double latitude,
    required double longitude,
  }) {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingStart) {
      return;
    }

    state = currentState.copyWith(
      previewLatitude: latitude,
      previewLongitude: longitude,
      isSelectingManually: false, // On cache la popup
    );
  }

  /// Définit directement le point de départ depuis un tap sur la carte
  /// Crée immédiatement le waypoint et passe en mode sélection de destination
  Future<void> setStartPointFromMapTap({
    required double latitude,
    required double longitude,
  }) async {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingStart) {
      return;
    }

    try {
      // Créer le waypoint de départ directement
      final startWaypoint = OrganizedWaypoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: Position(longitude, latitude),
        type: WaypointType.start,
        name: 'Point de départ',
        isCurrentLocation: false,
      );

      // Créer la nouvelle option
      final newOption = OrganizedHikeOption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Option ${currentState.optionIndex + 1}',
        waypoints: [startWaypoint],
      );

      // Passer en mode sélection de destination
      final allOptions = [...currentState.existingOptions, newOption];
      state = OrganizedHikeSelectingDestination(
        optionIndex: currentState.optionIndex,
        currentOption: newOption,
        allOptions: allOptions,
      );
    } catch (e) {
      state = OrganizedHikeError(
        message: 'Erreur lors de la définition du point de départ',
        reasons: [e.toString()],
        existingOptions: currentState.existingOptions,
      );
    }
  }

  /// Annule la prévisualisation du point de départ
  void cancelPreviewStartPoint() {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingStart) {
      return;
    }

    state = currentState.copyWith(
      clearPreview: true,
      isSelectingManually: true, // On réaffiche la popup
    );
  }

  /// Valide le point de départ prévisualisé
  Future<void> confirmPreviewStartPoint() async {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingStart ||
        !currentState.hasPreviewStart) {
      return;
    }

    try {
      // Créer le waypoint de départ
      final startWaypoint = OrganizedWaypoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: Position(
          currentState.previewLongitude!,
          currentState.previewLatitude!,
        ),
        type: WaypointType.start,
        name: 'Point de départ',
        isCurrentLocation: false,
      );

      // Créer la nouvelle option
      final newOption = OrganizedHikeOption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Option ${currentState.optionIndex + 1}',
        waypoints: [startWaypoint],
      );

      // Passer en mode sélection de destination
      final allOptions = [...currentState.existingOptions, newOption];
      state = OrganizedHikeSelectingDestination(
        optionIndex: currentState.optionIndex,
        currentOption: newOption,
        allOptions: allOptions,
      );
    } catch (e) {
      state = OrganizedHikeError(
        message: 'Erreur lors de la définition du point de départ',
        reasons: [e.toString()],
        existingOptions: currentState.existingOptions,
      );
    }
  }

  /// Ajoute une destination (ou waypoint intermédiaire)
  Future<void> addDestination({
    required double latitude,
    required double longitude,
    String? name,
  }) async {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingDestination) {
      return;
    }

    try {
      // Créer le waypoint de destination
      final destinationWaypoint = OrganizedWaypoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: Position(longitude, latitude),
        type: WaypointType.destination,
        name: name ?? 'Destination',
      );

      // Ajouter le waypoint à l'option actuelle
      final updatedWaypoints = [
        ...currentState.currentOption.waypoints,
        destinationWaypoint,
      ];

      final updatedOption = currentState.currentOption.copyWith(
        waypoints: updatedWaypoints,
      );

      // Passer en mode calcul d'itinéraire
      final allOptions = currentState.allOptions.map((opt) {
        return opt.id == updatedOption.id ? updatedOption : opt;
      }).toList();

      state = OrganizedHikeCalculatingRoute(
        optionIndex: currentState.optionIndex,
        option: updatedOption,
        allOptions: allOptions,
      );

      // Lancer le calcul de l'itinéraire
      await _calculateRoute(updatedOption, allOptions);
    } catch (e) {
      state = OrganizedHikeError(
        message: 'Erreur lors de l\'ajout de la destination',
        reasons: [e.toString()],
        existingOptions: currentState.allOptions,
      );
    }
  }

  /// Calcule l'itinéraire entre les waypoints via Mapbox Directions
  Future<void> _calculateRoute(
    OrganizedHikeOption option,
    List<OrganizedHikeOption> allOptions,
  ) async {
    try {
      // Préparer les coordonnées pour Mapbox Directions
      final waypoints = option.waypoints;
      if (waypoints.length < 2) {
        throw Exception('Au moins 2 waypoints nécessaires');
      }

      // Convertir tous les waypoints en coordonnées [lon, lat]
      final waypointCoordinates = waypoints
          .map((wp) => [wp.position.lng.toDouble(), wp.position.lat.toDouble()])
          .toList();

      // Appel à Mapbox Directions API avec tous les waypoints
      final route = await MapboxDirectionsService.getWalkingRouteWithWaypoints(
        waypoints: waypointCoordinates,
      );

      if (route == null || route.isEmpty) {
        throw Exception('Impossible de calculer l\'itinéraire');
      }

      // Calculer la distance totale en suivant le tracé
      double distanceKm = 0.0;
      for (int i = 0; i < route.length - 1; i++) {
        distanceKm += GeometryCalculationService.calculateDistanceKm(
          route[i][1], // lat
          route[i][0], // lon
          route[i + 1][1], // lat
          route[i + 1][0], // lon
        );
      }

      // Estimer le temps (vitesse moyenne 5 km/h)
      final estimatedDuration = Duration(
        minutes: ((distanceKm / 5.0) * 60).round(),
      );

      // Créer les statistiques (dénivelé sera calculé pendant le tracking)
      final statistics = RouteStatistics(
        distanceKm: distanceKm,
        elevationGainM: 0, // Sera calculé pendant le tracking
        estimatedDuration: estimatedDuration,
      );

      // Mettre à jour l'option avec le tracé et les stats
      final updatedOption = option.copyWith(
        routeCoordinates: route,
        statistics: statistics,
      );

      // Mettre à jour la liste des options
      final updatedAllOptions = allOptions.map((opt) {
        return opt.id == updatedOption.id ? updatedOption : opt;
      }).toList();

      // Obtenir l'index de l'option mise à jour
      final optionIndex = updatedAllOptions.indexWhere(
        (opt) => opt.id == updatedOption.id,
      );

      // Passer en mode option complète
      state = OrganizedHikeOptionComplete(
        currentOptionIndex: optionIndex,
        allOptions: updatedAllOptions,
      );
    } catch (e) {
      state = OrganizedHikeError(
        message: 'Erreur lors du calcul de l\'itinéraire',
        reasons: [e.toString()],
        existingOptions: allOptions,
      );
    }
  }

  /// Passe en mode ajout d'étape depuis une option complète
  /// insertAtIndex indique où insérer la nouvelle étape (null = à la fin)
  /// minimizeSheet: si true, la sheet sera minimisée pour montrer le bouton drag & drop
  void startAddingWaypoint({int? insertAtIndex, bool minimizeSheet = true}) {
    final currentState = state;

    if (currentState is! OrganizedHikeOptionComplete) {
      return;
    }

    final currentOption = currentState.currentOption;

    state = OrganizedHikeSelectingDestination(
      optionIndex: currentState.currentOptionIndex,
      currentOption: currentOption,
      allOptions: currentState.allOptions,
      insertAtIndex: insertAtIndex,
      isSheetMinimized: minimizeSheet,
    );
  }

  /// Minimise la bottom sheet (active le mode drag & drop)
  void minimizeSheet() {
    final currentState = state;

    if (currentState is OrganizedHikeSelectingDestination) {
      state = currentState.copyWith(isSheetMinimized: true);
    }
  }

  /// Expand la bottom sheet (désactive le mode drag & drop)
  void expandSheet() {
    final currentState = state;

    if (currentState is OrganizedHikeSelectingDestination) {
      state = currentState.copyWith(isSheetMinimized: false);
    }
  }

  /// Ferme la popup "Toucher la carte" (mais reste en mode sélection)
  void dismissDestinationPopup() {
    final currentState = state;

    if (currentState is OrganizedHikeSelectingDestination &&
        currentState.isSheetMinimized) {
      state = currentState.copyWith(
        isSheetMinimized: false,
        clearPreview: true,
      );
    }
  }

  /// Prévisualise une destination sur la carte (sans la valider)
  void previewDestination({
    required double latitude,
    required double longitude,
  }) {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingDestination) {
      return;
    }

    state = currentState.copyWith(
      previewLatitude: latitude,
      previewLongitude: longitude,
      isSheetMinimized: false, // On cache la popup "Toucher la carte"
    );
  }

  /// Annule la prévisualisation de destination
  void cancelPreviewDestination() {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingDestination) {
      return;
    }

    state = currentState.copyWith(
      clearPreview: true,
      isSheetMinimized: true, // On réaffiche la popup "Toucher la carte"
    );
  }

  /// Valide la destination prévisualisée
  Future<void> confirmPreviewDestination() async {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingDestination ||
        !currentState.hasPreviewDestination) {
      return;
    }

    // Si on a un insertAtIndex, insérer le waypoint à cet index
    if (currentState.insertAtIndex != null) {
      await insertWaypointAt(
        index: currentState.insertAtIndex!,
        latitude: currentState.previewLatitude!,
        longitude: currentState.previewLongitude!,
      );
    } else {
      // Sinon, ajouter à la fin
      await addDestination(
        latitude: currentState.previewLatitude!,
        longitude: currentState.previewLongitude!,
      );
    }
  }

  /// Insère un waypoint à un index spécifique dans l'option actuelle
  Future<void> insertWaypointAt({
    required int index,
    required double latitude,
    required double longitude,
    String? name,
  }) async {
    final currentState = state;

    if (currentState is! OrganizedHikeSelectingDestination) {
      return;
    }

    try {
      final waypoints = List<OrganizedWaypoint>.from(
        currentState.currentOption.waypoints,
      );

      // Créer le nouveau waypoint
      final newWaypoint = OrganizedWaypoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: Position(longitude, latitude),
        type: WaypointType.waypoint,
        name: name ?? 'Étape $index',
      );

      // Insérer à l'index spécifié
      waypoints.insert(index, newWaypoint);

      // Mettre à jour les types des waypoints
      for (int i = 0; i < waypoints.length; i++) {
        WaypointType type;
        if (i == 0) {
          type = WaypointType.start;
        } else if (i == waypoints.length - 1) {
          type = WaypointType.destination;
        } else {
          type = WaypointType.waypoint;
        }
        waypoints[i] = waypoints[i].copyWith(type: type);
      }

      final updatedOption = currentState.currentOption.copyWith(
        waypoints: waypoints,
      );

      // Mettre à jour la liste des options
      final allOptions = currentState.allOptions.map((opt) {
        return opt.id == updatedOption.id ? updatedOption : opt;
      }).toList();

      state = OrganizedHikeCalculatingRoute(
        optionIndex: currentState.optionIndex,
        option: updatedOption,
        allOptions: allOptions,
      );

      // Recalculer l'itinéraire
      await _calculateRoute(updatedOption, allOptions);
    } catch (e) {
      state = OrganizedHikeError(
        message: 'Erreur lors de l\'insertion de l\'étape',
        reasons: [e.toString()],
        existingOptions: currentState.allOptions,
      );
    }
  }

  /// Change l'option actuellement affichée (clic sur onglet)
  void switchToOption(int optionIndex) {
    final currentState = state;

    // Depuis OptionComplete
    if (currentState is OrganizedHikeOptionComplete) {
      if (optionIndex < 0 || optionIndex >= currentState.allOptions.length) {
        return;
      }

      state = OrganizedHikeOptionComplete(
        currentOptionIndex: optionIndex,
        allOptions: currentState.allOptions,
      );
      return;
    }

    // Depuis SelectingDestination (permet de revenir sur une option existante)
    if (currentState is OrganizedHikeSelectingDestination) {
      if (optionIndex < 0 || optionIndex >= currentState.allOptions.length) {
        return;
      }

      // Si c'est la même option, ne rien faire
      if (optionIndex == currentState.optionIndex) {
        return;
      }

      final targetOption = currentState.allOptions[optionIndex];

      // Si l'option cible est complète, passer en OptionComplete
      if (targetOption.isComplete) {
        state = OrganizedHikeOptionComplete(
          currentOptionIndex: optionIndex,
          allOptions: currentState.allOptions,
        );
      } else {
        // L'option cible n'est pas complète, rester en SelectingDestination
        state = OrganizedHikeSelectingDestination(
          optionIndex: optionIndex,
          currentOption: targetOption,
          allOptions: currentState.allOptions,
        );
      }
      return;
    }
  }

  /// Supprime une option
  void deleteOption(int optionIndex) {
    final currentState = state;

    if (currentState is! OrganizedHikeOptionComplete) {
      return;
    }

    final updatedOptions = List<OrganizedHikeOption>.from(
      currentState.allOptions,
    )..removeAt(optionIndex);

    // Si plus d'options, retour à idle
    if (updatedOptions.isEmpty) {
      state = const OrganizedHikeIdle();
      return;
    }

    // Ajuster l'index si nécessaire
    final newIndex = optionIndex >= updatedOptions.length
        ? updatedOptions.length - 1
        : optionIndex;

    state = OrganizedHikeOptionComplete(
      currentOptionIndex: newIndex,
      allOptions: updatedOptions,
    );
  }

  /// Lance le tracking guidé avec l'option sélectionnée
  /// Cette méthode sera appelée depuis le widget quand l'utilisateur clique "Démarrer"
  OrganizedHikeOption? getSelectedOption() {
    final currentState = state;

    if (currentState is OrganizedHikeOptionComplete) {
      return currentState.currentOption;
    }

    return null;
  }

  /// Réinitialise l'état (retour au menu principal)
  void reset() {
    state = const OrganizedHikeIdle();
  }

  /// Retour en arrière selon l'état actuel
  void goBack() {
    final currentState = state;

    switch (currentState) {
      case OrganizedHikeSelectingStart():
        // Si on était en train de sélectionner le départ d'une nouvelle option
        if (currentState.existingOptions.isEmpty) {
          // Première option : retour à idle
          state = const OrganizedHikeIdle();
        } else {
          // Options existantes : retour à l'affichage de la dernière option
          state = OrganizedHikeOptionComplete(
            currentOptionIndex: currentState.existingOptions.length - 1,
            allOptions: currentState.existingOptions,
          );
        }

      case OrganizedHikeSelectingDestination():
        // Retour à la sélection du départ (annule le départ actuel)
        state = OrganizedHikeSelectingStart(
          optionIndex: currentState.optionIndex,
          existingOptions: currentState.allOptions
              .where((opt) => opt.id != currentState.currentOption.id)
              .toList(),
        );

      case OrganizedHikeCalculatingRoute():
      case OrganizedHikeOptionComplete():
        // Retour à idle (ferme la bottomsheet)
        state = const OrganizedHikeIdle();

      case OrganizedHikeError():
        // Retour selon les options existantes
        if (currentState.existingOptions != null &&
            currentState.existingOptions!.isNotEmpty) {
          state = OrganizedHikeOptionComplete(
            currentOptionIndex: currentState.existingOptions!.length - 1,
            allOptions: currentState.existingOptions!,
          );
        } else {
          state = const OrganizedHikeIdle();
        }

      case OrganizedHikeIdle():
        // Déjà idle, ne rien faire
        break;
    }
  }

  /// Confirme la sortie du mode organisé (reset complet)
  void confirmQuit() {
    reset();
  }

  /// Supprime le dernier waypoint ajouté et recalcule le tracé si nécessaire
  Future<void> removeLastWaypoint() async {
    final currentState = state;

    switch (currentState) {
      case OrganizedHikeOptionComplete(
        currentOptionIndex: final index,
        allOptions: final allOptions,
      ):
        final option = allOptions[index];
        final waypoints = option.waypoints;

        if (waypoints.isEmpty) {
          // Pas de waypoints, retour à idle
          state = const OrganizedHikeIdle();
          return;
        }

        if (waypoints.length == 1) {
          // Un seul waypoint (départ) : retour à sélection du départ
          // On garde les autres options si elles existent
          final otherOptions = allOptions
              .where((o) => o.id != option.id)
              .toList();
          state = OrganizedHikeSelectingStart(
            optionIndex: index,
            existingOptions: otherOptions,
          );
          return;
        }

        if (waypoints.length == 2) {
          // Départ + arrivée : supprimer l'arrivée, retour à sélection destination
          final updatedWaypoints = [waypoints.first];
          final updatedOption = option.copyWith(
            waypoints: updatedWaypoints,
            routeCoordinates: null,
            statistics: null,
          );

          final updatedAllOptions = allOptions.map((opt) {
            return opt.id == updatedOption.id ? updatedOption : opt;
          }).toList();

          state = OrganizedHikeSelectingDestination(
            optionIndex: index,
            currentOption: updatedOption,
            allOptions: updatedAllOptions,
          );
          return;
        }

        // 3+ waypoints : supprimer le dernier et recalculer
        final updatedWaypoints = waypoints.sublist(0, waypoints.length - 1);

        // Mettre à jour les types des waypoints
        final correctedWaypoints = <OrganizedWaypoint>[];
        for (int i = 0; i < updatedWaypoints.length; i++) {
          WaypointType type;
          if (i == 0) {
            type = WaypointType.start;
          } else if (i == updatedWaypoints.length - 1) {
            type = WaypointType.destination;
          } else {
            type = WaypointType.waypoint;
          }
          correctedWaypoints.add(updatedWaypoints[i].copyWith(type: type));
        }

        final updatedOption = option.copyWith(waypoints: correctedWaypoints);

        final updatedAllOptions = allOptions.map((opt) {
          return opt.id == updatedOption.id ? updatedOption : opt;
        }).toList();

        // Passer en mode calcul pour recalculer la route
        state = OrganizedHikeCalculatingRoute(
          optionIndex: index,
          option: updatedOption,
          allOptions: updatedAllOptions,
        );

        // Recalculer l'itinéraire
        await _calculateRoute(updatedOption, updatedAllOptions);

      case OrganizedHikeSelectingDestination(
        optionIndex: final index,
        currentOption: final option,
        allOptions: final allOptions,
        previewLatitude: final previewLat,
      ):
        // Si on a une preview destination, juste l'annuler
        if (previewLat != null) {
          state = currentState.copyWith(clearPreview: true);
          return;
        }

        final waypoints = option.waypoints;

        if (waypoints.isEmpty) {
          // Pas de waypoints, retour à sélection du départ
          final otherOptions = allOptions
              .where((o) => o.id != option.id)
              .toList();
          state = OrganizedHikeSelectingStart(
            optionIndex: index,
            existingOptions: otherOptions,
          );
          return;
        }

        if (waypoints.length == 1) {
          // Un seul waypoint (départ) : retour à sélection du départ
          final otherOptions = allOptions
              .where((o) => o.id != option.id)
              .toList();
          state = OrganizedHikeSelectingStart(
            optionIndex: index,
            existingOptions: otherOptions,
          );
          return;
        }

        // 2+ waypoints : supprimer le dernier
        final updatedWaypoints = waypoints.sublist(0, waypoints.length - 1);

        // Mettre à jour les types
        final correctedWaypoints = <OrganizedWaypoint>[];
        for (int i = 0; i < updatedWaypoints.length; i++) {
          WaypointType type;
          if (i == 0) {
            type = WaypointType.start;
          } else if (i == updatedWaypoints.length - 1) {
            type = WaypointType.destination;
          } else {
            type = WaypointType.waypoint;
          }
          correctedWaypoints.add(updatedWaypoints[i].copyWith(type: type));
        }

        final updatedOption = option.copyWith(
          waypoints: correctedWaypoints,
          routeCoordinates: null,
          statistics: null,
        );

        final updatedAllOptions = allOptions.map((opt) {
          return opt.id == updatedOption.id ? updatedOption : opt;
        }).toList();

        if (updatedWaypoints.length == 1) {
          // Retour à sélection destination avec seulement le départ
          state = OrganizedHikeSelectingDestination(
            optionIndex: index,
            currentOption: updatedOption,
            allOptions: updatedAllOptions,
          );
        } else {
          // Recalculer la route
          state = OrganizedHikeCalculatingRoute(
            optionIndex: index,
            option: updatedOption,
            allOptions: updatedAllOptions,
          );
          await _calculateRoute(updatedOption, updatedAllOptions);
        }

      case OrganizedHikeSelectingStart():
        // Déjà en sélection de départ, retour à idle ou options existantes
        if (currentState.existingOptions.isEmpty) {
          state = const OrganizedHikeIdle();
        } else {
          state = OrganizedHikeOptionComplete(
            currentOptionIndex: currentState.existingOptions.length - 1,
            allOptions: currentState.existingOptions,
          );
        }

      default:
        // Pour les autres états, ne rien faire
        break;
    }
  }
}
