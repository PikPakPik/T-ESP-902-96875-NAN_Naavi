import 'package:flutter/material.dart' hide Visibility;
import 'package:geobase/geobase.dart' as geobase;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/data/models/route_data.dart';
import 'package:naavi/core/utils/utils.dart';

/// Service for managing static routes on the map
class RouteService {
  static const Color _defaultRouteColor = Color.fromRGBO(50, 73, 67, 1);
  static const String _defaultRouteColorHex = "#324943";
  // Removed unused field _highlightedRouteColorHex

  /// Initialize routes from WKB strings
  List<RouteInfo> initializeRoutes(
    List<String> wkbStrings,
    List<String>? routeNames,
    List<Map<String, dynamic>>? routesData,
  ) {
    final lineStrings = decodeMultipleWKBFromStrings(wkbStrings);

    // Use full routes data if available, otherwise create minimal maps with just WKB
    final List<Map<String, dynamic>> routesWithInfo;
    if (routesData != null && routesData.isNotEmpty) {
      routesWithInfo = routesData;
    } else {
      routesWithInfo = wkbStrings.map((wkb) => {'wkb': wkb}).toList();
    }

    final hikeLines = decodeMultipleWKBWithInfo(routesWithInfo);

    final routes = <RouteInfo>[];

    for (int i = 0; i < lineStrings.length; i++) {
      final routeName = (routeNames != null && i < routeNames.length)
          ? routeNames[i]
          : "Route ${i + 1}";

      routes.add(
        RouteInfo(
          id: "route_$i",
          name: routeName,
          lineString: lineStrings[i],
          hikeLine: hikeLines[i],
          color: _defaultRouteColor,
        ),
      );
    }

    return routes;
  }

  /// Add a single route to the map
  Future<void> addRouteToMap(
    MapboxMap mapboxMap,
    RouteInfo route,
    int index, {
    bool visible = false,
    bool addStartPoint = true,
  }) async {
    final lineString = route.lineString;

    // Convert LineString to coordinates for GeoJSON
    final coordinates = <List<double>>[];
    for (int i = 0; i < lineString.chain.positionCount; i++) {
      final pos = lineString.chain[i];
      coordinates.add([pos.x, pos.y]);
    }

    // Create GeoJSON for the line
    final geoJsonSource =
        '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": { "name": "${route.name}", "routeIndex": $index },
      "geometry": { "type": "LineString", "coordinates": ${coordinates.toString()} }
    }
  ]
}''';

    // Add GeoJSON source for the line
    await mapboxMap.style.addSource(
      GeoJsonSource(id: "linestring-source-$index", data: geoJsonSource),
    );

    // Add layer to display the line
    await mapboxMap.style.addLayer(
      LineLayer(
        id: "linestring-layer-$index",
        sourceId: "linestring-source-$index",
        lineColor: route.color
            .toARGB32(), // Use toARGB32 for explicit conversion
        lineWidth: 6.0, // Largeur plus importante pour une meilleure visibilité
        lineCap: LineCap.ROUND, // Bouts arrondis pour un rendu fluide
        lineJoin: LineJoin.ROUND, // Jointures arrondies pour un tracé lisse
        lineOpacity: 0.9, // Légère transparence pour un rendu plus doux
        visibility: visible ? Visibility.VISIBLE : Visibility.NONE,
      ),
    );

    // Add start point if available and requested
    if (addStartPoint && lineString.chain.positionCount > 0) {
      await _addStartPoint(mapboxMap, route, index, lineString);
    }
  }

  /// Add start point marker for a route
  Future<void> _addStartPoint(
    MapboxMap mapboxMap,
    RouteInfo route,
    int index,
    geobase.LineString lineString,
  ) async {
    final firstPoint = lineString.chain[0];

    final startPointGeoJson =
        '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": { "name": "Départ - ${route.name}", "routeIndex": $index },
      "geometry": { "type": "Point", "coordinates": [${firstPoint.x}, ${firstPoint.y}] }
    }
  ]
}''';

    await mapboxMap.style.addSource(
      GeoJsonSource(id: "start-point-source-$index", data: startPointGeoJson),
    );

    // Add the symbol layer (icon) on top
    await mapboxMap.style.addLayer(
      SymbolLayer(
        id: "start-point-layer-$index",
        sourceId: "start-point-source-$index",
        iconImage: 'start-point-icon',
        iconSize: 0.8, // Optimized size for crisp display
        iconAnchor: IconAnchor.BOTTOM,
        iconAllowOverlap: true, // Allow overlapping with other symbols
        iconIgnorePlacement: true, // Ignore placement restrictions
        visibility: Visibility.VISIBLE, // Ensure start points are visible
      ),
    );
  }

  /// Show and highlight a specific route
  Future<void> showAndHighlightRoute(
    MapboxMap mapboxMap,
    int routeIndex,
    int? previousHighlightedIndex,
    List<RouteInfo> routes,
  ) async {
    // Hide previous highlighted route
    if (previousHighlightedIndex != null) {
      await mapboxMap.style.setStyleLayerProperty(
        "linestring-layer-$previousHighlightedIndex",
        "visibility",
        "none",
      );
    }

    // Show and highlight new route
    await mapboxMap.style.setStyleLayerProperty(
      "linestring-layer-$routeIndex",
      "visibility",
      "visible",
    );

    // Convert color to hex string format for Mapbox
    await mapboxMap.style.setStyleLayerProperty(
      "linestring-layer-$routeIndex",
      "line-color",
      _defaultRouteColorHex, // Use hex string format
    );

    await mapboxMap.style.setStyleLayerProperty(
      "linestring-layer-$routeIndex",
      "line-width",
      5.0, // Use double
    );

    // Center camera on the selected route
    if (routeIndex < routes.length) {
      await fitCameraToSingleRoute(mapboxMap, routes[routeIndex]);
    }
  }

  /// Fit camera to show a single route
  Future<void> fitCameraToSingleRoute(
    MapboxMap mapboxMap,
    RouteInfo route,
  ) async {
    try {
      final bounds = calculateBounds([route]);

      // Use fitBounds with padding to show entire route
      // Bottom padding is larger to account for the popup
      final cameraForBounds = await mapboxMap.cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: Position(bounds.minLon, bounds.minLat)),
          northeast: Point(coordinates: Position(bounds.maxLon, bounds.maxLat)),
          infiniteBounds: false,
        ),
        MbxEdgeInsets(
          top: 100,
          left: 50,
          bottom: 450, // Large bottom padding for the popup
          right: 50,
        ),
        null, // bearing
        null, // pitch
        null, // maxZoom
        null, // offset
      );

      await mapboxMap.easeTo(
        cameraForBounds,
        MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      // Camera animation errors are silently ignored
    }
  }

  /// Calculate bounds for all routes
  RouteBounds calculateBounds(List<RouteInfo> routes) {
    double? minLat, maxLat, minLon, maxLon;

    for (final route in routes) {
      final lineString = route.lineString;
      if (lineString.chain.positionCount > 0) {
        for (int i = 0; i < lineString.chain.positionCount; i++) {
          final pos = lineString.chain[i];

          minLat = minLat == null ? pos.y : (pos.y < minLat ? pos.y : minLat);
          maxLat = maxLat == null ? pos.y : (pos.y > maxLat ? pos.y : maxLat);
          minLon = minLon == null ? pos.x : (pos.x < minLon ? pos.x : minLon);
          maxLon = maxLon == null ? pos.x : (pos.x > maxLon ? pos.x : maxLon);
        }
      }
    }

    if (minLat == null || maxLat == null || minLon == null || maxLon == null) {
      throw Exception('No valid coordinates found in routes');
    }

    return RouteBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }

  /// Fit camera to show all routes
  Future<void> fitCameraToRoutes(
    MapboxMap mapboxMap,
    List<RouteInfo> routes,
  ) async {
    if (routes.isEmpty) return;

    try {
      final bounds = calculateBounds(routes);
      final center = bounds.center;

      // Pour les vues globales, utilise plus de padding pour une vue d'ensemble
      final zoom = bounds.calculateZoom(padding: 0.25);

      await mapboxMap.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position(center.longitude, center.latitude),
          ),
          zoom: zoom,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      // Camera animation errors are silently ignored
    }
  }

  /// Add clustered start points for multiple routes
  Future<void> addClusteredStartPoints(
    MapboxMap mapboxMap,
    List<RouteInfo> routes,
  ) async {
    // Create GeoJSON with all start points (deduplicate exact same coordinates)
    final features = <String>[];
    final seenCoordinates = <String>{};

    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      if (route.lineString.chain.positionCount > 0) {
        final firstPoint = route.lineString.chain[0];
        final coordKey = '${firstPoint.x},${firstPoint.y}';

        // Skip if we've already added this exact coordinate
        if (seenCoordinates.contains(coordKey)) {
          continue;
        }
        seenCoordinates.add(coordKey);

        features.add('''
    {
      "type": "Feature",
      "properties": { 
        "name": "${route.name.replaceAll('"', '\\"')}",
        "routeIndex": $i
      },
      "geometry": { 
        "type": "Point", 
        "coordinates": [${firstPoint.x}, ${firstPoint.y}] 
      }
    }''');
      }
    }

    final geoJsonSource =
        '''
{
  "type": "FeatureCollection",
  "features": [
    ${features.join(',\n')}
  ]
}''';

    // Add source with clustering enabled
    await mapboxMap.style.addSource(
      GeoJsonSource(
        id: "hikes-start-points",
        data: geoJsonSource,
        cluster: true,
        clusterMaxZoom: 14,
        clusterRadius:
            30, // Réduit de 50 à 30 pour moins de clustering agressif
      ),
    );

    // Add cluster circle layer (using fixed styling for simplicity)
    await mapboxMap.style.addLayer(
      CircleLayer(
        id: "clusters",
        sourceId: "hikes-start-points",
        circleColor: AppColors.tertiaryColor.toARGB32(),
        circleRadius: 25.0, // Fixed size
        circleStrokeWidth: 2.0,
        circleStrokeColor: AppColors.primaryColor.toARGB32(), // White stroke
        filter: ["has", "point_count"],
      ),
    );

    // Add cluster count layer
    await mapboxMap.style.addLayer(
      SymbolLayer(
        id: "cluster-count",
        sourceId: "hikes-start-points",
        textField: "{point_count_abbreviated}",
        textSize: 14.0,
        textColor: AppColors.primaryColor.toARGB32(), // White text
        filter: ["has", "point_count"],
      ),
    );

    // Add unclustered point layer
    await mapboxMap.style.addLayer(
      SymbolLayer(
        id: "unclustered-point",
        sourceId: "hikes-start-points",
        iconImage: 'start-point-icon',
        iconSize: 0.8,
        iconAnchor: IconAnchor.BOTTOM,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        filter: [
          "!",
          ["has", "point_count"],
        ],
      ),
    );
  }

  /// Setup tap interactions for route start points
  Future<void> setupRouteInteractions(
    MapboxMap mapboxMap,
    List<RouteInfo> routes,
    Function(int) onRouteTapped,
  ) async {
    for (int i = 0; i < routes.length; i++) {
      // Add interaction for the symbol layer (start point icons)
      mapboxMap.addInteraction(
        TapInteraction(FeaturesetDescriptor(layerId: "start-point-layer-$i"), (
          feature,
          context,
        ) async {
          onRouteTapped(i);
        }),
        interactionID: "point-interaction-$i",
      );
    }
  }

  /// Setup tap interactions for clustered points
  Future<void> setupClusteredRouteInteractions(
    MapboxMap mapboxMap,
    List<RouteInfo> routes,
    Function(int) onRouteTapped,
  ) async {
    // Interaction for unclustered points
    mapboxMap.addInteraction(
      TapInteraction(FeaturesetDescriptor(layerId: "unclustered-point"), (
        feature,
        context,
      ) async {
        final properties = feature.properties;
        if (properties.containsKey("routeIndex")) {
          final routeIndex = properties["routeIndex"];
          if (routeIndex is num) {
            onRouteTapped(routeIndex.toInt());
          }
        }
      }),
      interactionID: "unclustered-point-interaction",
    );

    // Interaction for cluster circles
    mapboxMap.addInteraction(
      TapInteraction(FeaturesetDescriptor(layerId: "clusters"), (
        feature,
        context,
      ) async {
        await _handleClusterTap(mapboxMap, feature);
      }),
      interactionID: "cluster-interaction",
    );

    // Interaction for cluster count text
    mapboxMap.addInteraction(
      TapInteraction(FeaturesetDescriptor(layerId: "cluster-count"), (
        feature,
        context,
      ) async {
        await _handleClusterTap(mapboxMap, feature);
      }),
      interactionID: "cluster-count-interaction",
    );
  }

  /// Handle cluster tap - zoom to expand cluster
  Future<void> _handleClusterTap(
    MapboxMap mapboxMap,
    TypedFeaturesetFeature feature,
  ) async {
    final properties = feature.properties;

    if (properties.containsKey("cluster_id")) {
      try {
        // Build feature map for getGeoJsonClusterExpansionZoom
        final featureMap = <String, dynamic>{
          'type': 'Feature',
          'properties': properties,
          'geometry': feature.geometry,
        };

        final clusterExpansionZoom = await mapboxMap
            .getGeoJsonClusterExpansionZoom('hikes-start-points', featureMap);

        if (clusterExpansionZoom.value != null) {
          final geometry = feature.geometry;
          if (geometry["coordinates"] != null) {
            final coords = geometry["coordinates"];

            // Parse coordinates - they might be strings or numbers
            double lon;
            double lat;

            if (coords is List) {
              // Convertir en double, que ce soit num ou String
              lon = (coords[0] is num)
                  ? (coords[0] as num).toDouble()
                  : double.parse(coords[0].toString());
              lat = (coords[1] is num)
                  ? (coords[1] as num).toDouble()
                  : double.parse(coords[1].toString());
            } else {
              return;
            }

            final zoomLevel = (clusterExpansionZoom.value is num)
                ? (clusterExpansionZoom.value as num).toDouble()
                : double.parse(clusterExpansionZoom.value.toString());

            await mapboxMap.easeTo(
              CameraOptions(
                center: Point(coordinates: Position(lon, lat)),
                zoom: zoomLevel,
              ),
              MapAnimationOptions(duration: 500),
            );
          }
        }
      } catch (e) {
        // Cluster expansion errors are silently ignored
      }
    }
  }

  /// Clean up route interactions
  void cleanupRouteInteractions(MapboxMap mapboxMap, List<RouteInfo> routes) {
    for (int i = 0; i < routes.length; i++) {
      try {
        mapboxMap.removeInteraction("point-interaction-$i");
      } catch (e) {
        // Ignore interaction cleanup errors - interactions may not exist
      }
    }
  }

  /// Remove all route layers and sources from the map
  Future<void> removeAllRoutes(MapboxMap mapboxMap, int routeCount) async {
    for (int i = 0; i < routeCount; i++) {
      try {
        // Remove layers first (before removing sources)
        await mapboxMap.style.removeStyleLayer("linestring-layer-$i");
      } catch (e) {
        // Layer may not exist
      }
      try {
        await mapboxMap.style.removeStyleLayer("start-point-layer-$i");
      } catch (e) {
        // Layer may not exist
      }
      try {
        // Then remove sources
        await mapboxMap.style.removeStyleSource("linestring-source-$i");
      } catch (e) {
        // Source may not exist
      }
      try {
        await mapboxMap.style.removeStyleSource("start-point-source-$i");
      } catch (e) {
        // Source may not exist
      }
      try {
        // Remove interaction
        mapboxMap.removeInteraction("point-interaction-$i");
      } catch (e) {
        // Interaction may not exist
      }
    }
  }
}
