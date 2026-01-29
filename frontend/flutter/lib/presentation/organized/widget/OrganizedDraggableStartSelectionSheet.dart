import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/resources/colors.dart';
import '../../../core/resources/typography.dart';
import '../../../core/di/MapProviders.dart'
    show organizedHikeProvider, organizedSheetHeightProvider;
import '../state/OrganizedHikeState.dart';
import 'OrganizedStartSelectionSheet.dart';

/// États possibles de la sheet
enum StartSelectionSheetState {
  minimized,   // 10% - juste le texte
  buttons,     // 30% - texte + boutons de sélection
  suggestions, // 90% - texte + boutons + suggestions
}

/// Wrapper draggable pour OrganizedStartSelectionSheet
/// 3 états : minimisé (10%), boutons (30%), suggestions (90%)
class OrganizedDraggableStartSelectionSheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const OrganizedDraggableStartSelectionSheet({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<OrganizedDraggableStartSelectionSheet> createState() =>
      _OrganizedDraggableStartSelectionSheetState();
}

class _OrganizedDraggableStartSelectionSheetState
    extends ConsumerState<OrganizedDraggableStartSelectionSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  // Constantes pour les tailles
  static const double _minimizedSize = 0.11;    // 10% - juste le texte
  static const double _buttonsSize = 0.31;      // 30% - boutons de sélection
  static const double _suggestionsSize = 0.90;  // 90% - suggestions

  StartSelectionSheetState _currentState = StartSelectionSheetState.buttons;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleSheetSizeChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSheetSizeChange);
    _controller.dispose();
    super.dispose();
  }

  /// Minimise la sheet à 10%
  void _minimizeSheet() {
    if (_controller.isAttached) {
      _controller.animateTo(
        _minimizedSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Remet la sheet à 30% (état boutons)
  void _expandToButtons() {
    if (_controller.isAttached) {
      _controller.animateTo(
        _buttonsSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Détecte l'état actuel selon la taille de la sheet
  void _handleSheetSizeChange() {
    if (!_controller.isAttached) return;

    final size = _controller.size;

    StartSelectionSheetState newState;

    if (size < 0.20) {
      newState = StartSelectionSheetState.minimized;
    } else if (size < 0.60) {
      newState = StartSelectionSheetState.buttons;
    } else {
      newState = StartSelectionSheetState.suggestions;
    }

    if (newState != _currentState) {
      setState(() {
        _currentState = newState;
      });
    }
  }

  /// Met à jour la hauteur de la sheet en pixels dans le provider
  void _updateSheetHeight(BuildContext context) {
    if (!_controller.isAttached) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * _controller.size;
    ref.read(organizedSheetHeightProvider.notifier).state = sheetHeight;
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état pour minimiser/agrandir la sheet
    ref.listen<OrganizedHikeState>(organizedHikeProvider, (previous, next) {
      // Si on passe en mode sélection manuelle, minimiser la sheet
      if (next is OrganizedHikeSelectingStart && next.isSelectingManually) {
        final wasManuallySelecting = previous is OrganizedHikeSelectingStart &&
            previous.isSelectingManually;
        if (!wasManuallySelecting) {
          _minimizeSheet();
        }
      }
      // Si on annule la sélection manuelle, remettre la sheet à l'état boutons
      if (previous is OrganizedHikeSelectingStart && previous.isSelectingManually &&
          next is OrganizedHikeSelectingStart && !next.isSelectingManually && !next.hasPreviewStart) {
        _expandToButtons();
      }
    });

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Mettre à jour la hauteur en pixels
        final sheetHeight = notification.extent * MediaQuery.of(context).size.height;
        ref.read(organizedSheetHeightProvider.notifier).state = sheetHeight;
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: _buttonsSize,
        minChildSize: _minimizedSize,
        maxChildSize: _suggestionsSize,
        snap: true,
        snapSizes: const [_minimizedSize, _buttonsSize, _suggestionsSize],
        builder: (context, scrollController) {
          // Initialiser la hauteur au premier build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.isAttached) {
              _updateSheetHeight(context);
            }
          });
          return Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator avec bouton retour à gauche
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
                child: Row(
                  children: [
                    // Bouton retour à gauche
                    /*GestureDetector(
                      onTap: widget.onClose,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                    ),*/
                    // Handle indicator centré
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Espace pour équilibrer
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildContentForState(),
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  /// Construit le contenu selon l'état actuel
  Widget _buildContentForState() {
    switch (_currentState) {
      case StartSelectionSheetState.minimized:
        return _buildMinimizedContent();
      case StartSelectionSheetState.buttons:
        return _buildButtonsContent();
      case StartSelectionSheetState.suggestions:
        return _buildSuggestionsContent();
    }
  }

  /// État minimisé (10%) : juste le texte d'instruction
  Widget _buildMinimizedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Sélectionner un point de départ',
              style: AppTypography.body1.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// État boutons (30%) : texte + boutons de sélection
  Widget _buildButtonsContent() {
    return OrganizedStartSelectionSheet(
      onClose: widget.onClose,
    );
  }

  /// État suggestions (90%) : texte + boutons + zone de suggestions
  Widget _buildSuggestionsContent() {
    return Column(
      children: [
        // Contenu des boutons
        OrganizedStartSelectionSheet(
          onClose: widget.onClose,
        ),

        // Séparateur
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),

              // Titre suggestions
              Text(
                'Suggestions',
                style: AppTypography.title2.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Placeholder pour les suggestions futures
              _buildSuggestionsPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }

  /// Placeholder pour les suggestions (à implémenter plus tard)
  Widget _buildSuggestionsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.explore_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Les suggestions apparaîtront ici',
            style: AppTypography.body2.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 300), // Espace pour permettre le scroll
        ],
      ),
    );
  }
}
