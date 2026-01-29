import 'package:flutter/material.dart';
import 'package:naavi/core/resources/typography.dart';

/// Widgets de boutons réutilisables pour l'application
/// Extraits de HomeMapExplorerPage pour réutilisabilité

/// Bouton large pleine largeur avec style standard
class LargeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool disabled;

  const LargeButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          foregroundColor: disabled ? Colors.grey[600] : Colors.black,
          textStyle: AppTypography.body1,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
        ),
        child: Text(
          text,
          style: AppTypography.body1.copyWith(
            color: disabled ? Colors.grey[600] : Colors.black,
          ),
        ),
      ),
    );
  }
}

/// Bouton d'action avec support pour l'état de chargement
class ActionButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? text;

  const ActionButton({
    super.key,
    this.isLoading = false,
    this.onPressed,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
          textStyle: AppTypography.body1,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: isLoading
              ? const CircularProgressIndicator()
              : Text(text ?? "Error"),
        ),
      ),
    );
  }
}

/// Bouton circulaire avec icône (image asset)
class CircleIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String assetsPath;
  final double size;

  const CircleIconButton({
    super.key,
    required this.onPressed,
    required this.assetsPath,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(child: Image.asset(assetsPath, fit: BoxFit.contain)),
      ),
    );
  }
}
