import 'package:flutter/material.dart';
import 'package:naavi/core/resources/colors.dart';

import '../../../core/resources/typography.dart';

Widget actionButton({
  bool isLoading = false,
  VoidCallback? onPressed,
  String? text,
}) {
  return SizedBox(
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.tertiaryColor,
        shadowColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.secondaryColor,
        textStyle: AppTypography.body1.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
