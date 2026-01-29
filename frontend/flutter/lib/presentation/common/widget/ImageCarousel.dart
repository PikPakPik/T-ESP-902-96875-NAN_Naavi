import 'package:flutter/material.dart';

/// Un carrousel d'images simple qui permet de naviguer entre plusieurs images
/// via un geste de swipe horizontal.
class ImageCarousel extends StatefulWidget {
  /// Liste des URLs des images à afficher
  final List<String> imageUrls;

  /// Hauteur du carrousel (par défaut 250)
  final double height;

  /// Afficher les indicateurs de page (points en bas)
  final bool showIndicators;

  /// Couleur des indicateurs actifs
  final Color activeIndicatorColor;

  /// Couleur des indicateurs inactifs
  final Color inactiveIndicatorColor;

  /// BoxFit pour les images
  final BoxFit fit;

  /// BorderRadius pour les images
  final BorderRadius? borderRadius;

  const ImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 250,
    this.showIndicators = true,
    this.activeIndicatorColor = Colors.white,
    this.inactiveIndicatorColor = Colors.white54,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Utilise la largeur de l'écran si les contraintes sont infinies
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        return SizedBox(
          height: widget.height,
          width: width,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildImage(widget.imageUrls[index], width);
                },
              ),
              if (widget.showIndicators && widget.imageUrls.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: _buildIndicators(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String url, double width) {
    Widget image = Image.network(
      url,
      fit: widget.fit,
      width: width,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
      },
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.imageUrls.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 10 : 8,
          height: _currentPage == index ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? widget.activeIndicatorColor
                : widget.inactiveIndicatorColor,
          ),
        ),
      ),
    );
  }
}
