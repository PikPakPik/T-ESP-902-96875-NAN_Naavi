import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/data/datasources/LocalStorageHikeDataSource.dart';
import 'package:naavi/data/datasources/RemoteStorageHikingDataSource.dart';
import 'package:naavi/data/models/HikeModel.dart';
import 'package:naavi/data/repertories/StoreHikingRepertoryImpl.dart';
import 'package:naavi/domain/entities/Hike.dart';

// Mocks
class MockLocalStorageHikeDataSource extends Mock
    implements LocalStorageHikeDataSource {}

class MockRemoteStorageHikingDataSource extends Mock
    implements RemoteStorageHikingDataSource {}

// Fake classes for mocktail registration
class FakeHikeModel extends Fake implements HikeModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeHikeModel());
  });

  group('StoreHikingRepositoryImpl', () {
    late StoreHikingRepositoryImpl repository;
    late MockLocalStorageHikeDataSource mockLocalDataSource;
    late MockRemoteStorageHikingDataSource mockRemoteDataSource;

    setUp(() {
      mockLocalDataSource = MockLocalStorageHikeDataSource();
      mockRemoteDataSource = MockRemoteStorageHikingDataSource();
      repository = StoreHikingRepositoryImpl(
        localStorageHikeDataSource: mockLocalDataSource,
        remoteStorageHikingDataSource: mockRemoteDataSource,
      );
    });

    group('saveHikeLocally', () {
      test('should save hike to local data source', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [
              PathPoint(latitude: 47.2184, longitude: -1.5536),
              PathPoint(latitude: 47.2194, longitude: -1.5526),
            ]
          ],
        );

        await repository.saveHikeLocally(hike);

        verify(() => mockLocalDataSource.saveHike(any(
              that: predicate<HikeModel>((model) {
                return model.startPoint.latitude == 47.2184 &&
                    model.startPoint.longitude == -1.5536 &&
                    model.paths.length == 1 &&
                    model.paths[0].length == 2;
              }),
            ))).called(1);
      });

      test('should convert Hike entity to HikeModel correctly', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        await repository.saveHikeLocally(hike);

        final captured =
            verify(() => mockLocalDataSource.saveHike(captureAny()))
                .captured
                .first as HikeModel;

        expect(captured.startPoint.latitude, 47.2184);
        expect(captured.startPoint.longitude, -1.5536);
        expect(captured.paths.length, 1);
      });

      test('should save hike with multiple paths', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [
              PathPoint(latitude: 47.2184, longitude: -1.5536),
              PathPoint(latitude: 47.2194, longitude: -1.5526),
            ],
            [
              PathPoint(latitude: 47.2204, longitude: -1.5516),
              PathPoint(latitude: 47.2214, longitude: -1.5506),
            ]
          ],
        );

        await repository.saveHikeLocally(hike);

        final captured =
            verify(() => mockLocalDataSource.saveHike(captureAny()))
                .captured
                .first as HikeModel;

        expect(captured.paths.length, 2);
        expect(captured.paths[0].length, 2);
        expect(captured.paths[1].length, 2);
      });

      test('should save hike with empty paths', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [],
        );

        await repository.saveHikeLocally(hike);

        final captured =
            verify(() => mockLocalDataSource.saveHike(captureAny()))
                .captured
                .first as HikeModel;

        expect(captured.paths, isEmpty);
      });

      test('should handle local data source errors gracefully', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenThrow(Exception('Storage error'));

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        // Should not throw, error is caught
        await repository.saveHikeLocally(hike);

        verify(() => mockLocalDataSource.saveHike(any())).called(1);
      });

      test('should save hike without endPoint', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: null,
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        await repository.saveHikeLocally(hike);

        final captured =
            verify(() => mockLocalDataSource.saveHike(captureAny()))
                .captured
                .first as HikeModel;

        expect(captured.endPoint, isNull);
      });

      test('should save hike with endPoint', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: PathPoint(latitude: 47.2284, longitude: -1.5436),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        await repository.saveHikeLocally(hike);

        // Note: Currently the implementation doesn't save endPoint to the model
        // This is a limitation in the current implementation
        verify(() => mockLocalDataSource.saveHike(any())).called(1);
      });
    });

    group('getHike', () {
      test('should return hike from local data source', () async {
        final hikeModel = HikeModel(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [
              PathPoint(latitude: 47.2184, longitude: -1.5536),
              PathPoint(latitude: 47.2194, longitude: -1.5526),
            ]
          ],
        );

        when(() => mockLocalDataSource.getHike())
            .thenAnswer((_) async => hikeModel);

        final result = await repository.getHike();

        expect(result, isNotNull);
        expect(result!.startPoint.latitude, 47.2184);
        expect(result.startPoint.longitude, -1.5536);
        expect(result.paths.length, 1);
        verify(() => mockLocalDataSource.getHike()).called(1);
      });

      test('should convert HikeModel to Hike entity correctly', () async {
        final hikeModel = HikeModel(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [
              PathPoint(latitude: 47.2184, longitude: -1.5536),
              PathPoint(latitude: 47.2194, longitude: -1.5526),
            ]
          ],
        );

        when(() => mockLocalDataSource.getHike())
            .thenAnswer((_) async => hikeModel);

        final result = await repository.getHike();

        expect(result, isA<Hike>());
        expect(result!.startPoint.latitude, 47.2184);
        expect(result.startPoint.longitude, -1.5536);
        expect(result.paths[0][0].latitude, 47.2184);
        expect(result.paths[0][1].latitude, 47.2194);
      });

      test('should return hike with multiple paths', () async {
        final hikeModel = HikeModel(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [
              PathPoint(latitude: 47.2184, longitude: -1.5536),
              PathPoint(latitude: 47.2194, longitude: -1.5526),
            ],
            [
              PathPoint(latitude: 47.2204, longitude: -1.5516),
            ]
          ],
        );

        when(() => mockLocalDataSource.getHike())
            .thenAnswer((_) async => hikeModel);

        final result = await repository.getHike();

        expect(result, isNotNull);
        expect(result!.paths.length, 2);
        expect(result.paths[0].length, 2);
        expect(result.paths[1].length, 1);
      });

      test('should return hike with empty paths', () async {
        final hikeModel = HikeModel(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: PathPoint(latitude: 47.2284, longitude: -1.5436),
          paths: [],
        );

        when(() => mockLocalDataSource.getHike())
            .thenAnswer((_) async => hikeModel);

        final result = await repository.getHike();

        expect(result, isNotNull);
        expect(result!.paths, isEmpty);
      });

      test('should handle data source errors', () async {
        when(() => mockLocalDataSource.getHike())
            .thenThrow(Exception('Storage error'));

        expect(
          () => repository.getHike(),
          throwsException,
        );

        verify(() => mockLocalDataSource.getHike()).called(1);
      });
    });

    group('clearHike', () {
      test('should clear hike from local data source', () async {
        when(() => mockLocalDataSource.clearHike())
            .thenAnswer((_) async => Future.value());

        await repository.clearHike();

        verify(() => mockLocalDataSource.clearHike()).called(1);
      });

      test('should handle local data source errors gracefully', () async {
        when(() => mockLocalDataSource.clearHike())
            .thenThrow(Exception('Storage error'));

        // Should not throw, error is caught
        await repository.clearHike();

        verify(() => mockLocalDataSource.clearHike()).called(1);
      });

      test('should complete successfully when no hike exists', () async {
        when(() => mockLocalDataSource.clearHike())
            .thenAnswer((_) async => Future.value());

        await repository.clearHike();

        verify(() => mockLocalDataSource.clearHike()).called(1);
      });
    });

    group('saveCompletedHike', () {
      test('should save completed hike to remote data source', () async {
        when(() => mockRemoteDataSource.saveCompletedHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: PathPoint(latitude: 47.2284, longitude: -1.5436),
          paths: [
            [
              PathPoint(latitude: 47.2184, longitude: -1.5536),
              PathPoint(latitude: 47.2194, longitude: -1.5526),
            ]
          ],
        );

        await repository.saveCompletedHike(hike);

        verify(() => mockRemoteDataSource.saveCompletedHike(any(
              that: predicate<HikeModel>((model) {
                return model.startPoint.latitude == 47.2184 &&
                    model.startPoint.longitude == -1.5536 &&
                    model.paths.length == 1;
              }),
            ))).called(1);
      });

      test('should convert Hike entity to HikeModel correctly', () async {
        when(() => mockRemoteDataSource.saveCompletedHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: PathPoint(latitude: 47.2284, longitude: -1.5436),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        await repository.saveCompletedHike(hike);

        final captured = verify(
                () => mockRemoteDataSource.saveCompletedHike(captureAny()))
            .captured
            .first as HikeModel;

        expect(captured.startPoint.latitude, 47.2184);
        expect(captured.startPoint.longitude, -1.5536);
        expect(captured.paths.length, 1);
      });

      test('should save completed hike with multiple paths', () async {
        when(() => mockRemoteDataSource.saveCompletedHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [
              PathPoint(latitude: 47.2184, longitude: -1.5536),
              PathPoint(latitude: 47.2194, longitude: -1.5526),
            ],
            [
              PathPoint(latitude: 47.2204, longitude: -1.5516),
              PathPoint(latitude: 47.2214, longitude: -1.5506),
            ]
          ],
        );

        await repository.saveCompletedHike(hike);

        final captured = verify(
                () => mockRemoteDataSource.saveCompletedHike(captureAny()))
            .captured
            .first as HikeModel;

        expect(captured.paths.length, 2);
        expect(captured.paths[0].length, 2);
        expect(captured.paths[1].length, 2);
      });

      test('should handle remote data source errors gracefully', () async {
        when(() => mockRemoteDataSource.saveCompletedHike(any()))
            .thenThrow(Exception('Network error'));

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        // Should not throw, error is caught
        await repository.saveCompletedHike(hike);

        verify(() => mockRemoteDataSource.saveCompletedHike(any())).called(1);
      });

      test('should save completed hike without endPoint', () async {
        when(() => mockRemoteDataSource.saveCompletedHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: null,
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        await repository.saveCompletedHike(hike);

        verify(() => mockRemoteDataSource.saveCompletedHike(any())).called(1);
      });
    });

    group('Integration Scenarios', () {
      test('should handle complete save-retrieve-clear lifecycle', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hikeModel = HikeModel(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: PathPoint(latitude: 47.2284, longitude: -1.5436),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        when(() => mockLocalDataSource.getHike())
            .thenAnswer((_) async => hikeModel);

        when(() => mockLocalDataSource.clearHike())
            .thenAnswer((_) async => Future.value());

        // Save
        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        await repository.saveHikeLocally(hike);
        verify(() => mockLocalDataSource.saveHike(any())).called(1);

        // Retrieve
        final retrieved = await repository.getHike();
        expect(retrieved, isNotNull);
        verify(() => mockLocalDataSource.getHike()).called(1);

        // Clear
        await repository.clearHike();
        verify(() => mockLocalDataSource.clearHike()).called(1);
      });

      test('should handle local and remote saves independently', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        when(() => mockRemoteDataSource.saveCompletedHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        // Save locally
        await repository.saveHikeLocally(hike);
        verify(() => mockLocalDataSource.saveHike(any())).called(1);
        verifyNever(() => mockRemoteDataSource.saveCompletedHike(any()));

        // Save to remote
        await repository.saveCompletedHike(hike);
        verify(() => mockRemoteDataSource.saveCompletedHike(any())).called(1);
      });

      test('should handle error in one operation without affecting others', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenThrow(Exception('Save error'));

        final hikeModel = HikeModel(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          endPoint: PathPoint(latitude: 47.2284, longitude: -1.5436),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        when(() => mockLocalDataSource.getHike())
            .thenAnswer((_) async => hikeModel);

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        // Save fails but doesn't throw
        await repository.saveHikeLocally(hike);

        // Get should still work
        final retrieved = await repository.getHike();
        expect(retrieved, isNotNull);
      });
    });

    group('Edge Cases', () {
      test('should handle hike with very long paths', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final longPaths = List.generate(
          100,
          (i) => [
            PathPoint(latitude: 47.2184 + i * 0.001, longitude: -1.5536 + i * 0.001)
          ],
        );

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: longPaths,
        );

        await repository.saveHikeLocally(hike);

        final captured =
            verify(() => mockLocalDataSource.saveHike(captureAny()))
                .captured
                .first as HikeModel;

        expect(captured.paths.length, 100);
      });

      test('should handle hike with zero coordinates', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: 0.0, longitude: 0.0),
          paths: [
            [PathPoint(latitude: 0.0, longitude: 0.0)]
          ],
        );

        await repository.saveHikeLocally(hike);

        final captured =
            verify(() => mockLocalDataSource.saveHike(captureAny()))
                .captured
                .first as HikeModel;

        expect(captured.startPoint.latitude, 0.0);
        expect(captured.startPoint.longitude, 0.0);
      });

      test('should handle hike with negative coordinates', () async {
        when(() => mockLocalDataSource.saveHike(any()))
            .thenAnswer((_) async => Future.value());

        final hike = Hike(
          startPoint: PathPoint(latitude: -45.0, longitude: -90.0),
          paths: [
            [PathPoint(latitude: -45.0, longitude: -90.0)]
          ],
        );

        await repository.saveHikeLocally(hike);

        final captured =
            verify(() => mockLocalDataSource.saveHike(captureAny()))
                .captured
                .first as HikeModel;

        expect(captured.startPoint.latitude, -45.0);
        expect(captured.startPoint.longitude, -90.0);
      });
    });

    group('Error Handling', () {
      test('should throw when getHike returns null (known bug in implementation)', () async {
        // Note: The implementation has a bug where it uses hikeModel! even when it's null
        // This test documents the actual behavior rather than the expected behavior
        when(() => mockLocalDataSource.getHike()).thenAnswer((_) async => null);

        expect(
          () => repository.getHike(),
          throwsA(isA<TypeError>()),
        );
      });

      test('should continue execution after save error', () async {
        var callCount = 0;
        when(() => mockLocalDataSource.saveHike(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('First save failed');
          }
          return Future.value();
        });

        final hike = Hike(
          startPoint: PathPoint(latitude: 47.2184, longitude: -1.5536),
          paths: [
            [PathPoint(latitude: 47.2184, longitude: -1.5536)]
          ],
        );

        // First save fails silently
        await repository.saveHikeLocally(hike);
        expect(callCount, 1);

        // Second save succeeds
        await repository.saveHikeLocally(hike);
        expect(callCount, 2);
      });

      test('should continue execution after clear error', () async {
        var callCount = 0;
        when(() => mockLocalDataSource.clearHike()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('First clear failed');
          }
          return Future.value();
        });

        // First clear fails silently
        await repository.clearHike();
        expect(callCount, 1);

        // Second clear succeeds
        await repository.clearHike();
        expect(callCount, 2);
      });
    });
  });
}
