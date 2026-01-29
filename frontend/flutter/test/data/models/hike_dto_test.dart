import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/data/models/hike_dto.dart';

void main() {
  group('HikeDto', () {
    test('formattedDuration should format hours and minutes correctly', () {
      final now = DateTime.now();
      final hike = HikeDto(
        id: 1,
        name: 'Test Hike',
        startingPointLatitude: 47.2184,
        startingPointLongitude: -1.5536,
        startingElevation: 10,
        arrivalPointLatitude: 47.2194,
        arrivalPointLongitude: -1.5546,
        arrivalElevation: 20,
        distance: 5000,
        duration: 9000, // 2h 30min
        location: 'Nantes',
        difficulty: HikeDifficulty.medium,
        status: HikeStatus.published,
        seasons: [HikeSeason.spring],
        source: HikeSource.official,
        createdAt: now,
        updatedAt: now,
      );

      expect(hike.formattedDuration, '2h 30min');
    });

    test('formattedDuration should format hours only', () {
      final now = DateTime.now();
      final hike = HikeDto(
        id: 1,
        name: 'Test Hike',
        startingPointLatitude: 47.2184,
        startingPointLongitude: -1.5536,
        startingElevation: 10,
        arrivalPointLatitude: 47.2194,
        arrivalPointLongitude: -1.5546,
        arrivalElevation: 20,
        distance: 5000,
        duration: 3600, // 1h
        location: 'Nantes',
        difficulty: HikeDifficulty.medium,
        status: HikeStatus.published,
        seasons: [HikeSeason.spring],
        source: HikeSource.official,
        createdAt: now,
        updatedAt: now,
      );

      expect(hike.formattedDuration, '1h');
    });

    test('formattedDuration should format minutes only', () {
      final now = DateTime.now();
      final hike = HikeDto(
        id: 1,
        name: 'Test Hike',
        startingPointLatitude: 47.2184,
        startingPointLongitude: -1.5536,
        startingElevation: 10,
        arrivalPointLatitude: 47.2194,
        arrivalPointLongitude: -1.5546,
        arrivalElevation: 20,
        distance: 5000,
        duration: 1800, // 30min
        location: 'Nantes',
        difficulty: HikeDifficulty.medium,
        status: HikeStatus.published,
        seasons: [HikeSeason.spring],
        source: HikeSource.official,
        createdAt: now,
        updatedAt: now,
      );

      expect(hike.formattedDuration, '30min');
    });

    test(
      'formattedDuration should return "?" for zero or negative duration',
      () {
        final now = DateTime.now();
        final hikeZero = HikeDto(
          id: 1,
          name: 'Test Hike',
          startingPointLatitude: 47.2184,
          startingPointLongitude: -1.5536,
          startingElevation: 10,
          arrivalPointLatitude: 47.2194,
          arrivalPointLongitude: -1.5546,
          arrivalElevation: 20,
          distance: 5000,
          duration: 0,
          location: 'Nantes',
          difficulty: HikeDifficulty.medium,
          status: HikeStatus.published,
          seasons: [HikeSeason.spring],
          source: HikeSource.official,
          createdAt: now,
          updatedAt: now,
        );

        expect(hikeZero.formattedDuration, '?');
      },
    );

    test('toJson should serialize all fields correctly', () {
      final now = DateTime.now();
      final hike = HikeDto(
        id: 1,
        name: 'Test Hike',
        startingPointLatitude: 47.2184,
        startingPointLongitude: -1.5536,
        startingElevation: 10,
        arrivalPointLatitude: 47.2194,
        arrivalPointLongitude: -1.5546,
        arrivalElevation: 20,
        wkbGeometry: 'test_wkb',
        distance: 5000,
        duration: 3600,
        location: 'Nantes',
        difficulty: HikeDifficulty.medium,
        status: HikeStatus.published,
        seasons: [HikeSeason.spring, HikeSeason.summer],
        source: HikeSource.official,
        createdAt: now,
        updatedAt: now,
      );

      final json = hike.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test Hike');
      expect(json['difficulty'], 'MEDIUM');
      expect(json['status'], 'PUBLISHED');
      expect(json['source'], 'OFFICIAL');
      expect(json['seasons'], ['SPRING', 'SUMMER']);
    });
  });

  group('HikeDifficulty', () {
    test('fromString should parse difficulty correctly', () {
      expect(HikeDifficulty.fromString('EASY'), HikeDifficulty.easy);
      expect(HikeDifficulty.fromString('MEDIUM'), HikeDifficulty.medium);
      expect(HikeDifficulty.fromString('HARD'), HikeDifficulty.hard);
      expect(HikeDifficulty.fromString('easy'), HikeDifficulty.easy);
      expect(HikeDifficulty.fromString('unknown'), HikeDifficulty.easy);
    });
  });

  group('HikeStatus', () {
    test('fromString should parse status correctly', () {
      expect(HikeStatus.fromString('DRAFT'), HikeStatus.draft);
      expect(HikeStatus.fromString('UNPUBLISHED'), HikeStatus.unpublished);
      expect(HikeStatus.fromString('PUBLISHED'), HikeStatus.published);
      expect(HikeStatus.fromString('DELETED'), HikeStatus.deleted);
      expect(HikeStatus.fromString('unknown'), HikeStatus.published);
    });
  });

  group('HikeSeason', () {
    test('fromString should parse season correctly', () {
      expect(HikeSeason.fromString('SPRING'), HikeSeason.spring);
      expect(HikeSeason.fromString('SUMMER'), HikeSeason.summer);
      expect(HikeSeason.fromString('FALL'), HikeSeason.fall);
      expect(HikeSeason.fromString('WINTER'), HikeSeason.winter);
      expect(HikeSeason.fromString('unknown'), HikeSeason.spring);
    });
  });

  group('HikeSource', () {
    test('fromString should parse source correctly', () {
      expect(HikeSource.fromString('OFFICIAL'), HikeSource.official);
      expect(HikeSource.fromString('COMMUNITY'), HikeSource.community);
      expect(HikeSource.fromString('unknown'), HikeSource.official);
    });
  });

  group('PaginatedHikesResponse', () {
    test('should create PaginatedHikesResponse with all fields', () {
      final now = DateTime.now();
      final hikes = [
        HikeDto(
          id: 1,
          name: 'Hike 1',
          startingPointLatitude: 47.2184,
          startingPointLongitude: -1.5536,
          startingElevation: 10,
          arrivalPointLatitude: 47.2194,
          arrivalPointLongitude: -1.5546,
          arrivalElevation: 20,
          distance: 5000,
          duration: 3600,
          location: 'Nantes',
          difficulty: HikeDifficulty.medium,
          status: HikeStatus.published,
          seasons: [HikeSeason.spring],
          source: HikeSource.official,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final response = PaginatedHikesResponse(
        items: hikes,
        totalItems: 1,
        totalPages: 1,
        currentPage: 1,
        nextPage: 2,
        previousPage: null,
      );

      expect(response.items.length, 1);
      expect(response.totalItems, 1);
      expect(response.totalPages, 1);
      expect(response.currentPage, 1);
      expect(response.nextPage, 2);
      expect(response.previousPage, isNull);
    });

    test('should create PaginatedHikesResponse from JSON', () {
      final now = DateTime.now();
      final json = {
        'items': [
          {
            'id': 1,
            'name': 'Hike 1',
            'startingPointLatitude': 47.2184,
            'startingPointLongitude': -1.5536,
            'startingElevation': 10,
            'arrivalPointLatitude': 47.2194,
            'arrivalPointLongitude': -1.5546,
            'arrivalElevation': 20,
            'distance': 5000,
            'duration': 3600,
            'location': 'Nantes',
            'difficulty': 'MEDIUM',
            'status': 'PUBLISHED',
            'seasons': ['SPRING'],
            'source': 'OFFICIAL',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ],
        'totalItems': 1,
        'totalPages': 1,
        'currentPage': 1,
        'nextPage': 2,
        'previousPage': null,
      };

      final response = PaginatedHikesResponse.fromJson(json);

      expect(response.items.length, 1);
      expect(response.totalItems, 1);
      expect(response.totalPages, 1);
      expect(response.currentPage, 1);
      expect(response.nextPage, 2);
      expect(response.previousPage, isNull);
    });
  });
}
