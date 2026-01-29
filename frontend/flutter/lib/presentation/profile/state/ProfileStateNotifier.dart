import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/network/check_network_service.dart';
import '../../../core/services/turnstile_service.dart';
import '../../../data/models/user_dto.dart';
import 'ProfileState.dart';

/// Notifier pour gérer l'état de la page de profil
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final AuthService authService;
  final CheckNetworkService networkService;

  ProfileStateNotifier({
    required this.authService,
    CheckNetworkService? networkService,
  }) : networkService = networkService ?? CheckNetworkService(),
       super(const ProfileStateInitial());

  /// Charge les informations de l'utilisateur
  /// Utilise le cache en cas de mode hors-ligne
  Future<void> loadUserProfile() async {
    state = const ProfileStateLoading();

    try {
      // Vérifier d'abord si l'utilisateur est authentifié
      final isAuthenticated = await authService.isAuthenticated();

      if (!isAuthenticated) {
        state = const ProfileStateNotAuthenticated();
        return;
      }

      // Vérifier la connexion Internet
      final isOnline = await checkConnectivity();

      if (isOnline) {
        // En ligne : charger depuis l'API
        final userData = await authService.getCurrentUser();

        if (userData != null) {
          final user = UserDto.fromJson(userData);
          state = ProfileStateLoaded(user);
        } else {
          // API échoue, essayer le cache
          await _loadFromCacheOrError();
        }
      } else {
        // Hors-ligne : charger depuis le cache
        await _loadFromCacheOrError(isOffline: true);
      }
    } catch (e) {
      // En cas d'erreur, essayer le cache
      await _loadFromCacheOrError();
    }
  }

  /// Charge le profil depuis le cache ou affiche une erreur
  Future<void> _loadFromCacheOrError({bool isOffline = false}) async {
    final cachedData = await authService.getCachedUserProfile();

    if (cachedData != null) {
      final user = UserDto.fromJson(cachedData);
      if (isOffline) {
        // En mode hors-ligne avec données en cache
        state = ProfileStateOffline(user);
      } else {
        state = ProfileStateLoaded(user);
      }
    } else {
      // Pas de cache disponible
      final isAuthenticated = await authService.isAuthenticated();
      if (!isAuthenticated) {
        state = const ProfileStateNotAuthenticated();
      } else if (isOffline) {
        state = const ProfileStateOffline(null);
      } else {
        state = const ProfileStateError(
          'Impossible de charger les données utilisateur',
        );
      }
    }
  }

  /// Vérifie si l'appareil est connecté à Internet
  Future<bool> checkConnectivity() async {
    try {
      final connectivityState = await networkService.checkConnection();
      return connectivityState == ConnectivityState.online;
    } catch (e) {
      // On platform exception, assume offline to be safe
      return false;
    }
  }

  /// Met à jour les informations du profil utilisateur
  Future<bool> updateProfile({String? firstname, String? lastname}) async {
    // Récupérer l'utilisateur actuel
    UserDto? currentUser;
    if (state is ProfileStateLoaded) {
      currentUser = (state as ProfileStateLoaded).user;
    } else if (state is ProfileStateUpdateSuccess) {
      currentUser = (state as ProfileStateUpdateSuccess).user;
    }

    if (currentUser == null) {
      state = const ProfileStateError('Utilisateur non trouvé');
      return false;
    }

    // Vérifier la connexion Internet
    final isOnline = await checkConnectivity();
    if (!isOnline) {
      state = ProfileStateOffline(currentUser);
      return false;
    }

    // Passer en état de mise à jour
    state = ProfileStateUpdating(currentUser);

    try {
      final updatedUser = await authService.updateUser(
        firstname: firstname,
        lastname: lastname,
      );

      if (updatedUser != null) {
        state = ProfileStateUpdateSuccess(
          updatedUser,
          'Profil mis à jour avec succès',
        );
        return true;
      } else {
        state = ProfileStateUpdateError(
          currentUser,
          'Impossible de mettre à jour le profil',
        );
        return false;
      }
    } catch (e) {
      state = ProfileStateUpdateError(
        currentUser,
        'Erreur lors de la mise à jour: ${e.toString()}',
      );
      return false;
    }
  }

  /// Upload une photo de profil
  Future<bool> uploadProfilePicture(File imageFile) async {
    // Récupérer l'utilisateur actuel
    UserDto? currentUser;
    if (state is ProfileStateLoaded) {
      currentUser = (state as ProfileStateLoaded).user;
    } else if (state is ProfileStateUpdateSuccess) {
      currentUser = (state as ProfileStateUpdateSuccess).user;
    }

    if (currentUser == null) {
      state = const ProfileStateError('Utilisateur non trouvé');
      return false;
    }

    // Vérifier la connexion Internet
    final isOnline = await checkConnectivity();
    if (!isOnline) {
      state = ProfileStateOffline(currentUser);
      return false;
    }

    // Passer en état de mise à jour
    state = ProfileStateUpdating(currentUser);

    try {
      final profilePictureUrl = await authService.uploadProfilePicture(
        imageFile,
      );

      if (profilePictureUrl != null) {
        // Recharger le profil pour avoir les données à jour
        await loadUserProfile();
        return true;
      } else {
        state = ProfileStateUpdateError(
          currentUser,
          'Impossible d\'uploader la photo de profil',
        );
        return false;
      }
    } catch (e) {
      state = ProfileStateUpdateError(
        currentUser,
        'Erreur lors de l\'upload: ${e.toString()}',
      );
      return false;
    }
  }

  /// Revient à l'état chargé après avoir affiché un message de succès
  void dismissSuccessMessage() {
    if (state is ProfileStateUpdateSuccess) {
      final user = (state as ProfileStateUpdateSuccess).user;
      state = ProfileStateLoaded(user);
    }
  }

  /// Revient à l'état chargé après avoir affiché un message d'erreur
  void dismissErrorMessage() {
    if (state is ProfileStateUpdateError) {
      final user = (state as ProfileStateUpdateError).currentUser;
      state = ProfileStateLoaded(user);
    } else if (state is ProfileStateOffline) {
      final user = (state as ProfileStateOffline).currentUser;
      if (user != null) {
        state = ProfileStateLoaded(user);
      } else {
        state = const ProfileStateInitial();
      }
    }
  }

  /// Déconnecte l'utilisateur
  /// Fonctionne même en mode hors-ligne
  Future<void> logout(BuildContext context) async {
    state = const ProfileStateLoggingOut();

    try {
      // signOut() nettoie toujours les données locales, même en cas d'échec de l'API
      await authService.signOut();
    } catch (e) {
      // Les erreurs sont ignorées car signOut() garantit le nettoyage local
    } finally {
      // Toujours naviguer vers /auth car les données locales sont nettoyées
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }

  /// Supprime le compte utilisateur
  Future<bool> deleteAccount(BuildContext context) async {
    try {
      final success = await authService.deleteAccount();

      if (success) {
        if (context.mounted) {
          context.go('/auth');
        }
        return true;
      } else {
        state = const ProfileStateError('Échec de la suppression du compte');
        return false;
      }
    } catch (e) {
      state = ProfileStateError(
        'Erreur lors de la suppression: ${e.toString()}',
      );
      return false;
    }
  }

  /// Demande une réinitialisation de mot de passe
  /// Retourne true si la demande a été envoyée avec succès
  Future<bool> requestPasswordReset() async {
    // Vérifier la connexion Internet
    final isOnline = await checkConnectivity();
    if (!isOnline) {
      return false;
    }

    try {
      // Obtenir un token Turnstile frais
      final token = await TurnstileService.instance.getToken();
      if (token == null) {
        return false;
      }

      return await authService.requestPasswordReset(token);
    } catch (e) {
      return false;
    }
  }

  /// Réinitialise l'état
  void resetState() {
    state = const ProfileStateInitial();
  }
}
