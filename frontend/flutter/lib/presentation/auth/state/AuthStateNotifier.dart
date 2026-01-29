import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naavi/core/services/auth/auth_service.dart';
import 'package:naavi/core/services/network/check_network_service.dart';
import 'package:naavi/core/services/turnstile_service.dart';
import 'package:naavi/core/validators/password_validator.dart';
import 'AuthState.dart';

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  final CheckNetworkService checkNetworkService;

  AuthStateNotifier({
    required this.authService,
    required this.checkNetworkService,
  }) : super(const AuthStateInitial());

  /// Vérifie la connectivité et met à jour l'état si hors-ligne
  Future<bool> checkConnectivity() async {
    try {
      final connectivityState = await checkNetworkService.checkConnection();
      if (connectivityState == ConnectivityState.offline) {
        state = const AuthStateOffline();
        return false;
      }
      return true;
    } catch (e) {
      // On platform exception, assume offline to be safe
      state = const AuthStateOffline();
      return false;
    }
  }

  /// Réinitialise l'état offline si la connexion est rétablie
  Future<void> refreshConnectivity() async {
    if (state is AuthStateOffline) {
      final connectivityState = await checkNetworkService.checkConnection();
      if (connectivityState == ConnectivityState.online) {
        state = const AuthStateInitial();
      }
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    // Vérifier la connexion
    if (!await checkConnectivity()) return;

    state = const AuthStateLoading();
    try {
      final success = await authService.signInWithGoogle();
      if (success) {
        state = const AuthStateSuccess();
        if (context.mounted) {
          context.go('/');
        }
      } else {
        state = const AuthStateError('Échec de la connexion avec Google');
      }
    } catch (e) {
      state = AuthStateError('Erreur: ${e.toString()}');
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    // Vérifier la connexion
    if (!await checkConnectivity()) return;

    state = const AuthStateLoading();
    try {
      final success = await authService.signInWithApple();
      if (success) {
        state = const AuthStateSuccess();
        if (context.mounted) {
          context.go('/');
        }
      } else {
        state = const AuthStateError('Échec de la connexion avec Apple');
      }
    } catch (e) {
      state = AuthStateError('Erreur: ${e.toString()}');
    }
  }

  Future<void> checkEmail(BuildContext context, String email) async {
    if (email.isEmpty || !_isValidEmail(email)) {
      state = const AuthStateError('Veuillez entrer une adresse email valide');
      return;
    }

    // Vérifier la connexion
    if (!await checkConnectivity()) return;

    state = const AuthStateLoading();
    try {
      // Obtenir un token Turnstile frais
      final token = await TurnstileService.instance.getToken();
      if (token == null) {
        state = const AuthStateError('Erreur de vérification de sécurité');
        return;
      }

      final emailExists = await authService.checkEmailExists(email, token);
      if (emailExists) {
        state = AuthStatePasswordRequired(email);
      } else {
        state = AuthStateCreatePassword(email);
      }
    } catch (e) {
      state = AuthStateError('Erreur: ${e.toString()}');
    }
  }

  Future<void> loginWithPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (password.isEmpty) {
      state = const AuthStateError('Veuillez entrer votre mot de passe');
      return;
    }

    // Vérifier la connexion
    if (!await checkConnectivity()) return;

    state = const AuthStateLoading();
    try {
      // Obtenir un token Turnstile frais
      final token = await TurnstileService.instance.getToken();
      if (token == null) {
        state = const AuthStateError('Erreur de vérification de sécurité');
        return;
      }

      final result = await authService.login(email, password, token);
      if (result != null) {
        state = const AuthStateSuccess();
        if (context.mounted) {
          context.go('/');
        }
      } else {
        state = const AuthStateError('Email ou mot de passe incorrect');
      }
    } catch (e) {
      state = AuthStateError('Erreur: ${e.toString()}');
    }
  }

  Future<void> createAccountWithPassword(
    BuildContext context,
    String email,
    String firstname,
    String lastname,
    String password,
    String confirmPassword,
  ) async {
    if (firstname.trim().isEmpty) {
      state = const AuthStateError('Veuillez entrer votre prénom');
      return;
    }

    if (lastname.trim().isEmpty) {
      state = const AuthStateError('Veuillez entrer votre nom');
      return;
    }

    if (password.isEmpty) {
      state = const AuthStateError('Veuillez entrer un mot de passe');
      return;
    }

    if (password != confirmPassword) {
      state = const AuthStateError('Les mots de passe ne correspondent pas');
      return;
    }

    final passwordValidationMessage =
        PasswordValidator.getValidationMessage(password);
    if (passwordValidationMessage != null) {
      state = AuthStateError(passwordValidationMessage);
      return;
    }

    // Vérifier la connexion
    if (!await checkConnectivity()) return;

    state = const AuthStateLoading();
    try {
      // Obtenir un token Turnstile frais
      final token = await TurnstileService.instance.getToken();
      if (token == null) {
        state = const AuthStateError('Erreur de vérification de sécurité');
        return;
      }

      final result = await authService.createAccount(
        email,
        password,
        token,
        firstname: firstname.trim(),
        lastname: lastname.trim(),
      );
      if (result != null) {
        // Supprimer les tokens pour forcer l'utilisateur à se connecter
        await authService.signOut();
        // Passer à l'état AccountCreated pour rediriger vers le login avec l'email
        state = AuthStateAccountCreated(email);
      } else {
        state = const AuthStateError('Échec de la création du compte');
      }
    } catch (e) {
      state = AuthStateError('Erreur: ${e.toString()}');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    // Check for consecutive dots which are invalid
    if (email.contains('..')) {
      return false;
    }
    return emailRegex.hasMatch(email);
  }

  void resetState() {
    state = const AuthStateInitial();
  }

  /// Permet de passer l'authentification et d'aller directement sur la page principale
  void skipAuthentication(BuildContext context) {
    if (context.mounted) {
      context.go('/');
    }
  }

  /// Demande une réinitialisation de mot de passe pour un email donné
  /// Retourne true si la demande a été envoyée avec succès
  /// Note: La validation de l'email doit être faite côté UI avant d'appeler cette méthode
  Future<bool> forgotPassword(String email) async {
    // Vérifier la connexion
    if (!await checkConnectivity()) return false;

    try {
      // Obtenir un token Turnstile frais
      final token = await TurnstileService.instance.getToken();
      if (token == null) {
        return false;
      }

      final success = await authService.requestPasswordResetForEmail(email, token);
      return success;
    } catch (e) {
      return false;
    }
  }
}
