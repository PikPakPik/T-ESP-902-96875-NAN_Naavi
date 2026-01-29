import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

void main() {
  // Create a 120x120 image with RGBA channels for transparency
  final image = img.Image(width: 120, height: 120, numChannels: 4);

  // Fill with transparent background
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Style AllTrails: grosse flèche bleue avec bordure blanche
  // La flèche pointe vers le HAUT (direction 0° = Nord)

  // 1. D'abord dessiner la bordure blanche (légèrement plus grande)
  final borderPoints = [
    img.Point(60, 5), // Top (point)
    img.Point(105, 95), // Bottom right
    img.Point(60, 78), // Middle notch
    img.Point(15, 95), // Bottom left
  ];
  _drawPolygon(image, borderPoints, img.ColorRgba8(255, 255, 255, 255));

  // 2. Dessiner la flèche bleue principale par-dessus
  final mainPoints = [
    img.Point(60, 12), // Top (point)
    img.Point(98, 90), // Bottom right
    img.Point(60, 73), // Middle notch
    img.Point(22, 90), // Bottom left
  ];
  _drawPolygon(
    image,
    mainPoints,
    img.ColorRgba8(66, 133, 244, 255),
  ); // Bleu Google/AllTrails

  // 3. Petit highlight pour effet 3D subtil
  final highlightPoints = [
    img.Point(60, 22),
    img.Point(78, 75),
    img.Point(60, 68),
  ];
  _drawPolygon(image, highlightPoints, img.ColorRgba8(100, 160, 255, 80));

  // Save as PNG
  final pngBytes = img.encodePng(image);
  File('assets/icons/navigation_arrow.png').writeAsBytesSync(pngBytes);
  debugPrint('Navigation arrow created at assets/icons/navigation_arrow.png');
}

void _drawPolygon(img.Image image, List<img.Point> points, img.Color color) {
  // Draw filled polygon
  img.fillPolygon(image, vertices: points, color: color);
}
