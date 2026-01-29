import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Composant radio button personnalisé réutilisable
class CustomRadioButton extends StatefulWidget {
  /// Label du bouton radio
  final String label;

  /// Indique si le bouton est sélectionné
  final bool isSelected;

  /// Callback appelé lors du clic
  final VoidCallback onTap;

  /// Style du texte (optionnel)
  final TextStyle? textStyle;

  /// Couleur de fond quand sélectionné (par défaut: tertiaryColor)
  final Color? selectedColor;

  /// Couleur de bordure quand non sélectionné (par défaut: blanc avec opacité)
  final Color? unselectedBorderColor;

  /// Couleur du texte (optionnel, par défaut: blanc avec opacité selon sélection)
  final Color? textColor;

  const CustomRadioButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.textStyle,
    this.selectedColor,
    this.unselectedBorderColor,
    this.textColor,
  });

  @override
  State<CustomRadioButton> createState() => _CustomRadioButtonState();
}

class _CustomRadioButtonState extends State<CustomRadioButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CustomRadioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor =
        widget.selectedColor ?? AppColors.tertiaryColor;
    final effectiveUnselectedBorderColor =
        widget.unselectedBorderColor ?? Colors.white.withValues(alpha: 0.3);
    final effectiveTextColor =
        widget.textColor ??
        (widget.isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.7));

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style:
                  widget.textStyle ??
                  TextStyle(
                    fontFamily: 'Lexend Deca',
                    fontSize: 16,
                    color: effectiveTextColor,
                  ),
              child: Text(widget.label),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected
                      ? effectiveSelectedColor
                      : effectiveUnselectedBorderColor,
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveSelectedColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
