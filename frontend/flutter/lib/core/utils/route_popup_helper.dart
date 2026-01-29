import 'package:naavi/core/services/map/global_route_service.dart';

/// Helper class for managing route visibility from popups
class RoutePopupHelper {
  /// Call this method when the user closes a route info popup
  /// This will hide the currently displayed route on the map
  static Future<void> onPopupClosed() async {
    await GlobalRouteService().hideCurrentRoute();
  }
}
