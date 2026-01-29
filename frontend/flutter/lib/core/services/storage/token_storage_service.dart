import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de stockage des tokens d'authentification
/// Utilise SharedPreferences pour persister les tokens
class TokenStorageService {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userInfoKey = 'auth_user_info';
  static const String _userProfileKey = 'user_profile_cache';

  /// Sauvegarde l'access token
  Future<void> saveAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Sauvegarde le refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Sauvegarde les deux tokens en une seule fois
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Récupère l'access token
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Récupère le refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les deux tokens
  Future<Map<String, String?>> getTokens() async {
    final results = await Future.wait([getAccessToken(), getRefreshToken()]);

    return {'accessToken': results[0], 'refreshToken': results[1]};
  }

  /// Supprime l'access token
  Future<void> deleteAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Supprime le refresh token
  Future<void> deleteRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_refreshTokenKey);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Supprime tous les tokens (logout)
  Future<void> clearTokens() async {
    await Future.wait([deleteAccessToken(), deleteRefreshToken()]);
  }

  /// Vérifie si l'utilisateur est authentifié (a un access token)
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Vérifie si les deux tokens sont présents
  Future<bool> hasTokens() async {
    final tokens = await getTokens();
    return tokens['accessToken'] != null && tokens['refreshToken'] != null;
  }

  /// Sauvegarde les informations utilisateur (email + méthode d'auth)
  Future<void> saveUserInfo({
    required String email,
    required String method,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = jsonEncode({'method': method, 'email': email});
      await prefs.setString(_userInfoKey, userInfo);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Récupère les informations utilisateur
  Future<Map<String, String>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoJson = prefs.getString(_userInfoKey);
      if (userInfoJson == null) return null;

      final decoded = jsonDecode(userInfoJson) as Map<String, dynamic>;
      return {
        'method': decoded['method'] as String,
        'email': decoded['email'] as String,
      };
    } catch (e) {
      return null;
    }
  }

  /// Récupère uniquement l'email de l'utilisateur
  Future<String?> getUserEmail() async {
    final userInfo = await getUserInfo();
    return userInfo?['email'];
  }

  /// Récupère uniquement la méthode d'authentification
  Future<String?> getAuthMethod() async {
    final userInfo = await getUserInfo();
    return userInfo?['method'];
  }

  /// Sauvegarde les informations complètes de connexion
  Future<void> saveAuthInfo({
    required String accessToken,
    required String refreshToken,
    required String email,
    required String method,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserInfo(email: email, method: method),
    ]);
  }

  /// Récupère toutes les informations d'authentification
  Future<Map<String, String?>> getAuthInfo() async {
    final tokens = await getTokens();
    final userInfo = await getUserInfo();

    return {
      'accessToken': tokens['accessToken'],
      'refreshToken': tokens['refreshToken'],
      'email': userInfo?['email'],
      'method': userInfo?['method'],
    };
  }

  /// Sauvegarde le profil utilisateur complet en cache
  Future<void> saveUserProfile(Map<String, dynamic> userProfile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(userProfile);
      await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      // Intentionally empty catch block
    }
  }

  /// Récupère le profil utilisateur depuis le cache
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      if (profileJson == null) return null;

      return jsonDecode(profileJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Supprime toutes les données d'authentification
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
        prefs.remove(_userProfileKey),
      ]);
    } catch (e) {
      // Intentionally empty catch block
    }
  }
}
