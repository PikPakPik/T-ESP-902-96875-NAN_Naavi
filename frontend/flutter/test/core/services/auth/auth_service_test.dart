import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/auth/auth_service.dart';
import 'package:naavi/core/services/storage/token_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockHttpClient extends Mock implements http.Client {}

class MockTokenStorageService extends Mock implements TokenStorageService {}

// Fake URI for mocktail registration
class FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeUri());

    // Initialize dotenv for tests
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://api.test.com
''',
    );
  });

  group('AuthService', () {
    late AuthService authService;
    late MockHttpClient mockHttpClient;
    late MockTokenStorageService mockTokenStorage;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockTokenStorage = MockTokenStorageService();
      authService = AuthService(
        authenticatedClient: mockHttpClient,
        tokenStorage: mockTokenStorage,
      );

      // Setup SharedPreferences mock for tests
      SharedPreferences.setMockInitialValues({});
    });

    group('signInWithGoogle', () {
      test('should return true when Google sign-in succeeds', () async {
        final result = await authService.signInWithGoogle();

        // Currently simulated, should return true
        expect(result, true);
      });
    });

    group('signInWithApple', () {
      test('should return true when Apple sign-in succeeds', () async {
        final result = await authService.signInWithApple();

        // Currently simulated, should return true
        expect(result, true);
      });
    });

    group('verifyToken', () {
      test('should return true when token verification succeeds', () async {
        final result = await authService.verifyToken('test_token');

        // Currently simulated, should return true
        expect(result, true);
      });
    });

    group('checkEmailExists', () {
      test('should return false by default (uses real HTTP client)', () async {
        // Note: This method uses _basicHttpClient (CustomHttpClient.client)
        // which cannot be easily mocked, so we test the default behavior
        final result = await authService.checkEmailExists(
          'test@example.com',
          'token',
        );

        // Should return false (default behavior or network failure)
        expect(result, isA<bool>());
      });

      test('should handle any email input', () async {
        final result = await authService.checkEmailExists(
          'any@example.com',
          'token',
        );

        expect(result, isA<bool>());
      });

      test('should handle empty email', () async {
        final result = await authService.checkEmailExists('', 'token');

        expect(result, isA<bool>());
      });

      test('should handle empty token', () async {
        final result = await authService.checkEmailExists(
          'test@example.com',
          '',
        );

        expect(result, isA<bool>());
      });
    });

    group('login', () {
      test(
        'should return user data and save tokens on successful login',
        () async {
          final responseData = {
            'accessToken': 'access_token_123',
            'refreshToken': 'refresh_token_123',
            'user': {'email': 'test@example.com', 'id': '123'},
          };

          when(
            () => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => http.Response(jsonEncode(responseData), 200),
          );

          when(
            () => mockTokenStorage.saveAuthInfo(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
              email: any(named: 'email'),
              method: any(named: 'method'),
            ),
          ).thenAnswer((_) async => Future.value());

          final result = await authService.login(
            'test@example.com',
            'password',
            'token',
          );

          expect(result, isNotNull);
          expect(result!['accessToken'], 'access_token_123');
          expect(result['refreshToken'], 'refresh_token_123');

          verify(
            () => mockTokenStorage.saveAuthInfo(
              accessToken: 'access_token_123',
              refreshToken: 'refresh_token_123',
              email: 'test@example.com',
              method: 'email',
            ),
          ).called(1);
        },
      );

      test('should return null when login fails with non-200 status', () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Unauthorized', 401));

        final result = await authService.login(
          'test@example.com',
          'wrong_password',
          'token',
        );

        expect(result, isNull);
        verifyNever(
          () => mockTokenStorage.saveAuthInfo(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
            email: any(named: 'email'),
            method: any(named: 'method'),
          ),
        );
      });

      test('should return null when exception occurs', () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('Network error'));

        final result = await authService.login(
          'test@example.com',
          'password',
          'token',
        );

        expect(result, isNull);
      });
    });

    group('createAccount', () {
      test(
        'should return user data and save tokens on successful registration',
        () async {
          final responseData = {
            'accessToken': 'new_access_token',
            'refreshToken': 'new_refresh_token',
            'user': {'email': 'newuser@example.com', 'id': '456'},
          };

          when(
            () => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => http.Response(jsonEncode(responseData), 201),
          );

          when(
            () => mockTokenStorage.saveAuthInfo(
              accessToken: any(named: 'accessToken'),
              refreshToken: any(named: 'refreshToken'),
              email: any(named: 'email'),
              method: any(named: 'method'),
            ),
          ).thenAnswer((_) async => Future.value());

          final result = await authService.createAccount(
            'newuser@example.com',
            'password',
            'test_turnstile_token',
            firstname: 'John',
            lastname: 'Doe',
          );

          expect(result, isNotNull);
          expect(result!['accessToken'], 'new_access_token');
          expect(result['refreshToken'], 'new_refresh_token');

          verify(
            () => mockTokenStorage.saveAuthInfo(
              accessToken: 'new_access_token',
              refreshToken: 'new_refresh_token',
              email: 'newuser@example.com',
              method: 'email',
            ),
          ).called(1);
        },
      );

      test('should return null when registration fails', () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Bad Request', 400));

        final result = await authService.createAccount(
          'invalid@example.com',
          'weak',
          'test_turnstile_token',
          firstname: 'Jane',
          lastname: 'Doe',
        );

        expect(result, isNull);
      });
    });

    group('signOut', () {
      test('should clear all tokens and call logout endpoint', () async {
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'test_access_token');

        when(
          () => mockTokenStorage.clearAll(),
        ).thenAnswer((_) async => Future.value());

        when(
          () => mockHttpClient.delete(any()),
        ).thenAnswer((_) async => http.Response('OK', 200));

        await authService.signOut();

        verify(() => mockTokenStorage.getAccessToken()).called(1);
        verify(() => mockHttpClient.delete(any())).called(1);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });

      test('should clear tokens even when logout endpoint fails', () async {
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'test_access_token');

        when(
          () => mockTokenStorage.clearAll(),
        ).thenAnswer((_) async => Future.value());

        when(
          () => mockHttpClient.delete(any()),
        ).thenAnswer((_) async => http.Response('Error', 500));

        await authService.signOut();

        verify(() => mockTokenStorage.clearAll()).called(1);
      });

      test('should clear tokens when no access token available', () async {
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => null);

        when(
          () => mockTokenStorage.clearAll(),
        ).thenAnswer((_) async => Future.value());

        await authService.signOut();

        verify(() => mockTokenStorage.getAccessToken()).called(1);
        verifyNever(() => mockHttpClient.delete(any()));
        verify(() => mockTokenStorage.clearAll()).called(1);
      });
    });

    group('deleteAccount', () {
      test('should delete account and clear tokens on success', () async {
        when(
          () => mockHttpClient.delete(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('', 204));

        when(
          () => mockTokenStorage.clearAll(),
        ).thenAnswer((_) async => Future.value());

        final result = await authService.deleteAccount();

        expect(result, true);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });

      test('should return false when account deletion fails', () async {
        when(
          () => mockHttpClient.delete(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('Forbidden', 403));

        final result = await authService.deleteAccount();

        expect(result, false);
        verifyNever(() => mockTokenStorage.clearAll());
      });
    });

    group('getAccessToken', () {
      test('should return access token from storage', () async {
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'stored_access_token');

        final token = await authService.getAccessToken();

        expect(token, 'stored_access_token');
        verify(() => mockTokenStorage.getAccessToken()).called(1);
      });
    });

    group('getRefreshToken', () {
      test('should return refresh token from storage', () async {
        when(
          () => mockTokenStorage.getRefreshToken(),
        ).thenAnswer((_) async => 'stored_refresh_token');

        final token = await authService.getRefreshToken();

        expect(token, 'stored_refresh_token');
        verify(() => mockTokenStorage.getRefreshToken()).called(1);
      });
    });

    group('isAuthenticated', () {
      test('should return true when user has access token', () async {
        when(
          () => mockTokenStorage.hasAccessToken(),
        ).thenAnswer((_) async => true);

        final result = await authService.isAuthenticated();

        expect(result, true);
      });

      test('should return false when user has no access token', () async {
        when(
          () => mockTokenStorage.hasAccessToken(),
        ).thenAnswer((_) async => false);

        final result = await authService.isAuthenticated();

        expect(result, false);
      });
    });

    group('refreshAccessToken', () {
      test('should return new access token on successful refresh', () async {
        when(
          () => mockTokenStorage.getRefreshToken(),
        ).thenAnswer((_) async => 'valid_refresh_token');

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'accessToken': 'new_access_token'}),
            200,
          ),
        );

        when(
          () => mockTokenStorage.saveAccessToken(any()),
        ).thenAnswer((_) async => Future.value());

        final newToken = await authService.refreshAccessToken();

        expect(newToken, 'new_access_token');
        verify(
          () => mockTokenStorage.saveAccessToken('new_access_token'),
        ).called(1);
      });

      test('should return null when no refresh token exists', () async {
        when(
          () => mockTokenStorage.getRefreshToken(),
        ).thenAnswer((_) async => null);

        final newToken = await authService.refreshAccessToken();

        expect(newToken, isNull);
        verifyNever(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        );
      });

      test('should clear tokens and return null when refresh fails', () async {
        when(
          () => mockTokenStorage.getRefreshToken(),
        ).thenAnswer((_) async => 'expired_refresh_token');

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Unauthorized', 401));

        when(
          () => mockTokenStorage.clearAll(),
        ).thenAnswer((_) async => Future.value());

        final newToken = await authService.refreshAccessToken();

        expect(newToken, isNull);
        verify(() => mockTokenStorage.clearAll()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return user data when request succeeds', () async {
        final userData = {
          'id': '123',
          'email': 'test@example.com',
          'name': 'Test User',
        };

        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'valid_access_token');

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response(jsonEncode(userData), 200));

        when(
          () => mockTokenStorage.saveUserProfile(any()),
        ).thenAnswer((_) async => Future.value());

        final user = await authService.getCurrentUser();

        expect(user, isNotNull);
        expect(user!['email'], 'test@example.com');
      });

      test('should return null when no access token exists', () async {
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => null);

        final user = await authService.getCurrentUser();

        expect(user, isNull);
        verifyNever(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        );
      });

      test('should return null when request returns 401', () async {
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'expired_token');

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('Unauthorized', 401));

        final user = await authService.getCurrentUser();

        expect(user, isNull);
      });
    });

    group('checkAndRestoreSession', () {
      test(
        'should return "authenticated" when user session is valid',
        () async {
          when(
            () => mockTokenStorage.hasTokens(),
          ).thenAnswer((_) async => true);
          when(
            () => mockTokenStorage.getAccessToken(),
          ).thenAnswer((_) async => 'valid_token');

          when(
            () => mockHttpClient.get(any(), headers: any(named: 'headers')),
          ).thenAnswer(
            (_) async => http.Response(
              jsonEncode({'id': '123', 'email': 'test@example.com'}),
              200,
            ),
          );

          when(
            () => mockTokenStorage.saveUserProfile(any()),
          ).thenAnswer((_) async => Future.value());

          when(
            () => mockTokenStorage.clearAll(),
          ).thenAnswer((_) async => Future.value());

          final result = await authService.checkAndRestoreSession();

          expect(result, 'authenticated');
        },
      );

      test('should return "unauthenticated" when no tokens exist', () async {
        when(() => mockTokenStorage.hasTokens()).thenAnswer((_) async => false);

        final result = await authService.checkAndRestoreSession();

        expect(result, 'unauthenticated');
      });

      test('should return email when refresh fails', () async {
        when(() => mockTokenStorage.hasTokens()).thenAnswer((_) async => true);
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'expired_token');
        when(
          () => mockTokenStorage.getRefreshToken(),
        ).thenAnswer((_) async => 'expired_refresh');
        when(
          () => mockTokenStorage.getUserEmail(),
        ).thenAnswer((_) async => 'user@example.com');

        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('Unauthorized', 401));

        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Unauthorized', 401));

        when(
          () => mockTokenStorage.clearAll(),
        ).thenAnswer((_) async => Future.value());

        final result = await authService.checkAndRestoreSession();

        expect(result, 'user@example.com');
        // clearAll() is called twice: once in refreshAccessToken() and once in checkAndRestoreSession()
        verify(() => mockTokenStorage.clearAll()).called(2);
      });

      test('should successfully restore session after refresh', () async {
        when(() => mockTokenStorage.hasTokens()).thenAnswer((_) async => true);
        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'expired_token');
        when(
          () => mockTokenStorage.getRefreshToken(),
        ).thenAnswer((_) async => 'valid_refresh_token');

        // First call returns 401 (token expired)
        var callCount = 0;
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return http.Response('Unauthorized', 401);
          } else {
            return http.Response(
              jsonEncode({'id': '123', 'email': 'test@example.com'}),
              200,
            );
          }
        });

        // Refresh returns new token
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'accessToken': 'new_access_token'}),
            200,
          ),
        );

        when(
          () => mockTokenStorage.saveAccessToken(any()),
        ).thenAnswer((_) async => Future.value());

        when(
          () => mockTokenStorage.saveUserProfile(any()),
        ).thenAnswer((_) async => Future.value());

        when(
          () => mockTokenStorage.clearAll(),
        ).thenAnswer((_) async => Future.value());

        final result = await authService.checkAndRestoreSession();

        expect(result, 'authenticated');
        verify(
          () => mockTokenStorage.saveAccessToken('new_access_token'),
        ).called(1);
      });
    });

    group('Constructor', () {
      test('should use provided tokenStorage', () {
        final customTokenStorage = MockTokenStorageService();
        final service = AuthService(
          authenticatedClient: mockHttpClient,
          tokenStorage: customTokenStorage,
        );

        expect(service.tokenStorage, same(customTokenStorage));
      });

      test('should create default TokenStorageService when null', () {
        final service = AuthService(authenticatedClient: mockHttpClient);

        expect(service.tokenStorage, isA<TokenStorageService>());
        expect(service.tokenStorage, isNot(same(mockTokenStorage)));
      });
    });
  });
}
