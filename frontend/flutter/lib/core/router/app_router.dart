import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:naavi/presentation/explorer/HomeMapExplorerPage.dart';
import 'package:naavi/presentation/poi_explorer/PoiExplorerPage.dart';
import 'package:naavi/presentation/profile/EditProfilePage.dart';
import 'package:naavi/presentation/profile/ProfilePage.dart';
import 'package:naavi/presentation/splash/SplashScreenPage.dart';
import 'package:naavi/presentation/search/SearchPage.dart';

import 'package:naavi/presentation/auth/AuthPage.dart';

import '../../domain/entities/Hike.dart';
import '../../presentation/MainHomeScreen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splashScreen',
  routes: [
    GoRoute(
      path: '/splashScreen',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SplashScreenPage()),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: AuthPage()),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SearchPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Animation combinée : fade + slide pour une transition fluide
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    ),
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EditProfilePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // navigationShell gère automatiquement la navigation entre les branches
        return MainHomeScreen(navigationShell: navigationShell);
      },
      branches: [
        // Branche 0: POI Explorer
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/poi_explorer',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PoiExplorerPage()),
            ),
          ],
        ),

        // Branche 1: Home Map Explorer (page principale)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) {
                Position? initialPosition;
                Hike? hike;

                if (state.extra is Position) {
                  initialPosition = state.extra as Position;
                } else if (state.extra is Hike) {
                  hike = state.extra as Hike;
                }

                return NoTransitionPage(
                  child: HomeMapExplorerPage(
                    hike: hike,
                    initialPosition: initialPosition,
                  ),
                );
              },
            ),
          ],
        ),

        // Branche 2: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfilePage()),
            ),
          ],
        ),
      ],
    ),
  ],
);
