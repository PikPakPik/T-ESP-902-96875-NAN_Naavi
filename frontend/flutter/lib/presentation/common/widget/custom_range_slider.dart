import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Composant RangeSlider personnalisé réutilisable
class CustomRangeSlider extends StatelessWidget {
  /// Valeurs min et max du slider
  final RangeValues values;

  /// Valeur minimale possible
  final double min;

  /// Valeur maximale possible
  final double max;

  /// Nombre de divisions (par défaut: 180)
  final double divisions;

  /// Callback appelé lors du changement de valeur
  final ValueChanged<RangeValues> onChanged;

  /// Unité à afficher (ex: "km", "m", etc.)
  final String unit;

  /// Couleur de la partie remplie (par défaut: secondaryColor)
  final Color? activeColor;

  /// Couleur de la partie non remplie (par défaut: blanc)
  final Color? inactiveColor;

  /// Couleur du thumb gauche (par défaut: secondaryColor)
  final Color? leftThumbColor;

  /// Couleur de la bordure du thumb gauche (par défaut: tertiaryColor)
  final Color? leftThumbBorderColor;

  /// Couleur du thumb droit (par défaut: tertiaryColor)
  final Color? rightThumbColor;

  /// Couleur de la bordure du thumb droit (par défaut: tertiaryColor plus clair)
  final Color? rightThumbBorderColor;

  /// Style du texte des labels (optionnel)
  final TextStyle? labelTextStyle;

  /// Style du texte des valeurs min/max (optionnel)
  final TextStyle? minMaxTextStyle;

  const CustomRangeSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    this.divisions = 180,
    required this.onChanged,
    this.unit = 'km',
    this.activeColor,
    this.inactiveColor,
    this.leftThumbColor,
    this.leftThumbBorderColor,
    this.rightThumbColor,
    this.rightThumbBorderColor,
    this.labelTextStyle,
    this.minMaxTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppColors.secondaryColor;
    final effectiveInactiveColor = inactiveColor ?? Colors.white;
    final effectiveLeftThumbColor = leftThumbColor ?? AppColors.secondaryColor;
    final effectiveLeftThumbBorderColor =
        leftThumbBorderColor ?? AppColors.tertiaryColor;
    final effectiveRightThumbColor = rightThumbColor ?? AppColors.tertiaryColor;
    final effectiveRightThumbBorderColor =
        rightThumbBorderColor ?? AppColors.tertiaryColor.withValues(alpha: 0.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slider avec thème personnalisé
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeThumbShape: _CustomRangeSliderThumbShape(
              leftThumbColor: effectiveLeftThumbColor,
              leftThumbBorderColor: effectiveLeftThumbBorderColor,
              rightThumbColor: effectiveRightThumbColor,
              rightThumbBorderColor: effectiveRightThumbBorderColor,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions.toInt(),
            onChanged: onChanged,
            activeColor: effectiveActiveColor,
            inactiveColor: effectiveInactiveColor,
          ),
        ),
        // Labels des valeurs sélectionnées
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${values.start.round()} $unit',
                style:
                    labelTextStyle ??
                    TextStyle(
                      fontFamily: 'Lexend Deca',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
              Text(
                '${values.end.round()} $unit',
                style:
                    labelTextStyle ??
                    TextStyle(
                      fontFamily: 'Lexend Deca',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Labels min/max
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$min $unit',
              style:
                  minMaxTextStyle ??
                  TextStyle(
                    fontFamily: 'Lexend Deca',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
            ),
            Text(
              '$max $unit',
              style:
                  minMaxTextStyle ??
                  TextStyle(
                    fontFamily: 'Lexend Deca',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shape personnalisé pour les thumbs du RangeSlider
class _CustomRangeSliderThumbShape extends RangeSliderThumbShape {
  final Color leftThumbColor;
  final Color leftThumbBorderColor;
  final Color rightThumbColor;
  final Color rightThumbBorderColor;

  const _CustomRangeSliderThumbShape({
    required this.leftThumbColor,
    required this.leftThumbBorderColor,
    required this.rightThumbColor,
    required this.rightThumbBorderColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(20, 20);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = false,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool isPressed = false,
  }) {
    final Canvas canvas = context.canvas;
    final bool isLeftThumb = thumb == Thumb.start;

    final Color thumbColor;
    final Color borderColor;
    final double borderWidth;

    // Les deux thumbs ont le même design
    if (isLeftThumb) {
      // Thumb gauche : même style que le droit
      thumbColor = rightThumbColor;
      borderColor = rightThumbBorderColor;
      borderWidth = 2.0;
    } else {
      // Thumb droit : vert clair avec bordure
      thumbColor = rightThumbColor;
      borderColor = rightThumbBorderColor;
      borderWidth = 2.0;
    }

    // Effet de zoom lors du clic (utilise activationAnimation seulement si pressé)
    // L'animation va de 0.0 à 1.0, on veut un grossissement de 1.0 à 1.15
    // Ne zoomer que si ce thumb spécifique est pressé
    final scale = isPressed ? 1.0 + (activationAnimation.value * 0.15) : 1.0;
    final scaledRadius = 10 * scale;
    final scaledBorderWidth = borderWidth;

    // Dessiner la bordure avec effet de zoom
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = scaledBorderWidth;

    canvas.drawCircle(center, scaledRadius, borderPaint);

    // Dessiner le thumb avec effet de zoom
    final Paint thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, scaledRadius - scaledBorderWidth / 2, thumbPaint);
  }
}
