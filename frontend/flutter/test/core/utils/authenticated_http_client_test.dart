import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/storage/token_storage_service.dart';
import 'package:naavi/core/utils/authenticated_http_client.dart';

// Mocks
class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorageService extends Mock implements TokenStorageService {}

class MockStreamedResponse extends Mock implements http.StreamedResponse {}

// Fake classes for mocktail registration
class FakeUri extends Fake implements Uri {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeBaseRequest());
  });

  group('AuthenticatedHttpClient', () {
    late AuthenticatedHttpClient authenticatedClient;
    late MockHttpClient mockInnerClient;
    late MockTokenStorageService mockTokenStorage;
    late bool unauthorizedCallbackCalled;

    const baseUrl = 'https://api.test.com';
    const accessToken = 'test_access_token';
    const refreshToken = 'test_refresh_token';
    const newAccessToken = 'new_access_token';

    setUp(() {
      mockInnerClient = MockHttpClient();
      mockTokenStorage = MockTokenStorageService();
      unauthorizedCallbackCalled = false;

      authenticatedClient = AuthenticatedHttpClient(
        baseUrl: baseUrl,
        tokenStorage: mockTokenStorage,
        innerClient: mockInnerClient,
        onUnauthorized: () {
          unauthorizedCallbackCalled = true;
        },
      );
    });

    tearDown(() {
      authenticatedClient.close();
    });

    group('constructor', () {
      test('should create client with required parameters', () {
        final client = AuthenticatedHttpClient(
          baseUrl: baseUrl,
          tokenStorage: mockTokenStorage,
        );

        expect(client, isNotNull);
        expect(client.baseUrl, baseUrl);
        client.close();
      });

      test('should accept custom inner client', () {
        final customClient = MockHttpClient();
        final client = AuthenticatedHttpClient(
          baseUrl: baseUrl,
          tokenStorage: mockTokenStorage,
          innerClient: customClient,
        );

        expect(client, isNotNull);
        client.close();
      });

      test('should accept onUnauthorized callback', () {
        final client = AuthenticatedHttpClient(
          baseUrl: baseUrl,
          tokenStorage: mockTokenStorage,
          onUnauthorized: () {
            // Callback for testing
          },
        );

        expect(client, isNotNull);
        client.close();
      });
    });

    group('send - successful request', () {
      test('should add Authorization header when access token exists', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));
        final responseStream = http.StreamedResponse(
          Stream.value([]),
          200,
        );

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => responseStream);

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 200);
        expect(request.headers['Authorization'], 'Bearer $accessToken');
        verify(() => mockTokenStorage.getAccessToken()).called(1);
      });

      test('should not add Authorization header when no access token', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => null);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));
        final responseStream = http.StreamedResponse(
          Stream.value([]),
          200,
        );

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => responseStream);

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 200);
        expect(request.headers.containsKey('Authorization'), false);
      });

      test('should return successful response for 200 status', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));
        final responseStream = http.StreamedResponse(
          Stream.value(utf8.encode('{"data": "success"}')),
          200,
        );

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => responseStream);

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 200);
      });
    });

    group('send - 401 with successful refresh', () {
      test('should refresh token and retry on 401', () async {
        var sendCallCount = 0;

        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async {
          if (sendCallCount == 0) {
            return accessToken;
          } else {
            return newAccessToken;
          }
        });

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        when(() => mockInnerClient.send(any())).thenAnswer((_) async {
          sendCallCount++;
          if (sendCallCount == 1) {
            // First call returns 401
            return http.StreamedResponse(Stream.value([]), 401);
          } else {
            // Retry after refresh succeeds
            return http.StreamedResponse(
              Stream.value(utf8.encode('{"data": "success"}')),
              200,
            );
          }
        });

        // Mock refresh token request
        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'accessToken': newAccessToken}),
              200,
            ));

        when(() => mockTokenStorage.saveAccessToken(newAccessToken))
            .thenAnswer((_) async => Future.value());

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 200);
        verify(() => mockTokenStorage.saveAccessToken(newAccessToken)).called(1);
        expect(sendCallCount, 2); // Initial + retry
      });

      test('should handle multiple requests during token refresh', () async {
        var sendCallCount = 0;

        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async {
          if (sendCallCount < 2) {
            return accessToken;
          } else {
            return newAccessToken;
          }
        });

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        when(() => mockInnerClient.send(any())).thenAnswer((_) async {
          sendCallCount++;
          if (sendCallCount <= 2) {
            // First two calls return 401
            return http.StreamedResponse(Stream.value([]), 401);
          } else {
            // Subsequent calls succeed
            return http.StreamedResponse(
              Stream.value(utf8.encode('{"data": "success"}')),
              200,
            );
          }
        });

        // Mock refresh token request
        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'accessToken': newAccessToken}),
              200,
            ));

        when(() => mockTokenStorage.saveAccessToken(newAccessToken))
            .thenAnswer((_) async => Future.value());

        final request1 = http.Request('GET', Uri.parse('$baseUrl/test1'));
        final request2 = http.Request('GET', Uri.parse('$baseUrl/test2'));

        // Send both requests concurrently
        final results = await Future.wait([
          authenticatedClient.send(request1),
          authenticatedClient.send(request2),
        ]);

        expect(results[0].statusCode, 200);
        expect(results[1].statusCode, 200);
        verify(() => mockTokenStorage.saveAccessToken(newAccessToken)).called(1);
      });
    });

    group('send - 401 with failed refresh', () {
      test('should call onUnauthorized and clear tokens when refresh fails', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 401));

        // Mock refresh token request failure
        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response('Unauthorized', 401));

        when(() => mockTokenStorage.clearAll())
            .thenAnswer((_) async => Future.value());

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 401);
        expect(unauthorizedCallbackCalled, true);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });

      test('should handle refresh failure when no refresh token exists', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => null);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 401));

        when(() => mockTokenStorage.clearAll())
            .thenAnswer((_) async => Future.value());

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 401);
        expect(unauthorizedCallbackCalled, true);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });

      test('should handle refresh exception', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 401));

        // Mock refresh token request throws exception
        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenThrow(Exception('Network error'));

        when(() => mockTokenStorage.clearAll())
            .thenAnswer((_) async => Future.value());

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 401);
        expect(unauthorizedCallbackCalled, true);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });

      test('should work without onUnauthorized callback', () async {
        final client = AuthenticatedHttpClient(
          baseUrl: baseUrl,
          tokenStorage: mockTokenStorage,
          innerClient: mockInnerClient,
          onUnauthorized: null,
        );

        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => null);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 401));

        when(() => mockTokenStorage.clearAll())
            .thenAnswer((_) async => Future.value());

        final response = await client.send(request);

        expect(response.statusCode, 401);
        verify(() => mockTokenStorage.clearAll()).called(1);
        client.close();
      });
    });

    group('token refresh logic', () {
      test('should save new access token on successful refresh', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        var sendCallCount = 0;
        when(() => mockInnerClient.send(any())).thenAnswer((_) async {
          sendCallCount++;
          if (sendCallCount == 1) {
            return http.StreamedResponse(Stream.value([]), 401);
          } else {
            return http.StreamedResponse(Stream.value([]), 200);
          }
        });

        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'accessToken': newAccessToken}),
              200,
            ));

        when(() => mockTokenStorage.saveAccessToken(newAccessToken))
            .thenAnswer((_) async => Future.value());

        await authenticatedClient.send(request);

        verify(() => mockTokenStorage.saveAccessToken(newAccessToken)).called(1);
      });

      test('should handle refresh response with missing accessToken', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 401));

        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'wrongKey': 'value'}),
              200,
            ));

        when(() => mockTokenStorage.clearAll())
            .thenAnswer((_) async => Future.value());

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 401);
        expect(unauthorizedCallbackCalled, true);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });

      test('should handle malformed refresh response', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 401));

        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response(
              'invalid json',
              200,
            ));

        when(() => mockTokenStorage.clearAll())
            .thenAnswer((_) async => Future.value());

        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 401);
        expect(unauthorizedCallbackCalled, true);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });
    });

    group('request copying', () {
      test('should copy request headers correctly', () async {
        var sendCallCount = 0;

        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async {
          if (sendCallCount == 0) {
            return accessToken;
          } else {
            return newAccessToken;
          }
        });

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final request = http.Request('POST', Uri.parse('$baseUrl/test'))
          ..headers['Custom-Header'] = 'custom-value'
          ..body = 'test body';

        http.BaseRequest? capturedRequest;

        when(() => mockInnerClient.send(any())).thenAnswer((invocation) async {
          capturedRequest = invocation.positionalArguments[0] as http.BaseRequest;
          sendCallCount++;
          if (sendCallCount == 1) {
            return http.StreamedResponse(Stream.value([]), 401);
          } else {
            return http.StreamedResponse(Stream.value([]), 200);
          }
        });

        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'accessToken': newAccessToken}),
              200,
            ));

        when(() => mockTokenStorage.saveAccessToken(newAccessToken))
            .thenAnswer((_) async => Future.value());

        await authenticatedClient.send(request);

        // Verify the retried request has custom headers
        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.headers['Custom-Header'], 'custom-value');
      });

      test('should copy request body correctly', () async {
        var sendCallCount = 0;

        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async {
          if (sendCallCount == 0) {
            return accessToken;
          } else {
            return newAccessToken;
          }
        });

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        final requestBody = jsonEncode({'key': 'value'});
        final request = http.Request('POST', Uri.parse('$baseUrl/test'))
          ..body = requestBody;

        http.Request? capturedRequest;

        when(() => mockInnerClient.send(any())).thenAnswer((invocation) async {
          final req = invocation.positionalArguments[0] as http.BaseRequest;
          sendCallCount++;
          if (sendCallCount == 1) {
            return http.StreamedResponse(Stream.value([]), 401);
          } else {
            if (req is http.Request) {
              capturedRequest = req;
            }
            return http.StreamedResponse(Stream.value([]), 200);
          }
        });

        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'accessToken': newAccessToken}),
              200,
            ));

        when(() => mockTokenStorage.saveAccessToken(newAccessToken))
            .thenAnswer((_) async => Future.value());

        await authenticatedClient.send(request);

        // Verify the retried request has the same body
        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.body, requestBody);
      });
    });

    group('HTTP methods', () {
      test('should support GET requests', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 200));

        final response = await authenticatedClient.get(
          Uri.parse('$baseUrl/test'),
        );

        expect(response.statusCode, 200);
      });

      test('should support POST requests', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(
              Stream.value(utf8.encode('{"result": "created"}')),
              201,
            ));

        final response = await authenticatedClient.post(
          Uri.parse('$baseUrl/test'),
          body: jsonEncode({'data': 'test'}),
        );

        expect(response.statusCode, 201);
      });

      test('should support PUT requests', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 200));

        final response = await authenticatedClient.put(
          Uri.parse('$baseUrl/test'),
          body: jsonEncode({'data': 'updated'}),
        );

        expect(response.statusCode, 200);
      });

      test('should support DELETE requests', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 204));

        final response = await authenticatedClient.delete(
          Uri.parse('$baseUrl/test'),
        );

        expect(response.statusCode, 204);
      });

      test('should support PATCH requests', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 200));

        final response = await authenticatedClient.patch(
          Uri.parse('$baseUrl/test'),
          body: jsonEncode({'field': 'value'}),
        );

        expect(response.statusCode, 200);
      });

      test('should support HEAD requests', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 200));

        final response = await authenticatedClient.head(
          Uri.parse('$baseUrl/test'),
        );

        expect(response.statusCode, 200);
      });
    });

    group('close', () {
      test('should close inner client', () {
        when(() => mockInnerClient.close()).thenReturn(null);

        authenticatedClient.close();

        verify(() => mockInnerClient.close()).called(1);
      });

      test('should not throw when closing multiple times', () {
        when(() => mockInnerClient.close()).thenReturn(null);

        expect(() {
          authenticatedClient.close();
          authenticatedClient.close();
        }, returnsNormally);
      });
    });

    group('edge cases', () {
      test('should handle empty response body', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 204));

        final request = http.Request('DELETE', Uri.parse('$baseUrl/test'));
        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 204);
      });

      test('should handle very long access token', () async {
        final longToken = 'token_' * 1000;

        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => longToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 200));

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));
        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 200);
        expect(request.headers['Authorization'], 'Bearer $longToken');
      });

      test('should handle non-401 error responses without refresh', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 403));

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));
        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 403);
        verifyNever(() => mockTokenStorage.getRefreshToken());
      });

      test('should handle 500 error responses without refresh', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenAnswer((_) async => accessToken);

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 500));

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));
        final response = await authenticatedClient.send(request);

        expect(response.statusCode, 500);
        verifyNever(() => mockTokenStorage.getRefreshToken());
      });
    });

    group('concurrent refresh scenarios', () {
      test('should queue requests during active refresh', () async {
        var refreshCalled = 0;

        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async {
          if (refreshCalled == 0) {
            return accessToken;
          } else {
            return newAccessToken;
          }
        });

        when(() => mockTokenStorage.getRefreshToken())
            .thenAnswer((_) async => refreshToken);

        var sendCallCount = 0;
        when(() => mockInnerClient.send(any())).thenAnswer((_) async {
          sendCallCount++;
          if (sendCallCount <= 2) {
            // First two requests get 401
            return http.StreamedResponse(Stream.value([]), 401);
          } else {
            return http.StreamedResponse(Stream.value([]), 200);
          }
        });

        when(() => mockInnerClient.post(
              Uri.parse('$baseUrl/identity/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'token': refreshToken}),
            )).thenAnswer((_) async {
          refreshCalled++;
          await Future.delayed(Duration(milliseconds: 50)); // Simulate delay
          return http.Response(
            jsonEncode({'accessToken': newAccessToken}),
            200,
          );
        });

        when(() => mockTokenStorage.saveAccessToken(newAccessToken))
            .thenAnswer((_) async => Future.value());

        // Send two requests that will both get 401
        final request1 = http.Request('GET', Uri.parse('$baseUrl/test1'));
        final request2 = http.Request('GET', Uri.parse('$baseUrl/test2'));

        final responses = await Future.wait([
          authenticatedClient.send(request1),
          authenticatedClient.send(request2),
        ]);

        expect(responses[0].statusCode, 200);
        expect(responses[1].statusCode, 200);
        // Refresh should only be called once
        expect(refreshCalled, 1);
      });
    });

    group('token storage integration', () {
      test('should call token storage methods in correct order', () async {
        final callOrder = <String>[];

        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async {
          callOrder.add('getAccessToken');
          return accessToken;
        });

        when(() => mockInnerClient.send(any()))
            .thenAnswer((_) async => http.StreamedResponse(Stream.value([]), 200));

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));
        await authenticatedClient.send(request);

        expect(callOrder, ['getAccessToken']);
      });

      test('should handle token storage errors gracefully', () async {
        when(() => mockTokenStorage.getAccessToken())
            .thenThrow(Exception('Storage error'));

        final request = http.Request('GET', Uri.parse('$baseUrl/test'));

        expect(
          () => authenticatedClient.send(request),
          throwsException,
        );
      });
    });
  });
}
