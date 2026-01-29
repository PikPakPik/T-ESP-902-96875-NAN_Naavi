import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/utils/poi_type.dart';

/// Classe simple pour représenter un type de POI
class POITypeItem {
  final String name;
  final String id;
  final IconData icon;
  final Color color;
  final String description;
  final PoiType? poiType; // Type de POI depuis l'enum global

  const POITypeItem({
    required this.name,
    required this.id,
    required this.icon,
    required this.color,
    this.description = '',
    this.poiType,
  });
}

/// Dialog pour placer un POI sur la carte avec un marqueur draggable
/// Le marqueur temporaire affiche l'icône et peut être déplacé
class PoiPlacementSheet extends StatefulWidget {
  final PoiType poiType;
  final MapboxMap mapboxMap;
  final Function(double latitude, double longitude) onPlacePoi;
  final VoidCallback onCancel;
  final double? initialLatitude;
  final double? initialLongitude;

  const PoiPlacementSheet({
    super.key,
    required this.poiType,
    required this.mapboxMap,
    required this.onPlacePoi,
    required this.onCancel,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<PoiPlacementSheet> createState() => _PoiPlacementSheetState();
}

class _PoiPlacementSheetState extends State<PoiPlacementSheet> {
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  PointAnnotationManager? _tempMarkerManager;
  PointAnnotation? _tempMarker;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDraggableMarker();
  }

  @override
  void dispose() {
    // Nettoyer le marqueur temporaire de la carte avant de fermer le dialog
    _cleanupTempMarker();
    super.dispose();
  }

  /// Nettoie le marqueur temporaire de la carte
  Future<void> _cleanupTempMarker() async {
    if (_tempMarkerManager != null && _tempMarker != null) {
      try {
        await _tempMarkerManager!.delete(_tempMarker!);
      } catch (e) {
      // Intentionally empty catch block
    }
    }
    _tempMarkerManager = null;
    _tempMarker = null;
  }

  /// Initialise le marqueur draggable au centre de la carte ou à la position GPS
  Future<void> _initializeDraggableMarker() async {
    try {
      // Attendre un peu pour s'assurer que la carte est prête
      await Future.delayed(const Duration(milliseconds: 300));

      // Vérifier que le widget est toujours monté
      if (!mounted) return;

      // Utiliser la position GPS de l'utilisateur si disponible, sinon le centre de la carte
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _currentLatitude = widget.initialLatitude!;
        _currentLongitude = widget.initialLongitude!;
      } else {
        // Récupérer la position actuelle de la caméra
        final cameraState = await widget.mapboxMap.getCameraState();
        final center = cameraState.center;
        _currentLatitude = center.coordinates.lat.toDouble();
        _currentLongitude = center.coordinates.lng.toDouble();
      }

      // Vérifier que le widget est toujours monté avant de continuer
      if (!mounted) return;

      // Créer le marqueur temporaire draggable sur la carte
      await _createTempMarker(_currentLatitude, _currentLongitude);

      // Animer la caméra pour arriver sur le marqueur avec une animation fluide
      try {
        await widget.mapboxMap.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(_currentLongitude, _currentLatitude),
            ),
            zoom: 16.0, // Zoom approprié pour voir le marqueur clairement
          ),
          MapAnimationOptions(duration: 1000, startDelay: 0),
        );
      } catch (e) {
      // Intentionally empty catch block
    }

      // Vérifier que le widget est toujours monté avant setState
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Crée un marqueur temporaire draggable avec l'icône
  Future<void> _createTempMarker(double lat, double lon) async {
    try {
      // Nettoyer l'ancien marqueur s'il existe
      if (_tempMarkerManager != null && _tempMarker != null) {
        try {
          await _tempMarkerManager!.delete(_tempMarker!);
        } catch (e) {
      // Intentionally empty catch block
    }
      }

      // Créer un nouveau manager pour le marqueur temporaire
      _tempMarkerManager = await widget.mapboxMap.annotations
          .createPointAnnotationManager();

      // Créer les options avec l'icône
      final options = await _createTempMarkerOptions(lat, lon);

      // Créer le marqueur
      _tempMarker = await _tempMarkerManager!.create(options);

      // Écouter les événements de drag pour mettre à jour la position
      _setupDragListeners();
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Configure les listeners pour le drag du marqueur
  void _setupDragListeners() {
    // Note: Mapbox Flutter peut ne pas avoir de listeners de drag natifs
    // On utilise donc les interactions de tap pour permettre le déplacement
  }

  /// Crée les options pour le marqueur temporaire avec l'icône depuis Figma
  /// Le marqueur est positionné avec précision sur les coordonnées exactes
  Future<PointAnnotationOptions> _createTempMarkerOptions(
    double lat,
    double lon,
  ) async {
    // Charger l'icône appropriée selon le type de POI
    final iconPath = widget.poiType.assetPath;
    final ByteData bytes = await rootBundle.load(iconPath);
    final imageData = bytes.buffer.asUint8List();

    // Créer l'annotation avec UNIQUEMENT l'icône
    // iconAnchor.BOTTOM signifie que le point d'ancrage est en bas de l'icône
    // Donc le point géographique correspond exactement au bas de l'icône (la pointe)
    PointAnnotationOptions options = PointAnnotationOptions(
      geometry: Point(coordinates: Position(lon, lat)),
      iconSize: 0.5, // Taille réduite pour correspondre au point de position
      iconAnchor: IconAnchor
          .BOTTOM, // La pointe de l'icône pointe exactement sur les coordonnées
      image: imageData, // Utiliser uniquement l'icône depuis Figma
    );

    return options;
  }

  /// Déplace le marqueur à une nouvelle position
  Future<void> _moveMarkerTo(double lat, double lon) async {
    if (_tempMarkerManager == null || _tempMarker == null) return;

    try {
      // Supprimer l'ancien marqueur et en créer un nouveau à la nouvelle position
      await _tempMarkerManager!.delete(_tempMarker!);
      final options = await _createTempMarkerOptions(lat, lon);
      _tempMarker = await _tempMarkerManager!.create(options);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Gère le tap sur la carte pour déplacer le marqueur avec précision maximale
  /// Le marqueur se place EXACTEMENT là où l'utilisateur clique
  Future<void> _handleMapTap(TapDownDetails details) async {
    if (!_isInitialized || !mounted) return;

    try {
      // Utiliser directement les coordonnées globales du tap
      // globalPosition donne les coordonnées absolues de l'écran
      final screenCoordinate = ScreenCoordinate(
        x: details.globalPosition.dx,
        y: details.globalPosition.dy,
      );

      // Convertir les coordonnées de l'écran en coordonnées géographiques
      // Cette méthode Mapbox convertit avec précision les pixels de l'écran en coordonnées GPS
      final point = await widget.mapboxMap.coordinateForPixel(screenCoordinate);

      // Vérifier que le widget est toujours monté après l'appel async
      if (!mounted) return;

      final lat = point.coordinates.lat.toDouble();
      final lon = point.coordinates.lng.toDouble();

      setState(() {
        _currentLatitude = lat;
        _currentLongitude = lon;
      });

      // Déplacer le marqueur à la position EXACTE du clic
      await _moveMarkerTo(lat, lon);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleMapTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Overlay avec les éléments UI (boutons et panneaux)
          Stack(
            children: [
              // Boutons en bas
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isInitialized
                            ? () {
                                widget.onPlacePoi(
                                  _currentLatitude,
                                  _currentLongitude,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.poiType.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Placer ici',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
