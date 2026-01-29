import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naavi/core/di/SplashScreenProvider.dart';
import 'package:naavi/presentation/splash/state/SplashScreenState.dart';

import '../../core/resources/colors.dart';

class SplashScreenPage extends ConsumerStatefulWidget {
  const SplashScreenPage({super.key});

  @override
  ConsumerState<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends ConsumerState<SplashScreenPage> {
  int _currentMessageIndex = 0;
  bool _hasNavigated = false; // Flag pour éviter la navigation multiple

  final List<String> _messages = [
    "Découvrez de nouveaux sentiers",
    "Explorez la nature",
    "Partagez vos aventures",
  ];

  @override
  void initState() {
    super.initState();
    _startMessageRotation();

    // Démarrer le chargement après l'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchLocalHike();
    });
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
        _startMessageRotation();
      }
    });
  }

  Future<void> fetchLocalHike() async {
    ref.read(splashScreenProvider.notifier).fetchLocalHike();
  }

  Future<void> determineDestination(bool userWantsToContinue) async {
    ref
        .read(splashScreenProvider.notifier)
        .determineDestination(context, userWantsToContinue);
  }

  @override
  Widget build(BuildContext context) {
    var splashScreenState = ref.watch(splashScreenProvider);

    // Gérer automatiquement la navigation avec une garde pour éviter les déclenchements multiples
    ref.listen<SplashScreenState>(splashScreenProvider, (previous, next) {
      // Ne naviguer que si on passe à HikeNotFetched et qu'on n'a pas déjà navigué
      if (next is SplashScreenStateHikeNotFetched && !_hasNavigated) {
        _hasNavigated = true;
        // Ajouter un délai pour tester le splash screen (3 secondes)
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _hasNavigated) {
            determineDestination(false);
          } else {}
        });
      } else if (_hasNavigated) {}
    });

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              SizedBox(
                width: 182,
                height: 245,
                child: SvgPicture.asset(
                  'assets/icons/logo/logo-dark.svg',
                  width: 182,
                  height: 245,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF9FC484),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Message dynamique en bas
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _messages[_currentMessageIndex],
                  key: ValueKey(_currentMessageIndex),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Lexend Deca',
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Gestion des erreurs
              if (splashScreenState is SplashScreenStateError)
                Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Une erreur est survenue",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Lexend Deca',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
