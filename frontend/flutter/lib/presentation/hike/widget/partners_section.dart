import 'dart:async';
import 'package:flutter/material.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/data/models/partner_dto.dart';

/// Section des partenaires avec carrousel
class PartnersSection extends StatefulWidget {
  final List<PartnerDto> partners;

  const PartnersSection({super.key, required this.partners});

  @override
  State<PartnersSection> createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<PartnersSection> {
  final PageController _partnersPageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPartnerIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _partnersPageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.partners.isEmpty) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int nextIndex = (_currentPartnerIndex + 1) % widget.partners.length;
      _partnersPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPartnerPageChanged(int index) {
    setState(() {
      _currentPartnerIndex = index;
    });
    // Réinitialiser le timer après un scroll manuel
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.partners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Partenaire
        const Text(
          'Partenaire',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lexend Deca',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        // Message informatif avec icône
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'N\'oubliez pas de scanner le QR disponible à l\'entrée de chacun de nos partenaires !',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: 'Lexend Deca',
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showPartnerInfoBottomSheet(context),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Carrousel de partenaires
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _partnersPageController,
            onPageChanged: _onPartnerPageChanged,
            itemCount: widget.partners.length,
            itemBuilder: (context, index) {
              final partner = widget.partners[index];
              return _buildPartnerCard(partner);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicateurs de carrousel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.partners.length,
            (index) => Container(
              width: 24,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == _currentPartnerIndex
                    ? AppColors.greenMedium
                    : Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerCard(PartnerDto partner) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne avec logo et infos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo (carré bleu avec texte)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: partner.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            partner.logoUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          partner.logoText ??
                              partner.name.substring(0, 4).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Lexend Deca',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Colonne droite : Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nom
                    Text(
                      partner.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lexend Deca',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Type de partenaire
                    Text(
                      partner.category,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Lexend Deca',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Adresse
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.greenMedium,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Ouvrir la carte avec l'adresse
                            },
                            child: Text(
                              partner.address,
                              style: TextStyle(
                                color: AppColors.greenMedium,
                                fontFamily: 'Lexend Deca',
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Avis en dessous, sur toute la largeur
          if (partner.testimonial != null) ...[
            const SizedBox(height: 12),
            Text(
              '"${partner.testimonial!}"',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Lexend Deca',
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.left,
            ),
          ],
          const SizedBox(height: 12),
          // Bouton "Voir les avis"
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                // TODO: Naviguer vers la page des avis du partenaire
              },
              child: Text(
                'Voir les avis',
                style: TextStyle(
                  color: AppColors.greenMedium,
                  fontFamily: 'Lexend Deca',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPartnerInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée de drag
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // En-tête avec icône et bouton fermer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icône info
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Bouton fermer
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
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
              // Contenu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations sur les partenaires',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lexend Deca',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras quis risus non eros venenatis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras quis risus non eros venenatis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras quis risus non eros venenatis.',
                      style: TextStyle(
                        color: AppColors.greenMedium,
                        fontFamily: 'Lexend Deca',
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
