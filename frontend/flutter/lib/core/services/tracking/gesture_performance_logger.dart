import 'package:flutter/foundation.dart';

/// Service pour logger les performances des gestes en temps réel
class GesturePerformanceLogger {
  static DateTime? _lastGestureTime;
  static final List<int> _frameTimes = [];

  /// Log le début d'un geste
  static void logGestureStart(String gestureType) {
    if (!kDebugMode) return;

    final now = DateTime.now();
    _lastGestureTime = now;
  }

  /// Log une frame pendant un geste
  static void logFrame() {
    if (!kDebugMode) return;

    final now = DateTime.now();
    if (_lastGestureTime != null) {
      final frameTime = now.difference(_lastGestureTime!).inMilliseconds;
      _frameTimes.add(frameTime);
    }
    _lastGestureTime = now;
  }

  /// Log les statistiques globales
  static void logStats() {
    if (!kDebugMode) return;

    if (_frameTimes.isEmpty) return;
  }

  /// Reset les stats
  static void reset() {
    _frameTimes.clear();
    _lastGestureTime = null;
  }
}
