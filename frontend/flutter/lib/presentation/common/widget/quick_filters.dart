import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Composant réutilisable pour afficher des filtres rapides avec animation
class QuickFilters extends StatefulWidget {
  /// Liste des filtres à afficher
  final List<QuickFilter> filters;

  /// Indices des filtres sélectionnés
  final Set<int> selectedIndices;

  /// Callback appelé lorsqu'un filtre est sélectionné/désélectionné
  final Function(int index, bool isSelected) onFilterChanged;

  const QuickFilters({
    super.key,
    required this.filters,
    required this.selectedIndices,
    required this.onFilterChanged,
  });

  @override
  State<QuickFilters> createState() => _QuickFiltersState();
}

class _QuickFiltersState extends State<QuickFilters> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.filters.length,
        itemBuilder: (context, index) {
          final filter = widget.filters[index];
          final isSelected = widget.selectedIndices.contains(index);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                final newIsSelected = !isSelected;
                widget.onFilterChanged(index, newIsSelected);
              },
              child: _AnimatedFilter(
                name: filter.name,
                icon: filter.icon,
                isSelected: isSelected,
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget interne pour un filtre animé
class _AnimatedFilter extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final int index;

  const _AnimatedFilter({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: IntrinsicWidth(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            border: Border.all(color: Colors.white, width: 0.5),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône fixe qui change juste de couleur
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primaryColor : Colors.white,
                  size: 20,
                ),
              ),
              // Texte qui apparaît à droite de l'icône
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      axisAlignment: -1.0, // Aligné à gauche
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(-0.3, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: isSelected
                    ? Padding(
                        key: ValueKey('text-$index'),
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Lexend Deca',
                            fontSize: 14,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modèle pour un filtre rapide
class QuickFilter {
  final String name;
  final IconData icon;

  const QuickFilter({required this.name, required this.icon});
}
