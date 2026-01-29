import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:turf/turf.dart' as turf;
import 'dart:math';

class StatisticsService {
  DateTime? _startTime;
  DateTime? _endTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  Duration? finalTime;
  double? finalDistance;

  // Démarre le chronomètre
  void startTimer() {
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _pauseStartTime = null;
  }

  // Met en pause le chronomètre
  void pauseTimer() {
    if (_pauseStartTime == null && _startTime != null) {
      _pauseStartTime = DateTime.now();
    }
  }

  // Reprend le chronomètre après une pause
  void resumeTimer() {
    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }
  }

  // Arrête le chronomètre et calcule la durée finale
  void stopTimer() {
    if (_startTime == null) return;

    _endTime = DateTime.now();

    // Si on est en pause au moment du stop, ajouter cette dernière pause
    if (_pauseStartTime != null) {
      _pausedDuration += _endTime!.difference(_pauseStartTime!);
    }

    // Calcul de la durée totale moins les pauses
    finalTime = _endTime!.difference(_startTime!) - _pausedDuration;
  }

  Duration? getFinalTime() {
    return finalTime;
  }

  void setFinalTime() {
    stopTimer();
  }

  void setFinalDistance(double distance) {
    finalDistance = distance;
  }

  double calculateTotalDistance(List<List<gl.Position>> segments) {
    double totalDistance = 0.0;

    for (var segment in segments) {
      if (segment.length < 2) continue;

      for (int i = 0; i < segment.length - 1; i++) {
        final point1 = segment[i];
        final point2 = segment[i + 1];

        final distance2D = _calculateHorizontalDistance(point1, point2);
        final elevationDiff = (point2.altitude - point1.altitude).abs();

        final distance3D = _calculate3DDistance(distance2D, elevationDiff);

        totalDistance += distance3D;
      }
    }

    if (kDebugMode) {
    }
    return (totalDistance / 1000 * 100).roundToDouble() / 100;
  }

  double _calculateHorizontalDistance(gl.Position point1, gl.Position point2) {
    final distance = turf.distance(
      turf.Point(coordinates: turf.Position(point1.longitude, point1.latitude)),
      turf.Point(coordinates: turf.Position(point2.longitude, point2.latitude)),
      turf.Unit.meters,
    );
    return distance.toDouble();
  }

  double _calculate3DDistance(
    double horizontalDistance,
    double verticalDistance,
  ) {
    return sqrt(
      horizontalDistance * horizontalDistance +
          verticalDistance * verticalDistance,
    );
  }

  Map<String, double> calculateElevationGain(List<List<gl.Position>> segments) {
    double positiveGain = 0.0;
    double negativeGain = 0.0;

    for (var segment in segments) {
      if (segment.length < 2) continue;

      for (int i = 0; i < segment.length - 1; i++) {
        final elevationDiff = segment[i + 1].altitude - segment[i].altitude;

        if (elevationDiff > 0) {
          positiveGain += elevationDiff;
        } else {
          negativeGain += elevationDiff.abs();
        }
      }
    }

    return {
      'positive': positiveGain.roundToDouble(),
      'negative': negativeGain.roundToDouble(),
    };
  }

  // Réinitialise le service pour une nouvelle randonnée
  void reset() {
    _startTime = null;
    _endTime = null;
    _pausedDuration = Duration.zero;
    _pauseStartTime = null;
    finalTime = Duration.zero;
    finalDistance = 0.0;
  }
}
