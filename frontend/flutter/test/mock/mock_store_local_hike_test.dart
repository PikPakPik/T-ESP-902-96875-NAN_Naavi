import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/mock/MockStoreLocalHike.dart';
import 'package:naavi/data/models/HikeModel.dart';

void main() {
  group('MockLocalStorageHikeDataSource', () {
    late MockLocalStorageHikeDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockLocalStorageHikeDataSource();
    });

    test('mockHikeModel has valid start point', () {
      final model = mockDataSource.mockHikeModel;
      expect(model.startPoint, isNotNull);
      expect(model.startPoint.latitude, equals(48.8566));
      expect(model.startPoint.longitude, equals(2.3522));
    });

    test('mockHikeModel has two paths', () {
      final model = mockDataSource.mockHikeModel;
      expect(model.paths, hasLength(2));
    });

    test('mockHikeModel first path has 4 points', () {
      final model = mockDataSource.mockHikeModel;
      expect(model.paths[0], hasLength(4));
    });

    test('mockHikeModel second path has 4 points', () {
      final model = mockDataSource.mockHikeModel;
      expect(model.paths[1], hasLength(4));
    });

    test('mockHikeModel first path starts at Paris centre', () {
      final model = mockDataSource.mockHikeModel;
      final firstPoint = model.paths[0][0];
      expect(firstPoint.latitude, equals(48.8566));
      expect(firstPoint.longitude, equals(2.3522));
    });

    test('mockHikeModel second path ends at start point (loop)', () {
      final model = mockDataSource.mockHikeModel;
      final lastPoint = model.paths[1].last;
      expect(lastPoint.latitude, equals(48.8566));
      expect(lastPoint.longitude, equals(2.3522));
    });

    test('getHike returns mockHikeModel', () async {
      final result = await mockDataSource.getHike();
      expect(result, isNotNull);
      expect(result, equals(mockDataSource.mockHikeModel));
    });

    test('getHike returns HikeModel type', () async {
      final result = await mockDataSource.getHike();
      expect(result, isA<HikeModel>());
    });

    test('mockHikeModel paths form continuous route', () {
      final model = mockDataSource.mockHikeModel;
      // First path ends where second path begins
      final firstPathEnd = model.paths[0].last;
      final secondPathStart = model.paths[1].first;
      expect(firstPathEnd.latitude, equals(secondPathStart.latitude));
      expect(firstPathEnd.longitude, equals(secondPathStart.longitude));
    });

    test('all path points have valid coordinates', () {
      final model = mockDataSource.mockHikeModel;
      for (final path in model.paths) {
        for (final point in path) {
          expect(point.latitude, greaterThanOrEqualTo(-90));
          expect(point.latitude, lessThanOrEqualTo(90));
          expect(point.longitude, greaterThanOrEqualTo(-180));
          expect(point.longitude, lessThanOrEqualTo(180));
        }
      }
    });
  });
}
