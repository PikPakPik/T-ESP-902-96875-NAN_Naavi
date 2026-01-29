import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:naavi/core/services/auth/auth_service.dart';
import 'package:naavi/domain/entities/Hike.dart';
import 'package:naavi/domain/usecases/storeHikingUseCase.dart';
import 'package:naavi/presentation/splash/state/SplashScreenState.dart';

class SplashScreenStateNotifier extends StateNotifier<SplashScreenState> {
  final StoreHikingUseCase storeHikingUseCase;
  final AuthService authService;

  Hike? hike;
  Position? initialPosition;
  String? userEmail; // Email à pré-remplir si la session a expiré

  SplashScreenStateNotifier({
    required this.storeHikingUseCase,
    required this.authService,
  }) : super(const SplashScreenStateLoading());

  Future<void> fetchLocalHike() async {
    try {
      var fetchedhike = await storeHikingUseCase.getLocalHike();

      // Supprimer toute randonnée en pause pour toujours démarrer sur une page vierge
      if (fetchedhike != null) {
        await storeHikingUseCase.clearLocalHike();
      }

      // Récupérer la position en arrière-plan sans bloquer
      _waitForLocation();

      // Aller directement sur la map sans attendre la position
      state = const SplashScreenStateHikeNotFetched();
    } catch (e) {
      state = const SplashScreenStateError();
    }
  }

  Future<void> _waitForLocation() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Récupérer la position actuelle (avec timeout de 10 secondes)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Sauvegarder la position initiale pour la transmettre à la carte
      initialPosition = position;
    } catch (e) {
      // Continuer quand même même si la position n'est pas disponible
    }
  }

  Future<void> determineDestination(
    BuildContext context,
    bool userWantsToContinue,
  ) async {
    // Vérifier l'authentification avec un timeout pour éviter de bloquer
    String sessionStatus;

    try {
      sessionStatus = await authService.checkAndRestoreSession().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return 'unauthenticated';
        },
      );
    } catch (e) {
      sessionStatus = 'unauthenticated';
    }

    if (!context.mounted) {
      return;
    }

    if (sessionStatus == 'authenticated') {
      // Utilisateur authentifié, aller sur la page d'accueil
      context.go('/');
    } else if (sessionStatus == 'unauthenticated') {
      // Pas de session, aller sur la page d'authentification
      context.go('/auth');
    } else {
      // Session expirée, aller sur la page d'auth avec email pré-rempli
      userEmail = sessionStatus;
      // TODO: Passer l'email à la page d'auth via extra ou query params
      context.go('/auth');
    }
  }
}
