import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/di/AuthProvider.dart';
import 'package:naavi/core/di/HttpClientProvider.dart';
import 'package:naavi/core/services/auth/auth_service.dart';
import 'package:naavi/core/services/storage/token_storage_service.dart';
import 'package:naavi/presentation/auth/state/AuthState.dart';

// Mocks
class MockAuthService extends Mock implements AuthService {}

class MockTokenStorageService extends Mock implements TokenStorageService {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('AuthProvider', () {
    late ProviderContainer container;
    late MockAuthService mockAuthService;
    late MockTokenStorageService mockTokenStorageService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockAuthService = MockAuthService();
      mockTokenStorageService = MockTokenStorageService();
      mockHttpClient = MockHttpClient();

      container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(mockTokenStorageService),
          authenticatedHttpClientProvider.overrideWithValue(mockHttpClient),
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('authServiceProvider should provide AuthService', () {
      final authService = container.read(authServiceProvider);

      expect(authService, isA<AuthService>());
    });

    test('authProvider should provide AuthStateNotifier', () {
      final notifier = container.read(authProvider.notifier);

      expect(notifier, isNotNull);
    });

    test('authProvider should start with AuthStateInitial', () {
      final state = container.read(authProvider);

      expect(state, isA<AuthStateInitial>());
    });

    test('authProvider notifier should be mounted', () {
      final notifier = container.read(authProvider.notifier);
      expect(notifier.mounted, isTrue);
    });

    test('authProvider notifier should unmount when disposed', () {
      final testContainer = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(mockTokenStorageService),
          authenticatedHttpClientProvider.overrideWithValue(mockHttpClient),
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
      final notifier = testContainer.read(authProvider.notifier);
      expect(notifier.mounted, isTrue);
      testContainer.dispose();
      expect(notifier.mounted, isFalse);
    });

    test('authServiceProvider should use tokenStorageProvider', () {
      // Create container without override to test real dependency injection
      final realContainer = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(mockTokenStorageService),
          authenticatedHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(realContainer.dispose);

      final authService = realContainer.read(authServiceProvider);
      expect(authService, isA<AuthService>());
      expect(authService.tokenStorage, same(mockTokenStorageService));
    });

    test('authServiceProvider should use authenticatedHttpClientProvider', () {
      final realContainer = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(mockTokenStorageService),
          authenticatedHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(realContainer.dispose);

      final authService = realContainer.read(authServiceProvider);
      expect(authService, isA<AuthService>());
    });
  });
}
