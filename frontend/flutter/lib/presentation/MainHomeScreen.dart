import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naavi/presentation/common/MenuNavBar.dart';

class MainHomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainHomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF241913),
      bottomNavigationBar: MenuNavBar(
        selectedIndex: navigationShell.currentIndex,
        onItemTapped: (index) {
          // Naviguer vers la branche correspondante
          // pageTransition: false évite les animations de transition
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
      // Le navigationShell gère automatiquement l'affichage de la bonne branche
      // et conserve l'état de chaque branche
      body: navigationShell,
    );
  }
}