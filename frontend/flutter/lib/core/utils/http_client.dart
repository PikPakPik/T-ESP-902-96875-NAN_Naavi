import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Client HTTP personnalisé qui ignore les erreurs de certificat SSL UNIQUEMENT en développement
/// ✅ En production (release mode), utilise la vérification SSL normale
/// ⚠️ En développement (debug mode), ignore les erreurs de certificat SSL
class CustomHttpClient {
  static http.Client? _client;

  /// Obtient un client HTTP approprié selon le mode (dev/prod)
  /// - En DEBUG mode : ignore les erreurs SSL (pour dev local)
  /// - En RELEASE mode : vérification SSL normale (sécurisé)
  static http.Client get client {
    if (_client != null) return _client!;

    if (kDebugMode) {
      // MODE DÉVELOPPEMENT : Ignore les erreurs SSL
      final ioClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      _client = IOClient(ioClient);
    } else {
      // MODE PRODUCTION : Vérification SSL normale
      _client = http.Client();
    }

    return _client!;
  }

  /// Ferme le client (à appeler lors du nettoyage)
  static void close() {
    _client?.close();
    _client = null;
  }
}
