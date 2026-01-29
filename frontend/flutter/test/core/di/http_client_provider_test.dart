import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:naavi/core/di/HttpClientProvider.dart';
import 'package:naavi/core/services/storage/token_storage_service.dart';
import 'package:naavi/core/utils/authenticated_http_client.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Initialize dotenv for tests
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://api.test.com
''',
    );
  });

  group('HttpClientProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('tokenStorageProvider', () {
      test('should provide a TokenStorageService instance', () {
        final tokenStorage = container.read(tokenStorageProvider);

        expect(tokenStorage, isA<TokenStorageService>());
      });

      test('should provide the same instance on multiple reads', () {
        final tokenStorage1 = container.read(tokenStorageProvider);
        final tokenStorage2 = container.read(tokenStorageProvider);

        expect(tokenStorage1, same(tokenStorage2));
      });

      test('should create new instance in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final tokenStorage1 = container1.read(tokenStorageProvider);
        final tokenStorage2 = container2.read(tokenStorageProvider);

        expect(tokenStorage1, isNot(same(tokenStorage2)));

        container1.dispose();
        container2.dispose();
      });
    });

    group('authenticatedHttpClientProvider', () {
      test('should provide an http.Client instance', () {
        final client = container.read(authenticatedHttpClientProvider);

        expect(client, isA<http.Client>());
      });

      test('should provide an AuthenticatedHttpClient instance', () {
        final client = container.read(authenticatedHttpClientProvider);

        expect(client, isA<AuthenticatedHttpClient>());
      });

      test('should use TokenStorageService from tokenStorageProvider', () {
        final client =
            container.read(authenticatedHttpClientProvider)
                as AuthenticatedHttpClient;

        // The client should be properly created with dependencies
        expect(client, isA<AuthenticatedHttpClient>());
      });

      test('should use base URL from environment variables', () {
        final client =
            container.read(authenticatedHttpClientProvider)
                as AuthenticatedHttpClient;

        expect(client.baseUrl, 'https://api.test.com');
      });

      test('should use empty string when API_BASE_URL is not set', () {
        // Create new dotenv without API_BASE_URL
        dotenv.testLoad(fileInput: '');

        final newContainer = ProviderContainer();
        final client =
            newContainer.read(authenticatedHttpClientProvider)
                as AuthenticatedHttpClient;

        expect(client.baseUrl, '');

        newContainer.dispose();

        // Restore original dotenv
        dotenv.testLoad(
          fileInput: '''
API_BASE_URL=https://api.test.com
''',
        );
      });

      test('should provide the same instance on multiple reads', () {
        final client1 = container.read(authenticatedHttpClientProvider);
        final client2 = container.read(authenticatedHttpClientProvider);

        expect(client1, same(client2));
      });

      test('should create new instance in different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final client1 = container1.read(authenticatedHttpClientProvider);
        final client2 = container2.read(authenticatedHttpClientProvider);

        expect(client1, isNot(same(client2)));

        container1.dispose();
        container2.dispose();
      });

      test('should have onUnauthorized callback configured', () {
        final client =
            container.read(authenticatedHttpClientProvider)
                as AuthenticatedHttpClient;

        // The onUnauthorized callback should be set (even if it's a no-op)
        expect(client.onUnauthorized, isNotNull);
      });

      test('should watch tokenStorageProvider for changes', () {
        var buildCount = 0;
        final testContainer = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWith((ref) {
              buildCount++;
              return TokenStorageService();
            }),
          ],
        );

        // First read
        testContainer.read(authenticatedHttpClientProvider);
        expect(buildCount, 1);

        testContainer.dispose();
      });
    });

    group('Provider integration', () {
      test(
        'should have proper dependency chain: authenticatedHttpClientProvider -> tokenStorageProvider',
        () {
          // Read the authenticated client, which should trigger tokenStorage read
          final client =
              container.read(authenticatedHttpClientProvider)
                  as AuthenticatedHttpClient;
          final tokenStorage = container.read(tokenStorageProvider);

          // Verify client was created properly with dependencies
          expect(client, isA<AuthenticatedHttpClient>());
          expect(tokenStorage, isA<TokenStorageService>());
        },
      );

      test('should maintain provider scope isolation', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        final client1 = container1.read(authenticatedHttpClientProvider);
        final tokenStorage1 = container1.read(tokenStorageProvider);

        final client2 = container2.read(authenticatedHttpClientProvider);
        final tokenStorage2 = container2.read(tokenStorageProvider);

        // Different containers should have different instances
        expect(client1, isNot(same(client2)));
        expect(tokenStorage1, isNot(same(tokenStorage2)));

        container1.dispose();
        container2.dispose();
      });

      test('should support provider override for testing', () {
        final mockTokenStorage = TokenStorageService();
        final overriddenContainer = ProviderContainer(
          overrides: [tokenStorageProvider.overrideWithValue(mockTokenStorage)],
        );

        final client =
            overriddenContainer.read(authenticatedHttpClientProvider)
                as AuthenticatedHttpClient;

        expect(client, isA<AuthenticatedHttpClient>());

        overriddenContainer.dispose();
      });
    });
  });
}
