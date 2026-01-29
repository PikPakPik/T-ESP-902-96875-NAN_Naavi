import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:naavi/core/utils/utils.dart';

/// Widget pour gérer la carte Mapbox dans HikeDetailPage
class HikeMapWidget extends StatefulWidget {
  final String? wkb;
  final double? startLat;
  final double? startLon;
  final bool showMapFullScreen;
  final ValueChanged<bool> onMapFullScreenChanged;
  final VoidCallback? onFullScreenImage;
  final String? imagePath;

  const HikeMapWidget({
    super.key,
    this.wkb,
    this.startLat,
    this.startLon,
    required this.showMapFullScreen,
    required this.onMapFullScreenChanged,
    this.onFullScreenImage,
    this.imagePath,
  });

  @override
  State<HikeMapWidget> createState() => _HikeMapWidgetState();
}

class _HikeMapWidgetState extends State<HikeMapWidget> {
  MapboxMap? _mapboxMap;
  MapboxMap? _miniMapboxMap;
  List<List<double>> _routeCoordinates = [];

  CameraOptions _getInitialCamera() {
    if (widget.startLat != null && widget.startLon != null) {
      return CameraOptions(
        center: Point(
          coordinates: Position(widget.startLon!, widget.startLat!),
        ),
        zoom: 13,
      );
    }

    return CameraOptions(
      center: Point(
        coordinates: Position(-1.5536, 47.2184),
      ), // Nantes par défaut
      zoom: 13,
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // Activer les gestes pour permettre le zoom et le déplacement, mais bloquer le double-clic
    try {
      await mapboxMap.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: true,
          pinchToZoomEnabled: true,
          scrollEnabled: true,
          pitchEnabled: true,
          doubleTapToZoomInEnabled: false, // Désactivé
          doubleTouchToZoomOutEnabled: false, // Désactivé
          quickZoomEnabled: true,
        ),
      );
    } catch (e) {
      // Gesture settings errors are silently ignored
    }
  }

  @override
  void didUpdateWidget(HikeMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recentrer la caméra sur le trajet quand on passe en mode carte plein écran
    if (widget.showMapFullScreen != oldWidget.showMapFullScreen &&
        widget.showMapFullScreen &&
        _routeCoordinates.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _routeCoordinates.isNotEmpty) {
          _fitCameraToRoute(_routeCoordinates);
        }
      });
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    if (_mapboxMap == null) return;
    await _addRouteToMap();
    // Toujours recentrer sur le trajet après l'avoir ajouté
    if (_routeCoordinates.isNotEmpty) {
      // Attendre un peu pour que la carte soit prête
      await Future.delayed(const Duration(milliseconds: 200));
      await _fitCameraToRoute(_routeCoordinates);
    }
  }

  Future<void> _addRouteToMap() async {
    if (_mapboxMap == null || widget.wkb == null) return;

    try {
      final lineString = decodeWKBFromString(widget.wkb!);
      if (lineString.chain.positionCount == 0) return;

      final coordinates = <List<double>>[];
      for (int i = 0; i < lineString.chain.positionCount; i++) {
        final pos = lineString.chain[i];
        coordinates.add([pos.x, pos.y]);
      }

      if (coordinates.isEmpty) return;
      _routeCoordinates = coordinates;

      final geoJsonSource =
          '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {},
      "geometry": { "type": "LineString", "coordinates": ${coordinates.toString()} }
    }
  ]
}''';

      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: "hike-route-source", data: geoJsonSource),
      );

      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: "hike-route-layer",
          sourceId: "hike-route-source",
          lineColor: const Color(0xFF324943).toARGB32(),
          lineWidth: 8.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );

      if (coordinates.isNotEmpty) {
        final startPoint = coordinates.first;
        final startGeoJson =
            '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {},
      "geometry": { "type": "Point", "coordinates": [${startPoint[0]}, ${startPoint[1]}] }
    }
  ]
}''';

        await _mapboxMap!.style.addSource(
          GeoJsonSource(id: "hike-start-source", data: startGeoJson),
        );

        await _mapboxMap!.style.addLayer(
          CircleLayer(
            id: "hike-start-layer",
            sourceId: "hike-start-source",
            circleColor: Colors.white.toARGB32(),
            circleRadius: 8,
            circleStrokeColor: const Color(0xFF4CAF50).toARGB32(),
            circleStrokeWidth: 3,
          ),
        );
      }

      await _fitCameraToRoute(coordinates);
    } catch (e) {
      // Route display errors are silently ignored
    }
  }

  Future<void> _fitCameraToRoute(List<List<double>> coordinates) async {
    if (_mapboxMap == null || coordinates.isEmpty) return;

    double minLat = coordinates[0][1];
    double maxLat = coordinates[0][1];
    double minLon = coordinates[0][0];
    double maxLon = coordinates[0][0];

    for (final coord in coordinates) {
      if (coord[1] < minLat) minLat = coord[1];
      if (coord[1] > maxLat) maxLat = coord[1];
      if (coord[0] < minLon) minLon = coord[0];
      if (coord[0] > maxLon) maxLon = coord[0];
    }

    try {
      // Padding adapté selon si on est en plein écran ou non, et si une image est présente
      final padding = widget.showMapFullScreen
          ? MbxEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
          : widget.imagePath != null
          ? MbxEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
          : MbxEdgeInsets(top: 40, left: 40, bottom: 40, right: 40);

      final cameraForBounds = await _mapboxMap!.cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: Position(minLon, minLat)),
          northeast: Point(coordinates: Position(maxLon, maxLat)),
          infiniteBounds: false,
        ),
        padding,
        null,
        null,
        null,
        null,
      );

      await _mapboxMap!.setCamera(cameraForBounds);
    } catch (e) {
      // Camera fit errors are silently ignored
    }
  }

  Future<void> _onMiniMapCreated(MapboxMap mapboxMap) async {
    _miniMapboxMap = mapboxMap;
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        rotateEnabled: false,
        pinchToZoomEnabled: false,
        scrollEnabled: false,
        pitchEnabled: false,
        doubleTapToZoomInEnabled: false,
        doubleTouchToZoomOutEnabled: false,
        quickZoomEnabled: false,
      ),
    );

    try {
      await mapboxMap.logo.updateSettings(
        LogoSettings(marginLeft: 500, marginBottom: 500),
      );
      await mapboxMap.attribution.updateSettings(
        AttributionSettings(marginLeft: 500, marginBottom: 500),
      );
    } catch (e) {
      // Mini map style errors are silently ignored
    }
  }

  Future<void> _onMiniStyleLoaded(StyleLoadedEventData event) async {
    if (_miniMapboxMap == null) return;
    await _addRouteToMiniMap();
  }

  Future<void> _addRouteToMiniMap() async {
    if (_miniMapboxMap == null || widget.wkb == null) return;

    try {
      final lineString = decodeWKBFromString(widget.wkb!);
      if (lineString.chain.positionCount == 0) return;

      final coordinates = <List<double>>[];
      for (int i = 0; i < lineString.chain.positionCount; i++) {
        final pos = lineString.chain[i];
        coordinates.add([pos.x, pos.y]);
      }

      if (coordinates.isEmpty) return;

      final geoJsonSource =
          '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {},
      "geometry": { "type": "LineString", "coordinates": ${coordinates.toString()} }
    }
  ]
}''';

      await _miniMapboxMap!.style.addSource(
        GeoJsonSource(id: "mini-hike-route-source", data: geoJsonSource),
      );

      await _miniMapboxMap!.style.addLayer(
        LineLayer(
          id: "mini-hike-route-layer",
          sourceId: "mini-hike-route-source",
          lineColor: const Color(0xFF324943).toARGB32(),
          lineWidth: 3.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );

      if (coordinates.isNotEmpty) {
        final startPoint = coordinates.first;
        final startGeoJson =
            '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {},
      "geometry": { "type": "Point", "coordinates": [${startPoint[0]}, ${startPoint[1]}] }
    }
  ]
}''';

        await _miniMapboxMap!.style.addSource(
          GeoJsonSource(id: "mini-hike-start-source", data: startGeoJson),
        );

        await _miniMapboxMap!.style.addLayer(
          CircleLayer(
            id: "mini-hike-start-layer",
            sourceId: "mini-hike-start-source",
            circleColor: const Color(0xFF4CAF50).toARGB32(),
            circleRadius: 5,
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 2,
          ),
        );
      }

      await _fitMiniCameraToRoute(coordinates);
    } catch (e) {
      // Mini map route errors are silently ignored
    }
  }

  Future<void> _fitMiniCameraToRoute(List<List<double>> coordinates) async {
    if (_miniMapboxMap == null || coordinates.isEmpty) return;

    double minLat = coordinates[0][1];
    double maxLat = coordinates[0][1];
    double minLon = coordinates[0][0];
    double maxLon = coordinates[0][0];

    for (final coord in coordinates) {
      if (coord[1] < minLat) minLat = coord[1];
      if (coord[1] > maxLat) maxLat = coord[1];
      if (coord[0] < minLon) minLon = coord[0];
      if (coord[0] > maxLon) maxLon = coord[0];
    }

    try {
      final cameraForBounds = await _miniMapboxMap!.cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: Position(minLon, minLat)),
          northeast: Point(coordinates: Position(maxLon, maxLat)),
          infiniteBounds: false,
        ),
        MbxEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
        null,
        null,
        null,
        null,
      );

      await _miniMapboxMap!.setCamera(cameraForBounds);
    } catch (e) {
      // Mini camera fit errors are silently ignored
    }
  }

  Widget _buildPhotoView() {
    if (widget.imagePath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: Colors.grey[800]),
      child: Image.asset(
        widget.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[700],
          child: const Center(
            child: Icon(Icons.landscape, color: Colors.white38, size: 80),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPhoto() {
    if (widget.imagePath == null) {
      return _buildMiniMap();
    }

    return Image.asset(
      widget.imagePath!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          color: Colors.grey[600],
          child: const Center(
            child: Icon(Icons.image, color: Colors.white54, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          children: [
            MapWidget(
              key: const ValueKey("miniHikeDetailMap"),
              styleUri: MapboxStyles.OUTDOORS,
              cameraOptions: _getInitialCamera(),
              onMapCreated: _onMiniMapCreated,
              onStyleLoadedListener: _onMiniStyleLoaded,
            ),
            Positioned.fill(child: Container(color: Colors.transparent)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Carte toujours présente en arrière-plan
        MapWidget(
          key: const ValueKey("mainHikeDetailMap"),
          styleUri: MapboxStyles.OUTDOORS,
          cameraOptions: _getInitialCamera(),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
        ),
        // Photo par-dessus (visible ou non selon l'état et si une image existe)
        // Ignorer les interactions quand on est en mode carte plein écran
        if (!widget.showMapFullScreen && widget.imagePath != null)
          IgnorePointer(
            ignoring: widget.showMapFullScreen,
            child: _buildPhotoView(),
          ),

        // Mini vue (carte ou photo selon l'état) - cliquable pour basculer si image existe
        if (widget.imagePath != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E4D9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final newState = !widget.showMapFullScreen;
                    widget.onMapFullScreenChanged(newState);

                    // Recentrer la caméra sur le trajet après le changement d'état
                    if (newState && _routeCoordinates.isNotEmpty) {
                      // Attendre un peu pour que la transition soit terminée
                      await Future.delayed(const Duration(milliseconds: 100));
                      await _fitCameraToRoute(_routeCoordinates);
                    } else if (!newState && _routeCoordinates.isNotEmpty) {
                      // Recentrer aussi quand on revient à la vue avec photo
                      await Future.delayed(const Duration(milliseconds: 100));
                      await _fitCameraToRoute(_routeCoordinates);
                    }
                  },
                  child: widget.showMapFullScreen
                      ? _buildMiniPhoto()
                      : _buildMiniMap(),
                ),
              ),
            ),
          ),

        // Bouton plein écran photo uniquement (si une image existe)
        if (!widget.showMapFullScreen && widget.imagePath != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: widget.onFullScreenImage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
