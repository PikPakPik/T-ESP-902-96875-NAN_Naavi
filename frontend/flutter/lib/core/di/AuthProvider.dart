import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/presentation/auth/state/AuthState.dart';
import 'package:naavi/presentation/auth/state/AuthStateNotifier.dart';
import '../services/auth/auth_service.dart';
import '../services/network/check_network_service.dart';
import 'HttpClientProvider.dart';

// Provider pour le service d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  final authenticatedClient = ref.watch(authenticatedHttpClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  return AuthService(
    authenticatedClient: authenticatedClient,
    tokenStorage: tokenStorage,
  );
});

// Provider pour le service de vérification réseau (pour l'auth)
final authCheckNetworkServiceProvider = Provider<CheckNetworkService>((ref) {
  return CheckNetworkService();
});

// Provider pour l'état d'authentification
final authProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final checkNetworkService = ref.watch(authCheckNetworkServiceProvider);
  return AuthStateNotifier(
    authService: authService,
    checkNetworkService: checkNetworkService,
  );
});
