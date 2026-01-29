import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTapped;

  const MenuNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Sur Android, on réduit le padding bottom car SafeArea peut être trop généreux
    final bottomPadding = Platform.isAndroid
        ? MediaQuery.of(context).padding.bottom * 1.5
        : MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      color: const Color(0xFF241913),
      child: Container(
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFF241913),
          border: Border(top: BorderSide(color: Colors.white, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavItem(
              context,
              icon: Icons.account_balance_outlined,
              index: 0,
              selected: selectedIndex == 0,
              route: '/poi_explorer',
            ),
            _buildNavItem(
              context,
              icon: Icons.explore,
              index: 1,
              selected: selectedIndex == 1,
              route: '/',
            ),
            _buildNavItem(
              context,
              icon: Icons.person,
              index: 2,
              selected: selectedIndex == 2,
              route: '/profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required int index,
    required bool selected,
    required String route,
  }) {
    String label = index == 0
        ? 'Découvrir'
        : index == 1
        ? 'Explorer'
        : 'Profil';

    return Expanded(
      child: InkWell(
        onTap: () {
          // Les bottom sheets sont maintenant des widgets conditionnels (comme RecapHike)
          // donc ils se ferment automatiquement lors de la navigation
          onItemTapped(index);
          context.go(route);
        },
        splashColor: Colors.white24,
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.grey,
                  size: 22,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontSize: 10,
                    fontFamily: 'Lexend Deca',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
