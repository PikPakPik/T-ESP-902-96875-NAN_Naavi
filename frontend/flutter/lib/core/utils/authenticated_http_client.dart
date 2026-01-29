import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../services/storage/token_storage_service.dart';

/// Client HTTP avec gestion automatique du refresh des tokens
/// - Ajoute automatiquement l'Authorization header
/// - Intercepte les 401 et refresh automatiquement le token
/// - Retente la requête avec le nouveau token
/// - Si le refresh échoue, déconnecte l'utilisateur
class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final TokenStorageService _tokenStorage;
  final String baseUrl;
  final Function()? onUnauthorized; // Callback pour déconnecter

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  AuthenticatedHttpClient({
    required this.baseUrl,
    required TokenStorageService tokenStorage,
    this.onUnauthorized,
    http.Client? innerClient,
  }) : _tokenStorage = tokenStorage,
       _inner = innerClient ?? _createDefaultClient();

  /// Crée un client HTTP par défaut (ignore SSL en dev)
  static http.Client _createDefaultClient() {
    if (kDebugMode) {
      final ioClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      return IOClient(ioClient);
    }
    return http.Client();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Ajouter l'access token à la requête
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Envoyer la requête
    var response = await _inner.send(request);

    // Si 401, tenter de refresh le token
    if (response.statusCode == 401) {

      // Attendre si un refresh est déjà en cours
      if (_isRefreshing) {
        return await _waitForRefreshAndRetry(request);
      }

      // Refresh le token
      _isRefreshing = true;
      final refreshed = await _refreshToken();
      _isRefreshing = false;

      if (refreshed) {
        // Retenter la requête avec le nouveau token
        final newAccessToken = await _tokenStorage.getAccessToken();
        if (newAccessToken != null) {
          request.headers['Authorization'] = 'Bearer $newAccessToken';
        }

        // Retenter la requête
        response = await _inner.send(_copyRequest(request));

        // Traiter les requêtes en attente
        _processPendingRequests();
      } else {
        // Le refresh a échoué, déconnecter l'utilisateur
        await _tokenStorage.clearAll();

        // Appeler le callback de déconnexion
        if (onUnauthorized != null) {
          onUnauthorized!();
        }

        // Annuler les requêtes en attente
        _cancelPendingRequests();
      }
    }

    return response;
  }

  /// Refresh le token avec le refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await _inner.post(
        Uri.parse('$baseUrl/identity/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];

        if (newAccessToken != null) {
          await _tokenStorage.saveAccessToken(newAccessToken);
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Attend que le refresh se termine et retente la requête
  Future<http.StreamedResponse> _waitForRefreshAndRetry(
    http.BaseRequest request,
  ) async {
    final completer = _PendingRequest();
    _pendingRequests.add(completer);

    // Attendre que le refresh se termine
    final success = await completer.future;

    if (success) {
      // Ajouter le nouveau token
      final newAccessToken = await _tokenStorage.getAccessToken();
      if (newAccessToken != null) {
        request.headers['Authorization'] = 'Bearer $newAccessToken';
      }
      return await _inner.send(_copyRequest(request));
    } else {
      throw Exception('Authentication failed');
    }
  }

  /// Traite les requêtes en attente après un refresh réussi
  void _processPendingRequests() {
    for (var request in _pendingRequests) {
      request.complete(true);
    }
    _pendingRequests.clear();
  }

  /// Annule les requêtes en attente après un refresh échoué
  void _cancelPendingRequests() {
    for (var request in _pendingRequests) {
      request.complete(false);
    }
    _pendingRequests.clear();
  }

  /// Copie une requête (nécessaire car BaseRequest ne peut être envoyée qu'une fois)
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    if (request is http.MultipartRequest) {
      final newRequest = http.MultipartRequest(request.method, request.url);
      newRequest.headers.addAll(request.headers);
      newRequest.fields.addAll(request.fields);
      newRequest.files.addAll(request.files);
      return newRequest;
    }

    final newRequest = http.Request(request.method, request.url);
    newRequest.headers.addAll(request.headers);

    if (request is http.Request) {
      newRequest.bodyBytes = request.bodyBytes;
    }

    return newRequest;
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Classe pour gérer les requêtes en attente
class _PendingRequest {
  final Completer<bool> _completer = Completer<bool>();

  Future<bool> get future => _completer.future;

  void complete(bool success) {
    if (!_completer.isCompleted) {
      _completer.complete(success);
    }
  }
}
