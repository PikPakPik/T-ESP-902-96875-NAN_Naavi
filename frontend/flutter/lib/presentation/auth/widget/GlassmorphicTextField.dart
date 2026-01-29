import 'dart:ui';
import 'package:flutter/material.dart';

/// Widget de champ de texte avec effet glassmorphisme
/// Utilisé pour les champs de formulaire sur fond d'image
class GlassmorphicTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final String? errorText;

  const GlassmorphicTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade400
                      : Colors.white.withValues(alpha: 0.3),
                  width: hasError ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                enabled: enabled,
                style: TextStyle(
                  fontFamily: 'Lexend Deca',
                  fontSize: 14,
                  color: enabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontFamily: 'Lexend Deca',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 19,
                  ),
                ),
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 12,
                color: Colors.red.shade300,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
