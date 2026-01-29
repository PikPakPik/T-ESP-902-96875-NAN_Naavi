import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/storage/token_storage_service.dart';
import '../utils/authenticated_http_client.dart';

/// Provider pour le TokenStorageService
final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// Provider pour le client HTTP authentifié
/// Ce client gère automatiquement le refresh des tokens
final authenticatedHttpClientProvider = Provider<http.Client>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  return AuthenticatedHttpClient(
    baseUrl: baseUrl,
    tokenStorage: tokenStorage,
    onUnauthorized: () {
      // TODO: Gérer la déconnexion automatique
      // Peut-être via un provider global ou un event bus
    },
  );
});
