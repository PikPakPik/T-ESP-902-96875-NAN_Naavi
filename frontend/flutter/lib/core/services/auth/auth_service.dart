import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/user_dto.dart';
import '../../utils/http_client.dart';
import '../storage/token_storage_service.dart';

/// Service d'authentification
/// Ce service gère les différentes méthodes d'authentification
class AuthService {
  final http.Client? authenticatedClient;
  final TokenStorageService tokenStorage;

  AuthService({this.authenticatedClient, TokenStorageService? tokenStorage})
    : tokenStorage = tokenStorage ?? TokenStorageService();

  String? get _baseUrl => dotenv.env['API_BASE_URL'];

  /// Client HTTP pour les requêtes non authentifiées (login, register)
  http.Client get _basicHttpClient => CustomHttpClient.client;

  /// Client HTTP pour les requêtes authentifiées (avec gestion auto du refresh)
  http.Client get _httpClient => authenticatedClient ?? _basicHttpClient;

  /// Service de stockage des tokens (alias pour compatibilité)
  TokenStorageService get _tokenStorage => tokenStorage;

  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      // TODO: Implémenter la logique d'authentification Google
      // Exemple avec google_sign_in package:
      // final GoogleSignIn googleSignIn = GoogleSignIn();
      // final GoogleSignInAccount? account = await googleSignIn.signIn();
      // if (account != null) {
      //   // Envoyer le token à votre backend
      //   return true;
      // }
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Connexion avec Apple
  Future<bool> signInWithApple() async {
    try {
      // TODO: Implémenter la logique d'authentification Apple
      // Exemple avec sign_in_with_apple package:
      // final credential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [
      //     AppleIDAuthorizationScopes.email,
      //     AppleIDAuthorizationScopes.fullName,
      //   ],
      // );
      // if (credential != null) {
      //   // Envoyer le token à votre backend
      //   return true;
      // }
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Vérification du token d'authentification
  Future<bool> verifyToken(String token) async {
    try {
      // TODO: Implémenter la vérification du token
      // Appel API vers votre backend pour vérifier le token
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si un email existe dans le système
  Future<bool> checkEmailExists(String email, String token) async {
    try {
      if (_baseUrl == null) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/identity/is-available-email');
      final response = await _basicHttpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final extra = data['extra'] as Map<String, dynamic>?;
        final isAvailable = extra?['success'] == true;
        return !isAvailable;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Connexion avec email et mot de passe
  Future<Map<String, dynamic>?> login(
    String email,
    String password,
    String token,
  ) async {
    try {
      if (_baseUrl == null) {
        return null;
      }

      final url = Uri.parse('$_baseUrl/identity/login');
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Sauvegarder les tokens et informations d'auth
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          await _tokenStorage.saveAuthInfo(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            email: email,
            method: 'email',
          );
        }

        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Création de compte avec email et mot de passe
  Future<Map<String, dynamic>?> createAccount(
    String email,
    String password,
    String token, {
    required String firstname,
    required String lastname,
  }) async {
    try {
      if (_baseUrl == null) {
        return null;
      }

      final url = Uri.parse('$_baseUrl/identity/register');
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'password': password,
          'confirmPassword': password,
          'token': token,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Sauvegarder les tokens et informations d'auth
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          await _tokenStorage.saveAuthInfo(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            email: email,
            method: 'email',
          );
        }

        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      // Récupérer le token AVANT de le supprimer
      final accessToken = await _tokenStorage.getAccessToken();

      // Appel API de déconnexion avec le token
      if (_baseUrl != null && accessToken != null) {
        final url = Uri.parse('$_baseUrl/identity/logout');
        await _httpClient.delete(url);
      }
    } catch (e) {
      // Errors are silently ignored - logout API call is best-effort
    } finally {
      // Toujours supprimer les données locales, même si l'appel API échoue
      await _tokenStorage.clearAll();
    }
  }

  /// Supprime le compte utilisateur
  Future<bool> deleteAccount() async {
    try {
      if (_baseUrl == null) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/identity/delete-account');
      final response = await _httpClient.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Supprimer toutes les données locales
        await _tokenStorage.clearAll();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'access token stocké
  Future<String?> getAccessToken() async {
    return await _tokenStorage.getAccessToken();
  }

  /// Récupère le refresh token stocké
  Future<String?> getRefreshToken() async {
    return await _tokenStorage.getRefreshToken();
  }

  /// Vérifie si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasAccessToken();
  }

  /// Rafraîchit l'access token en utilisant le refresh token
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return null;
      }

      if (_baseUrl == null) {
        return null;
      }

      final url = Uri.parse('$_baseUrl/identity/refresh');
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];

        // Sauvegarder le nouveau access token
        if (newAccessToken != null) {
          await _tokenStorage.saveAccessToken(newAccessToken);
          return newAccessToken;
        }
      } else {
        // Si le refresh échoue, déconnecter l'utilisateur
        await _tokenStorage.clearAll();
        return null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Récupère les informations de l'utilisateur connecté
  /// Sauvegarde automatiquement le profil en cache pour l'accès hors-ligne
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        return null;
      }

      if (_baseUrl == null) {
        return null;
      }

      final url = Uri.parse('$_baseUrl/identity/user');
      // Utiliser le client authentifié qui gérera automatiquement le refresh si 401
      final response = await _httpClient.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        // Sauvegarder en cache pour l'accès hors-ligne
        await _tokenStorage.saveUserProfile(userData);
        return userData;
      } else if (response.statusCode == 401) {
        // Token expiré, on renvoie null pour indiquer qu'il faut refresh
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Récupère le profil utilisateur depuis le cache (pour le mode hors-ligne)
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    return await _tokenStorage.getCachedUserProfile();
  }

  /// Met à jour les informations de l'utilisateur connecté
  /// Retourne le UserDto mis à jour en cas de succès, null sinon
  /// Sauvegarde automatiquement le profil mis à jour en cache
  Future<UserDto?> updateUser({String? firstname, String? lastname}) async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        return null;
      }

      if (_baseUrl == null) {
        return null;
      }

      final url = Uri.parse('$_baseUrl/identity/user');
      final body = <String, dynamic>{};

      if (firstname != null) body['firstname'] = firstname;
      if (lastname != null) body['lastname'] = lastname;

      final response = await _httpClient.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Sauvegarder en cache pour l'accès hors-ligne
        await _tokenStorage.saveUserProfile(data);
        return UserDto.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Upload une photo de profil pour l'utilisateur connecté
  /// Retourne l'URL de la photo uploadée en cas de succès, null sinon
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      if (_baseUrl == null) {
        return null;
      }

      final url = Uri.parse('$_baseUrl/identity/user/profile-picture');

      // Créer une requête multipart
      final request = http.MultipartRequest('POST', url);

      // Ajouter le fichier image
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      // Utiliser _httpClient.send() pour bénéficier du refresh automatique du token
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['profilePicture'] as String? ?? data['url'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Demande une réinitialisation de mot de passe pour l'utilisateur connecté
  /// Envoie un email avec un lien de réinitialisation
  /// Retourne true si la demande a été envoyée avec succès
  Future<bool> requestPasswordReset(String token) async {
    try {
      final email = await _tokenStorage.getUserEmail();
      if (email == null) {
        return false;
      }

      return await requestPasswordResetForEmail(email, token);
    } catch (e) {
      return false;
    }
  }

  /// Demande une réinitialisation de mot de passe pour un email donné
  /// Utilisé sur la page de login pour les utilisateurs non connectés
  /// Retourne true si la demande a été envoyée avec succès
  Future<bool> requestPasswordResetForEmail(String email, String token) async {
    try {
      if (_baseUrl == null) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/identity/forgot-password');
      final response = await _basicHttpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'token': token}),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie et restaure la session utilisateur
  /// Retourne : 'authenticated' si connecté, 'unauthenticated' si non connecté,
  /// ou l'email de l'utilisateur si le refresh a échoué
  Future<String> checkAndRestoreSession() async {
    try {
      // Vérifier si on a des tokens
      final hasTokens = await _tokenStorage.hasTokens();
      if (!hasTokens) {
        return 'unauthenticated';
      }

      // Essayer de récupérer l'utilisateur
      var user = await getCurrentUser();

      // Si échec (probablement 401), essayer de refresh
      if (user == null) {
        final newAccessToken = await refreshAccessToken();

        if (newAccessToken != null) {
          // Réessayer de récupérer l'utilisateur avec le nouveau token
          user = await getCurrentUser();
          if (user != null) {
            return 'authenticated';
          }
        }

        // Le refresh a échoué, récupérer l'email pour pré-remplir le login
        final email = await _tokenStorage.getUserEmail();
        await _tokenStorage.clearAll();
        return email ?? 'unauthenticated';
      }

      return 'authenticated';
    } catch (e) {
      await _tokenStorage.clearAll();
      return 'unauthenticated';
    }
  }
}
