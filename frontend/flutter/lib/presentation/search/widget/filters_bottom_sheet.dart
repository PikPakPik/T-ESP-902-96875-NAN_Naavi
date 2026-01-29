import 'package:flutter/material.dart';
import '../../../core/resources/colors.dart';
import '../../common/widget/custom_radio_button.dart';
import '../../common/widget/segmented_control.dart';
import '../../common/widget/custom_range_slider.dart';

/// Énumération pour le tri
enum SortOption {
  closest('Le plus proche'),
  mostPopular('Le plus populaire');

  final String label;
  const SortOption(this.label);
}

/// Énumération pour la difficulté
enum DifficultyFilter {
  easy('Facile'),
  medium('Moyen'),
  hard('Difficile');

  final String label;
  const DifficultyFilter(this.label);
}

/// Bottom sheet pour les filtres de recherche
class FiltersBottomSheet extends StatefulWidget {
  final SortOption? initialSort;
  final Set<DifficultyFilter>? initialDifficulties;
  final RangeValues? initialDistance;
  final Function(SortOption?, Set<DifficultyFilter>, RangeValues?) onApply;

  const FiltersBottomSheet({
    super.key,
    this.initialSort,
    this.initialDifficulties,
    this.initialDistance,
    required this.onApply,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  SortOption? _selectedSort;
  Set<DifficultyFilter> _selectedDifficulties = {};
  RangeValues _distanceRange = const RangeValues(0, 180);

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort ?? SortOption.closest;
    _selectedDifficulties = widget.initialDifficulties ?? <DifficultyFilter>{};
    _distanceRange = widget.initialDistance ?? const RangeValues(0, 180);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée de drag
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // En-tête avec titre et bouton fermer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(
                    fontFamily: 'Lexend Deca',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section "Trier par"
                  _buildSortSection(),
                  const SizedBox(height: 32),
                  // Section "Difficulté"
                  _buildDifficultySection(),
                  const SizedBox(height: 32),
                  // Section "Distance à parcourir"
                  _buildDistanceSection(),
                  const SizedBox(height: 32),
                  // Boutons (Réinitialiser et Appliquer)
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton Réinitialiser
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedSort = SortOption.closest;
                _selectedDifficulties = {};
                _distanceRange = const RangeValues(0, 180);
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Réinitialiser',
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton Appliquer
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onApply(
                _selectedSort,
                _selectedDifficulties,
                _distanceRange,
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiaryColor,
              foregroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Appliquer',
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trier par',
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...SortOption.values.map(
          (option) => CustomRadioButton(
            label: option.label,
            isSelected: _selectedSort == option,
            onTap: () {
              setState(() {
                _selectedSort = option;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulté :',
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedControl<DifficultyFilter>(
          allowMultipleSelection: true,
          options: DifficultyFilter.values
              .map((d) => SegmentedOption(label: d.label, value: d))
              .toList(),
          selectedValue: _selectedDifficulties,
          onSelectionChanged: (value) {
            setState(() {
              _selectedDifficulties = value as Set<DifficultyFilter>;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distance à parcourir :',
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        CustomRangeSlider(
          values: _distanceRange,
          min: 0,
          max: 180,
          divisions: 180,
          unit: 'km',
          onChanged: (RangeValues values) {
            setState(() {
              _distanceRange = values;
            });
          },
        ),
      ],
    );
  }
}
