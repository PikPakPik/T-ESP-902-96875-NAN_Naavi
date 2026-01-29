import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';

/// Types de feedback disponibles
enum FeedbackType { success, error, info, warning }

/// Classe utilitaire pour afficher des overlays de feedback animés
class FeedbackOverlay {
  /// Affiche un overlay de succès
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, type: FeedbackType.success);
  }

  /// Affiche un overlay d'erreur
  static void showError(BuildContext context, String message) {
    _show(context, message: message, type: FeedbackType.error);
  }

  /// Affiche un overlay d'info
  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, type: FeedbackType.info);
  }

  /// Affiche un overlay de warning
  static void showWarning(BuildContext context, String message) {
    _show(context, message: message, type: FeedbackType.warning);
  }

  /// Affiche un overlay de chargement
  /// Retourne une fonction pour fermer l'overlay
  static VoidCallback showLoading(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayWidget(message: message),
    );

    overlay.insert(overlayEntry);

    return () {
      overlayEntry.remove();
    };
  }

  static void _show(
    BuildContext context, {
    required String message,
    required FeedbackType type,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FeedbackOverlayWidget(
        message: message,
        type: type,
        duration: duration,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _FeedbackOverlayWidget extends StatefulWidget {
  final String message;
  final FeedbackType type;
  final Duration duration;
  final VoidCallback onComplete;

  const _FeedbackOverlayWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<_FeedbackOverlayWidget> createState() => _FeedbackOverlayWidgetState();
}

class _FeedbackOverlayWidgetState extends State<_FeedbackOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.45, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case FeedbackType.success:
        return AppColors.secondaryColor;
      case FeedbackType.error:
        return const Color(0xFFB33A3A);
      case FeedbackType.info:
        return const Color(0xFF3A7AB3);
      case FeedbackType.warning:
        return const Color(0xFFB38A3A);
    }
  }

  Color get _glowColor {
    switch (widget.type) {
      case FeedbackType.success:
        return AppColors.secondaryColor.withValues(alpha: 0.4);
      case FeedbackType.error:
        return const Color(0xFFB33A3A).withValues(alpha: 0.4);
      case FeedbackType.info:
        return const Color(0xFF3A7AB3).withValues(alpha: 0.4);
      case FeedbackType.warning:
        return const Color(0xFFB38A3A).withValues(alpha: 0.4);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case FeedbackType.success:
        return Icons.check_rounded;
      case FeedbackType.error:
        return Icons.close_rounded;
      case FeedbackType.info:
        return Icons.info_outline_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          color: Colors.black.withValues(alpha: 0.4 * _opacityAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor,
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Transform.scale(
                        scale: _iconAnimation.value,
                        child: Icon(_icon, color: Colors.white, size: 50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Lexend Deca',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget pour l'overlay de chargement
class _LoadingOverlayWidget extends StatefulWidget {
  final String message;

  const _LoadingOverlayWidget({required this.message});

  @override
  State<_LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<_LoadingOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          color: Colors.black.withValues(alpha: 0.4 * _opacityAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Lexend Deca',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
