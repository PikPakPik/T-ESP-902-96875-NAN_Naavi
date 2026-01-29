import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:geolocator_apple/geolocator_apple.dart' hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/core/services/map/route_marker_service.dart';
import 'dart:async';

import '../../../data/models/HikeModel.dart';
import '../../../domain/entities/Hike.dart';

/// État du tracking de localisation
enum TrackingState { idle, ready, tracking, finished, paused }

/// Service pour gérer le tracking de localisation et l'affichage sur la carte
class TrackingLocationService {
  // Constantes de configuration
  static const int _distanceFilter = 5;
  static const double _lineWidth = 5.0;
  static const Duration _cleanupDelay = Duration(milliseconds: 200);
  static const gl.LocationAccuracy _locationAccuracy =
      gl.LocationAccuracy.bestForNavigation;

  // Gestion du stream de position
  StreamSubscription<gl.Position>? _positionSub;
  TrackingState _currentState = TrackingState.idle;

  // Références à la carte et aux managers
  MapboxMap? _mapboxMapController;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;

  // Collections d'annotations
  final List<PolylineAnnotation> _polylines = [];
  final List<PointAnnotation> _pointAnnotations = [];

  // Données de tracking
  List<gl.Position> _currentSegment = [];
  final List<List<gl.Position>> _trackingSegments = [];
  PointAnnotation? _lastPausePoint;

  // État utilisateur
  bool isUserExploring = false;
  void Function(gl.Position)? onNewPosition;

  // Getters
  TrackingState get currentState => _currentState;
  bool get isTracking => _currentState == TrackingState.tracking;
  bool get isPaused => _currentState == TrackingState.paused;

  /// Définit le contrôleur de la carte
  void setMapController(MapboxMap controller) {
    _mapboxMapController = controller;
  }

  /// Initialise une nouvelle randonnée avec un point de départ
  Future<void> setStartPoint(
    gl.Position? currentPosition,
    MapboxMap? mapBoxMapController,
  ) async {
    if (currentPosition == null || mapBoxMapController == null) {
      return;
    }

    await _stopPositionStream();
    _resetState();
    await _initializeManagers(mapBoxMapController);
    await _resetTrackingState(currentPosition);
    await _clearAllAnnotations();
    await _createStartPoint(currentPosition);
    await _updatePolylines();
  }

  /// Définit le point d'arrivée et termine le tracking
  Future<void> setEndPoint(
    gl.Position? currentPosition,
    MapboxMap? mapBoxMapController,
  ) async {
    if (mapBoxMapController == null || currentPosition == null) return;

    // Si en pause, remplacer le point "Pause" par "Finish"
    if (isPaused && _lastPausePoint != null) {
      final pausePosition = _getPausePosition();
      if (pausePosition != null) {
        currentPosition = pausePosition;
        await _replacePauseWithFinish();
      }
    }

    await _finalizeCurrentSegment(currentPosition);
    _currentState = TrackingState.finished;
    await _createFinishPoint(currentPosition);
    await _updatePolylines();
  }

  /// Démarre le tracking de position
  Future<void> startTracking(MapboxMap mapBoxMapController) async {
    if (!await _checkLocationPermissions()) {
      return;
    }

    await _stopPositionStream();
    _positionSub = _createPositionStream(_handleTrackingPosition);
  }

  /// Arrête le tracking de position
  void stopTracking() {
    _stopPositionStream();
  }

  /// Met en pause le tracking
  Future<void> pauseTracking() async {
    _positionSub?.cancel();

    // Sauvegarder le segment actuel s'il contient des points
    if (_currentSegment.isNotEmpty) {
      _trackingSegments.add(List.from(_currentSegment));

      // Créer le point de pause (bleu ciel) avec RouteMarkerService
      if (_mapboxMapController != null) {
        final lastPosition = _currentSegment.last;
        await RouteMarkerService.displayPauseMarker(
          mapboxMap: _mapboxMapController!,
          latitude: lastPosition.latitude,
          longitude: lastPosition.longitude,
          prefix: 'improvise',
        );
      }

      // Vider le segment actuel pour éviter qu'il soit compté deux fois
      _currentSegment = [];
    }

    _currentState = TrackingState.paused;
  }

  /// Reprend le tracking après une pause
  Future<void> continueTracking() async {
    if (!isPaused || _mapboxMapController == null) {
      return;
    }

    if (!await _checkLocationPermissions()) {
      return;
    }

    _currentSegment = [];
    _lastPausePoint = null;

    await _stopPositionStream();
    _positionSub = _createPositionStream(_handleResumePosition);
  }

  /// Nettoie toutes les annotations et réinitialise l'état
  Future<void> clearTracking() async {
    await _stopPositionStream();
    await _clearAllPolylines();
    await _clearAllPoints();
    // Nettoyer les markers de départ/arrivée du RouteMarkerService
    if (_mapboxMapController != null) {
      await RouteMarkerService.removeAllMarkers(
        mapboxMap: _mapboxMapController!,
        prefix: 'improvise',
      );
    }
    // Réinitialiser le compteur de markers de pause
    RouteMarkerService.resetPauseMarkerCount();
    _resetState();
    await Future.delayed(_cleanupDelay);
  }

  /// Restaure une randonnée sauvegardée sur la carte
  Future<void> restoreHike(Hike hike, MapboxMap mapBoxMapController) async {
    _mapboxMapController = mapBoxMapController;
    await _initializeManagers(mapBoxMapController);
    await _clearAllAnnotations();
    _resetState();
    _currentState = TrackingState.paused;

    // Créer le point de départ
    final startPosition = _pathPointToPosition(hike.startPoint);
    await _createStartPoint(startPosition);

    // Créer les polylines pour chaque chemin
    for (var path in hike.paths) {
      await _createPolylineFromPath(path);
    }

    // Créer le point d'arrivée si présent
    if (hike.endPoint != null) {
      final endPosition = _pathPointToPosition(hike.endPoint!);
      await _createFinishPoint(endPosition);
    }
  }

  /// Retourne la dernière position connue
  gl.Position? getLastKnownPosition() {
    if (_currentSegment.isNotEmpty) {
      return _currentSegment.last;
    }

    if (_trackingSegments.isNotEmpty) {
      final lastSegment = _trackingSegments.last;
      if (lastSegment.isNotEmpty) {
        return lastSegment.last;
      }
    }

    return null;
  }

  /// Retourne tous les segments de tracking
  List<List<gl.Position>> getAllSegments() {
    List<List<gl.Position>> allSegments = List.from(_trackingSegments);

    // Ajouter le segment en cours s'il contient des points
    if (_currentSegment.isNotEmpty) {
      allSegments.add(List.from(_currentSegment));
    }

    return allSegments;
  }

  /// Retourne le chemin actuel sous forme de PathPoints
  Future<List<List<PathPoint>>> getCurrentPath() async {
    List<List<PathPoint>> paths = [];

    for (var segment in _trackingSegments) {
      if (segment.length >= 2) {
        paths.add(_convertSegmentToPathPoints(segment));
      }
    }

    if (_currentSegment.length >= 2) {
      paths.add(_convertSegmentToPathPoints(_currentSegment));
    }

    return paths;
  }

  /// Met à jour l'état d'exploration de l'utilisateur
  void setUserExploring(bool exploring) {
    isUserExploring = exploring;
  }

  /// Libère les ressources
  void dispose() {
    _stopPositionStream();
    _pointManager = null;
    _polylineManager = null;
    _polylines.clear();
    _pointAnnotations.clear();
    _lastPausePoint = null;
  }

  // ==================== Méthodes privées ====================

  /// Initialise les managers d'annotations
  /// Le polyline est créé SOUS le layer de localisation pour que la flèche passe au-dessus
  Future<void> _initializeManagers(MapboxMap mapBoxMapController) async {
    // Créer le polyline manager en dessous du layer de localisation (puck)
    // Cela permet à la flèche de navigation de passer AU-DESSUS du tracé
    _polylineManager ??= await mapBoxMapController.annotations
        .createPolylineAnnotationManager(
          below: 'mapbox-location-indicator-layer',
        );

    // Les points (départ, arrivée) sont créés normalement au-dessus
    _pointManager ??= await mapBoxMapController.annotations
        .createPointAnnotationManager();
  }

  /// Réinitialise l'état du tracking
  Future<void> _resetTrackingState(gl.Position startPosition) async {
    _currentSegment = [startPosition];
    _currentState = TrackingState.ready;
    _trackingSegments.clear();
    _lastPausePoint = null;
  }

  /// Réinitialise l'état interne
  void _resetState() {
    _currentState = TrackingState.idle;
    _currentSegment.clear();
    _trackingSegments.clear();
    _lastPausePoint = null;
    _polylines.clear();
    _pointAnnotations.clear();
    isUserExploring = false;
  }

  /// Vérifie et demande les permissions de localisation
  Future<bool> _checkLocationPermissions() async {
    try {
      final serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {}
        return false;
      }

      var permission = await gl.Geolocator.checkPermission();
      if (permission == gl.LocationPermission.denied) {
        permission = await gl.Geolocator.requestPermission();
        if (permission == gl.LocationPermission.denied ||
            permission == gl.LocationPermission.deniedForever) {
          if (kDebugMode) {}
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {}
      return false;
    }
  }

  /// Crée les settings de localisation appropriés pour la plateforme
  gl.LocationSettings _createLocationSettings() {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: _locationAccuracy,
        distanceFilter: _distanceFilter,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      return gl.LocationSettings(
        accuracy: _locationAccuracy,
        distanceFilter: _distanceFilter,
      );
    }
  }

  /// Crée un stream de position avec gestion d'erreur
  StreamSubscription<gl.Position> _createPositionStream(
    Future<void> Function(gl.Position) onPosition,
  ) {
    return gl.Geolocator.getPositionStream(
      locationSettings: _createLocationSettings(),
    ).listen(
      (position) async {
        try {
          await onPosition(position);
        } catch (e) {
          _logError('Erreur lors du traitement de la position', e);
        }
      },
      onError: (error) {
        _logError('Erreur dans le stream de position', error);
      },
      cancelOnError: false,
    );
  }

  /// Gère les nouvelles positions pendant le tracking
  Future<void> _handleTrackingPosition(gl.Position position) async {
    _currentSegment.add(position);
    _currentState = TrackingState.tracking;
    onNewPosition?.call(position);

    if (_mapboxMapController != null) {
      // Délai de 150ms pour synchroniser le tracé avec l'animation de la flèche
      // Le puck se déplace avec une interpolation fluide, on attend qu'il commence
      // son mouvement avant de dessiner le tracé
      await Future.delayed(const Duration(milliseconds: 150));
      await _updatePolylines();
    }
  }

  /// Gère les nouvelles positions lors de la reprise
  Future<void> _handleResumePosition(gl.Position position) async {
    if (_currentSegment.isEmpty) {
      _currentSegment.add(position);
      await _createResumePoint(position);
    } else {
      _currentSegment.add(position);
    }

    _currentState = TrackingState.tracking;

    if (_mapboxMapController != null) {
      // Même délai de synchronisation pour la cohérence avec le tracking normal
      await Future.delayed(const Duration(milliseconds: 150));
      await _updatePolylines();
    }
  }

  /// Arrête le stream de position
  Future<void> _stopPositionStream() async {
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Crée le point de départ (vert)
  Future<void> _createStartPoint(gl.Position position) async {
    if (kDebugMode) {}
    // Utiliser le RouteMarkerService pour le marker vert de départ
    if (_mapboxMapController != null) {
      await RouteMarkerService.displayStartMarker(
        mapboxMap: _mapboxMapController!,
        latitude: position.latitude,
        longitude: position.longitude,
        prefix: 'improvise',
      );
    }
  }

  /// Crée le point d'arrivée (rouge)
  Future<void> _createFinishPoint(gl.Position position) async {
    // Utiliser le RouteMarkerService pour le marker rouge d'arrivée
    if (_mapboxMapController != null) {
      await RouteMarkerService.displayEndMarker(
        mapboxMap: _mapboxMapController!,
        latitude: position.latitude,
        longitude: position.longitude,
        prefix: 'improvise',
      );
    }
  }

  /// Crée le point de reprise (bleu ciel comme le point de pause)
  Future<void> _createResumePoint(gl.Position position) async {
    if (_mapboxMapController == null) return;

    await RouteMarkerService.displayPauseMarker(
      mapboxMap: _mapboxMapController!,
      latitude: position.latitude,
      longitude: position.longitude,
      prefix: 'improvise',
    );
  }

  /// Récupère la position du point de pause
  gl.Position? _getPausePosition() {
    if (_currentSegment.isNotEmpty) {
      return _currentSegment.last;
    }

    if (_trackingSegments.isNotEmpty) {
      final lastSegment = _trackingSegments.last;
      if (lastSegment.isNotEmpty) {
        return lastSegment.last;
      }
    }

    return null;
  }

  /// Remplace le point "Pause" par "Finish"
  Future<void> _replacePauseWithFinish() async {
    if (_lastPausePoint != null && _pointManager != null) {
      try {
        await _pointManager!.delete(_lastPausePoint!);
        _pointAnnotations.remove(_lastPausePoint);
      } catch (e) {
        _logError('Erreur lors de la suppression du point Pause', e);
      }
      _lastPausePoint = null;
    }
  }

  /// Finalise le segment actuel
  Future<void> _finalizeCurrentSegment(gl.Position endPosition) async {
    if (_currentSegment.isNotEmpty) {
      _currentSegment.add(endPosition);
      _trackingSegments.add(List.from(_currentSegment));
    }
  }

  /// Supprime toutes les annotations de points
  Future<void> _clearAllPoints() async {
    if (_pointManager == null) return;

    try {
      // Supprimer les points individuellement
      if (_pointAnnotations.isNotEmpty) {
        for (var point in _pointAnnotations) {
          try {
            await _pointManager!.delete(point);
          } catch (e) {
            _logError('Erreur lors de la suppression d\'un point', e);
          }
        }
      }

      // Supprimer tous les points restants
      await _pointManager!.deleteAll();
      await Future.delayed(_cleanupDelay);
    } catch (e) {
      _logError('Erreur lors de la suppression des points', e);
    }

    _pointAnnotations.clear();
    _lastPausePoint = null;
  }

  /// Supprime toutes les polylines
  Future<void> _clearAllPolylines() async {
    if (_polylineManager == null) return;

    // Créer une copie de la liste pour éviter ConcurrentModificationError
    final polylinesToDelete = List.from(_polylines);
    for (var polyline in polylinesToDelete) {
      try {
        await _polylineManager!.delete(polyline);
      } catch (e) {
        _logError('Erreur lors de la suppression d\'une polyline', e);
      }
    }
    _polylines.clear();
  }

  /// Supprime toutes les annotations (points et polylines)
  Future<void> _clearAllAnnotations() async {
    await _clearAllPolylines();
    await _clearAllPoints();
  }

  /// Met à jour les polylines sur la carte
  Future<void> _updatePolylines() async {
    if (_polylineManager == null) return;

    // Supprimer les polylines existantes
    await _clearAllPolylines();

    // Dessiner tous les segments terminés
    for (var segment in _trackingSegments) {
      if (segment.length >= 2) {
        await _createPolylineFromSegment(segment, AppColors.primaryColor);
      }
    }

    // Dessiner le segment actuel
    if (_currentSegment.length >= 2) {
      final color = isPaused ? AppColors.tertiaryColor : AppColors.primaryColor;
      await _createPolylineFromSegment(_currentSegment, color);
    }
  }

  /// Crée une polyline à partir d'un segment
  Future<void> _createPolylineFromSegment(
    List<gl.Position> segment,
    Color color,
  ) async {
    if (_polylineManager == null) return;

    try {
      final coordinates = segment
          .map((position) => Position(position.longitude, position.latitude))
          .toList();

      final polyline = await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordinates),
          lineWidth: _lineWidth,
          lineColor: color.toARGB32(),
        ),
      );
      _polylines.add(polyline);
    } catch (e) {
      _logError('Erreur lors de la création d\'une polyline', e);
    }
  }

  /// Crée une polyline à partir d'un chemin PathPoint
  Future<void> _createPolylineFromPath(List<PathPoint> path) async {
    if (_polylineManager == null) return;

    try {
      final coordinates = path
          .map((p) => Position(p.longitude, p.latitude))
          .toList();

      final polyline = await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordinates),
          lineWidth: _lineWidth,
          lineColor: AppColors.primaryColor.toARGB32(),
        ),
      );
      _polylines.add(polyline);
    } catch (e) {
      _logError(
        'Erreur lors de la création d\'une polyline depuis un chemin',
        e,
      );
    }
  }

  /// Convertit un segment en liste de PathPoints
  List<PathPoint> _convertSegmentToPathPoints(List<gl.Position> segment) {
    return segment
        .map(
          (position) => PathPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        )
        .toList();
  }

  /// Convertit un PathPoint en gl.Position
  gl.Position _pathPointToPosition(PathPoint pathPoint) {
    return gl.Position(
      latitude: pathPoint.latitude,
      longitude: pathPoint.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Log une erreur en mode debug
  void _logError(String message, dynamic error) {
    if (kDebugMode) {}
  }
}
