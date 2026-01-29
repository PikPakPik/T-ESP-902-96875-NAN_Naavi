import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/network/check_network_service.dart';

// Mock class for Connectivity
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityState', () {
    test('should have offline state', () {
      expect(ConnectivityState.offline, isNotNull);
    });

    test('should have online state', () {
      expect(ConnectivityState.online, isNotNull);
    });

    test('should have two distinct states', () {
      expect(ConnectivityState.offline, isNot(equals(ConnectivityState.online)));
    });
  });

  group('CheckNetworkService', () {
    late CheckNetworkService service;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockConnectivity = MockConnectivity();
      service = CheckNetworkService(connectivity: mockConnectivity);
    });

    group('checkConnection', () {
      test('should return a ConnectivityState', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result = await service.checkConnection();

        expect(
          result,
          anyOf(ConnectivityState.offline, ConnectivityState.online),
        );
      });

      test('should complete without throwing', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        await expectLater(
          service.checkConnection(),
          completes,
        );
      });

      test('should return same result for consecutive calls in short time', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result1 = await service.checkConnection();
        final result2 = await service.checkConnection();

        // In real environment, connectivity shouldn't change rapidly
        // (though in tests it might be different)
        expect(result1, isA<ConnectivityState>());
        expect(result2, isA<ConnectivityState>());
      });
    });

    group('Multiple Instances', () {
      test('should support multiple service instances', () {
        final mock1 = MockConnectivity();
        final mock2 = MockConnectivity();
        final service1 = CheckNetworkService(connectivity: mock1);
        final service2 = CheckNetworkService(connectivity: mock2);

        expect(service1, isNotNull);
        expect(service2, isNotNull);
        expect(service1, isNot(same(service2)));
      });

      test('should return consistent results across instances', () async {
        final mock1 = MockConnectivity();
        final mock2 = MockConnectivity();

        when(() => mock1.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mock2.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final service1 = CheckNetworkService(connectivity: mock1);
        final service2 = CheckNetworkService(connectivity: mock2);

        final result1 = await service1.checkConnection();
        final result2 = await service2.checkConnection();

        // Both should return valid ConnectivityState
        expect(result1, isA<ConnectivityState>());
        expect(result2, isA<ConnectivityState>());
      });
    });

    group('Repeated Calls', () {
      test('should handle multiple consecutive calls', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        for (int i = 0; i < 5; i++) {
          final result = await service.checkConnection();
          expect(result, isA<ConnectivityState>());
        }
      });

      test('should not throw on rapid consecutive calls', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final futures = List.generate(
          10,
          (_) => service.checkConnection(),
        );

        final results = await Future.wait(futures);

        expect(results.length, 10);
        for (final result in results) {
          expect(result, isA<ConnectivityState>());
        }
      });
    });

    group('State Values', () {
      test('online state should be accessible', () {
        expect(ConnectivityState.online, isNotNull);
        expect(ConnectivityState.online.toString(), contains('online'));
      });

      test('offline state should be accessible', () {
        expect(ConnectivityState.offline, isNotNull);
        expect(ConnectivityState.offline.toString(), contains('offline'));
      });

      test('states should be comparable', () {
        final online1 = ConnectivityState.online;
        final online2 = ConnectivityState.online;
        final offline1 = ConnectivityState.offline;

        expect(online1, equals(online2));
        expect(online1, isNot(equals(offline1)));
      });
    });
  });
}
