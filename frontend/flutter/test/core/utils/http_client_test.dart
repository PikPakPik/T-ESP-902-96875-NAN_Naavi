import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:naavi/core/utils/http_client.dart';

void main() {
  group('CustomHttpClient', () {
    setUp(() {
      // Reset the client before each test
      CustomHttpClient.close();
    });

    tearDown(() {
      // Clean up after each test
      CustomHttpClient.close();
    });

    group('client getter', () {
      test('should return a non-null client', () {
        final client = CustomHttpClient.client;

        expect(client, isNotNull);
        expect(client, isA<http.Client>());
      });

      test('should return the same client instance on multiple calls (singleton)', () {
        final client1 = CustomHttpClient.client;
        final client2 = CustomHttpClient.client;

        expect(identical(client1, client2), true);
      });

      test('should create appropriate client based on debug mode', () {
        // In test environment, kDebugMode is typically true
        final client = CustomHttpClient.client;

        expect(client, isNotNull);
        // The client should be created successfully
        expect(client, isA<http.Client>());
      });
    });

    group('close', () {
      test('should close the client', () {
        // Get client to initialize it
        final client = CustomHttpClient.client;
        expect(client, isNotNull);

        // Close should not throw
        expect(() => CustomHttpClient.close(), returnsNormally);
      });

      test('should allow getting a new client after close', () {
        final client1 = CustomHttpClient.client;
        expect(client1, isNotNull);

        CustomHttpClient.close();

        final client2 = CustomHttpClient.client;
        expect(client2, isNotNull);
        // Should be a new instance after close
        expect(identical(client1, client2), false);
      });

      test('should handle multiple close calls safely', () {
        CustomHttpClient.close();
        expect(() => CustomHttpClient.close(), returnsNormally);
        expect(() => CustomHttpClient.close(), returnsNormally);
      });
    });

    group('behavior in different modes', () {
      test('should handle debug mode appropriately', () {
        // This test verifies the client works in the current mode
        final client = CustomHttpClient.client;

        expect(client, isNotNull);
        expect(client, isA<http.Client>());

        // Verify client can be closed without errors
        expect(() => client.close(), returnsNormally);
      });

      test('should create functional client that can be used for requests', () {
        final client = CustomHttpClient.client;

        // Verify the client has the expected methods
        expect(client.get, isA<Function>());
        expect(client.post, isA<Function>());
        expect(client.put, isA<Function>());
        expect(client.delete, isA<Function>());
        expect(client.head, isA<Function>());
        expect(client.patch, isA<Function>());
      });
    });

    group('lifecycle management', () {
      test('should properly manage client lifecycle', () {
        // Initial state - no client
        CustomHttpClient.close();

        // Create client
        final client1 = CustomHttpClient.client;
        expect(client1, isNotNull);

        // Get same client
        final client2 = CustomHttpClient.client;
        expect(identical(client1, client2), true);

        // Close and recreate
        CustomHttpClient.close();
        final client3 = CustomHttpClient.client;
        expect(client3, isNotNull);
        expect(identical(client1, client3), false);
      });

      test('should handle rapid creation and closure', () {
        for (int i = 0; i < 5; i++) {
          final client = CustomHttpClient.client;
          expect(client, isNotNull);
          CustomHttpClient.close();
        }

        // Should still work after multiple cycles
        final finalClient = CustomHttpClient.client;
        expect(finalClient, isNotNull);
      });
    });

    group('thread safety', () {
      test('should handle concurrent access safely', () async {
        CustomHttpClient.close();

        // Simulate concurrent access
        final futures = List.generate(10, (index) {
          return Future(() => CustomHttpClient.client);
        });

        final clients = await Future.wait(futures);

        // All should be non-null
        for (final client in clients) {
          expect(client, isNotNull);
        }

        // All should be the same instance (singleton behavior)
        for (int i = 1; i < clients.length; i++) {
          expect(identical(clients[0], clients[i]), true);
        }
      });
    });

    group('SSL certificate handling', () {
      test('should configure SSL behavior based on kDebugMode', () {
        // The client should be created with appropriate SSL settings
        final client = CustomHttpClient.client;

        expect(client, isNotNull);

        // In debug mode (typical for tests), the client should be IOClient
        // In release mode, it should be a standard http.Client
        // We just verify it's created successfully
        if (kDebugMode) {
          // Debug mode: SSL verification is bypassed for development
          expect(client, isNotNull);
        } else {
          // Release mode: Standard SSL verification
          expect(client, isA<http.Client>());
        }
      });
    });

    group('error handling', () {
      test('should not throw when closing a non-existent client', () {
        CustomHttpClient.close();
        expect(() => CustomHttpClient.close(), returnsNormally);
      });

      test('should recover from closed client', () {
        final client1 = CustomHttpClient.client;
        expect(client1, isNotNull);

        client1.close();
        CustomHttpClient.close();

        // Should be able to get a new client
        expect(() => CustomHttpClient.client, returnsNormally);
        final client2 = CustomHttpClient.client;
        expect(client2, isNotNull);
      });
    });

    group('memory management', () {
      test('should release resources when closed', () {
        final client = CustomHttpClient.client;
        expect(client, isNotNull);

        // Close should release the internal reference
        CustomHttpClient.close();

        // Getting a new client should work
        final newClient = CustomHttpClient.client;
        expect(newClient, isNotNull);
        expect(identical(client, newClient), false);
      });
    });

    group('client methods availability', () {
      test('should have all standard HTTP methods', () {
        final client = CustomHttpClient.client;

        // Verify all standard HTTP methods are available
        expect(client.get, isNotNull);
        expect(client.post, isNotNull);
        expect(client.put, isNotNull);
        expect(client.delete, isNotNull);
        expect(client.patch, isNotNull);
        expect(client.head, isNotNull);
        expect(client.read, isNotNull);
        expect(client.readBytes, isNotNull);
        expect(client.send, isNotNull);
        expect(client.close, isNotNull);
      });

      test('should return client with correct type', () {
        final client = CustomHttpClient.client;

        expect(client, isA<http.Client>());
      });
    });

    group('integration scenarios', () {
      test('should work in typical usage pattern', () {
        // Get client for use
        final client = CustomHttpClient.client;
        expect(client, isNotNull);

        // Use client (methods exist)
        expect(client.get, isNotNull);
        expect(client.post, isNotNull);

        // Clean up at end of app lifecycle
        expect(() => CustomHttpClient.close(), returnsNormally);
      });

      test('should handle restart scenario', () {
        // Initial use
        final client1 = CustomHttpClient.client;
        expect(client1, isNotNull);

        // App restart simulation
        CustomHttpClient.close();

        // New session
        final client2 = CustomHttpClient.client;
        expect(client2, isNotNull);
        expect(identical(client1, client2), false);
      });
    });
  });
}
