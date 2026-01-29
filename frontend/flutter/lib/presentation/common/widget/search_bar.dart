import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/resources/colors.dart';

/// Barre de recherche stylisée basée sur le design SVG
/// Affiche un placeholder et navigue vers la page de recherche au clic
/// Supporte deux états : normal (fond sombre) et compact (fond blanc)
class CustomSearchBar extends StatelessWidget {
  final String placeholder;
  final VoidCallback? onTap;
  final bool isCompact;
  final String heroTag;

  const CustomSearchBar({
    super.key,
    this.placeholder = 'Rechercher un parcours',
    this.onTap,
    this.isCompact = false,
    this.heroTag = 'search_bar',
  });

  @override
  Widget build(BuildContext context) {
    final widget = GestureDetector(
      onTap: onTap ?? () => context.push('/search'),
      child: Container(
        width: isCompact ? 242 : 338,
        height: isCompact ? 32 : 34,
        decoration: BoxDecoration(
          color: isCompact ? Colors.white : AppColors.primaryColor,
          borderRadius: BorderRadius.circular(isCompact ? 15.5 : 16.75),
          border: Border.all(color: Colors.black, width: 0.5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: 0,
          ),
          child: Row(
            children: [
              // Icône de recherche (loupe)
              SizedBox(
                width: isCompact ? 16 : 18,
                height: isCompact ? 16 : 18,
                child: Icon(
                  Icons.search,
                  color: isCompact ? const Color(0xFF323232) : Colors.white,
                  size: isCompact ? 16 : 18,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                // Texte placeholder (seulement en mode normal)
                Expanded(
                  child: Text(
                    placeholder,
                    style: TextStyle(
                      fontFamily: 'Lexend Deca',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // Icône de filtre (seulement en mode compact)
              if (isCompact) ...[
                const Spacer(),
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 0.5),
                  ),
                  child: Icon(Icons.settings, color: Colors.black),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Utiliser Hero pour l'animation de transition
    return Hero(
      tag: heroTag,
      child: Material(color: Colors.transparent, child: widget),
    );
  }
}
