import 'package:flutter/material.dart';
import '../../../core/resources/typography.dart';

/// Full-page loading overlay that blocks user interactions
/// Shows a centered spinner with an optional message
class FullPageLoader extends StatelessWidget {
  final String? message;

  const FullPageLoader({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: AppTypography.title2.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
