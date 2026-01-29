import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/map/state/HomeMapState.dart';

void main() {
  group('HomeMapState enum', () {
    test('should have all expected values', () {
      expect(HomeMapState.values.length, equals(5));
      expect(HomeMapState.values, contains(HomeMapState.explore));
      expect(HomeMapState.values, contains(HomeMapState.organise));
      expect(HomeMapState.values, contains(HomeMapState.improvise));
      expect(HomeMapState.values, contains(HomeMapState.resume));
      expect(HomeMapState.values, contains(HomeMapState.trackingExploration));
    });

    test('explore should be first value', () {
      expect(HomeMapState.values[0], equals(HomeMapState.explore));
    });

    test('organise should be second value', () {
      expect(HomeMapState.values[1], equals(HomeMapState.organise));
    });

    test('improvise should be third value', () {
      expect(HomeMapState.values[2], equals(HomeMapState.improvise));
    });

    test('resume should be fourth value', () {
      expect(HomeMapState.values[3], equals(HomeMapState.resume));
    });

    test('trackingExploration should be fifth value', () {
      expect(HomeMapState.values[4], equals(HomeMapState.trackingExploration));
    });

    test('should have correct name for explore', () {
      expect(HomeMapState.explore.name, equals('explore'));
    });

    test('should have correct name for organise', () {
      expect(HomeMapState.organise.name, equals('organise'));
    });

    test('should have correct name for improvise', () {
      expect(HomeMapState.improvise.name, equals('improvise'));
    });

    test('should have correct name for resume', () {
      expect(HomeMapState.resume.name, equals('resume'));
    });

    test('should have correct name for trackingExploration', () {
      expect(
        HomeMapState.trackingExploration.name,
        equals('trackingExploration'),
      );
    });

    test('should be comparable by index', () {
      expect(HomeMapState.explore.index, lessThan(HomeMapState.organise.index));
      expect(
        HomeMapState.organise.index,
        lessThan(HomeMapState.improvise.index),
      );
    });
  });
}
