import 'package:naavi/core/services/map/route_management_service.dart';

/// Global service to manage route visibility across the app
class GlobalRouteService {
  static final GlobalRouteService _instance = GlobalRouteService._internal();
  factory GlobalRouteService() => _instance;
  GlobalRouteService._internal();

  RouteManagementService? _currentRouteService;

  /// Register the current active route service
  void registerRouteService(RouteManagementService service) {
    _currentRouteService = service;
  }

  /// Unregister the current route service
  void unregisterRouteService() {
    _currentRouteService = null;
  }

  /// Hide the currently selected route (called from popup close)
  Future<void> hideCurrentRoute() async {
    if (_currentRouteService != null) {
      await _currentRouteService!.hideCurrentRoute();
    }
  }
}
