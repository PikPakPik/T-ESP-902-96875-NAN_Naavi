import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Composant segmented control (boutons segmentés) réutilisable
class SegmentedControl<T> extends StatefulWidget {
  /// Liste des options à afficher
  final List<SegmentedOption<T>> options;

  /// Valeur(s) actuellement sélectionnée(s)
  /// - Si allowMultipleSelection est false: T? (une seule valeur)
  /// - Si allowMultipleSelection est true: Set&lt;T&gt; (plusieurs valeurs)
  final dynamic selectedValue;

  /// Callback appelé lors de la sélection d'une option
  /// - Si allowMultipleSelection est false: ValueChanged&lt;T?&gt;
  /// - Si allowMultipleSelection est true: ValueChanged&lt;Set&lt;T&gt;&gt;
  final ValueChanged<dynamic> onSelectionChanged;

  /// Permet la sélection multiple (par défaut: false)
  final bool allowMultipleSelection;

  /// Couleur de fond quand sélectionné (par défaut: tertiaryColor)
  final Color? selectedColor;

  /// Couleur de fond quand non sélectionné (par défaut: secondaryColor)
  final Color? unselectedColor;

  /// Couleur du texte quand sélectionné (par défaut: primaryColor)
  final Color? selectedTextColor;

  /// Couleur du texte quand non sélectionné (par défaut: blanc)
  final Color? unselectedTextColor;

  /// Style du texte (optionnel)
  final TextStyle? textStyle;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelectionChanged,
    this.allowMultipleSelection = false,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.textStyle,
  });

  @override
  State<SegmentedControl<T>> createState() => _SegmentedControlState<T>();
}

class _SegmentedControlState<T> extends State<SegmentedControl<T>>
    with TickerProviderStateMixin {
  final Map<T, AnimationController> _animationControllers = {};
  final Map<T, Animation<double>> _scaleAnimations = {};

  @override
  void initState() {
    super.initState();
    // Initialiser les animations pour chaque option
    for (final option in widget.options) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      final animation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
      _animationControllers[option.value] = controller;
      _scaleAnimations[option.value] = animation;
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(T optionValue, bool isSelected) {
    // Animation de zoom lors du clic
    final controller = _animationControllers[optionValue];
    if (controller != null) {
      controller.forward().then((_) {
        controller.reverse();
      });
    }

    // Appeler le callback
    if (widget.allowMultipleSelection) {
      final currentSet = (widget.selectedValue as Set<T>? ?? <T>{}).toSet();
      if (isSelected) {
        currentSet.remove(optionValue);
      } else {
        currentSet.add(optionValue);
      }
      widget.onSelectionChanged(currentSet);
    } else {
      widget.onSelectionChanged(isSelected ? null : optionValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor =
        widget.selectedColor ?? AppColors.tertiaryColor;
    final effectiveUnselectedColor =
        widget.unselectedColor ?? AppColors.secondaryColor;
    final effectiveSelectedTextColor =
        widget.selectedTextColor ?? AppColors.primaryColor;
    final effectiveUnselectedTextColor =
        widget.unselectedTextColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: effectiveUnselectedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: widget.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = widget.allowMultipleSelection
              ? (widget.selectedValue as Set<T>? ?? <T>{}).contains(
                  option.value,
                )
              : widget.selectedValue == option.value;

          // Déterminer les coins arrondis selon la position
          BorderRadius? borderRadius;
          if (widget.options.length == 1) {
            borderRadius = BorderRadius.circular(12);
          } else if (index == 0) {
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            );
          } else if (index == widget.options.length - 1) {
            borderRadius = const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            );
          } else {
            borderRadius = BorderRadius.zero;
          }

          final scaleAnimation =
              _scaleAnimations[option.value] ??
              AlwaysStoppedAnimation<double>(1.0);

          return Expanded(
            child: GestureDetector(
              onTap: () => _handleTap(option.value, isSelected),
              child: ScaleTransition(
                scale: scaleAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? effectiveSelectedColor
                        : Colors.transparent,
                    borderRadius: borderRadius,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style:
                        widget.textStyle ??
                        TextStyle(
                          fontFamily: 'Lexend Deca',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? effectiveSelectedTextColor
                              : effectiveUnselectedTextColor,
                        ),
                    child: Text(option.label, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Classe pour représenter une option dans le segmented control
class SegmentedOption<T> {
  final String label;
  final T value;

  const SegmentedOption({required this.label, required this.value});
}
