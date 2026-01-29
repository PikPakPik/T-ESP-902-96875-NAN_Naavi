import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

enum AuthButtonType { social, primary }

/// Widget de bouton pour la page d'authentification
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AuthButtonType type;
  final bool disabled;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = AuthButtonType.social,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = type == AuthButtonType.social
        ? Colors.white
        : AppColors.tertiaryColor;

    final foregroundColor = AppColors.secondaryColor;

    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        onPressed: isLoading || disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
          disabledBackgroundColor: disabled
              ? backgroundColor.withValues(alpha: 0.6)
              : backgroundColor,
          disabledForegroundColor: disabled
              ? foregroundColor.withValues(alpha: 0.6)
              : foregroundColor,
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Lexend Deca',
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
      ),
    );
  }
}
