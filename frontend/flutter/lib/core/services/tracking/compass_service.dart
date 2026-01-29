import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/foundation.dart';

class CompassService {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _currentHeading;
  double? _previousHeading;
  final double _headingThreshold;
  final bool _smoothingEnabled;

  // Variables pour le smoothing
  final List<double> _headingBuffer = [];
  static const int _bufferSize = 3; // Moyenne sur 3 valeurs

  void Function(double heading)? onHeadingChanged;

  CompassService({
    this.onHeadingChanged,
    double headingThreshold = 0.5, // Réduit à 0.5° pour plus de fluidité
    bool smoothingEnabled = true,
  }) : _headingThreshold = headingThreshold,
       _smoothingEnabled = smoothingEnabled;

  double? get currentHeading => _currentHeading;

  void startListening() {
    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        _handleHeadingUpdate(event.heading!);
      }
    });
  }

  void _handleHeadingUpdate(double newHeading) {
    // Appliquer le smoothing si activé
    double smoothedHeading = newHeading;
    if (_smoothingEnabled) {
      smoothedHeading = _applySmoothing(newHeading);
    }

    // Vérifier le threshold
    if (_previousHeading != null) {
      if ((smoothedHeading - _previousHeading!).abs() > _headingThreshold) {
        _updateHeading(smoothedHeading);
      }
    } else {
      _updateHeading(smoothedHeading);
    }
  }

  /// Applique un lissage par moyenne mobile pour réduire les variations brusques
  double _applySmoothing(double newHeading) {
    _headingBuffer.add(newHeading);

    // Garder seulement les N dernières valeurs
    if (_headingBuffer.length > _bufferSize) {
      _headingBuffer.removeAt(0);
    }

    // Calculer la moyenne
    if (_headingBuffer.length == 1) {
      return newHeading;
    }

    double sum = 0;
    for (var heading in _headingBuffer) {
      sum += heading;
    }
    return sum / _headingBuffer.length;
  }

  void _updateHeading(double heading) {
    _currentHeading = heading;
    _previousHeading = heading;
    onHeadingChanged?.call(heading);
  }

  Future<double?> getCurrentHeading() async {
    if (_currentHeading != null) {
      return _currentHeading;
    }

    try {
      // Ajouter un timeout court pour ne pas bloquer indéfiniment
      final compassStream = FlutterCompass.events;
      if (compassStream == null) {
        _currentHeading = 0.0;
        return 0.0;
      }

      final heading = await compassStream.first.timeout(
        const Duration(milliseconds: 500),
      );

      _currentHeading = heading.heading ?? 0.0;
      return _currentHeading;
    } on TimeoutException {
      _currentHeading = 0.0;
      return 0.0;
    } catch (e) {
      if (kDebugMode) {}
      // Retourner 0 par défaut plutôt que null
      _currentHeading = 0.0;
      return 0.0;
    }
  }

  /// Force la récupération d'un heading frais en ignorant le cache
  /// Utile pour s'assurer d'avoir une orientation correcte au démarrage
  Future<double> getFreshHeading() async {
    // Réinitialiser le buffer et le cache pour avoir une valeur vraiment fraîche
    _headingBuffer.clear();
    _currentHeading = null;
    _previousHeading = null;

    try {
      final compassStream = FlutterCompass.events;
      if (compassStream == null) {
        return 0.0;
      }

      // Attendre une vraie valeur du compas
      final heading = await compassStream.first.timeout(
        const Duration(milliseconds: 150),
      );

      if (heading.heading != null) {
        _currentHeading = heading.heading;
        _previousHeading = heading.heading;
        _headingBuffer.add(heading.heading!);
        return heading.heading!;
      }
      return 0.0;
    } on TimeoutException {
      // Si timeout, essayer de lire une valeur synchrone
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Attend un heading stable en collectant plusieurs lectures
  /// Retourne une valeur fiable pour le positionnement initial de la caméra
  Future<double> getStableHeading() async {
    _headingBuffer.clear();

    try {
      final compassStream = FlutterCompass.events;
      if (compassStream == null) {
        return 0.0;
      }

      // Collecter 3 lectures rapidement pour avoir une valeur stable
      final readings = <double>[];
      await for (final event
          in compassStream.take(3).timeout(const Duration(milliseconds: 200))) {
        if (event.heading != null) {
          readings.add(event.heading!);
        }
      }

      if (readings.isEmpty) {
        return 0.0;
      }

      // Calculer la moyenne des lectures
      final average = readings.reduce((a, b) => a + b) / readings.length;
      _currentHeading = average;
      _previousHeading = average;
      return average;
    } on TimeoutException {
      // Si timeout, utiliser la valeur actuelle ou 0
      return _currentHeading ?? 0.0;
    } catch (e) {
      return _currentHeading ?? 0.0;
    }
  }

  void stopListening() {
    _compassSub?.cancel();
    _compassSub = null;
  }

  void dispose() {
    stopListening();
  }
}
