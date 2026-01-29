import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/services/storage/token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TokenStorageService', () {
    late TokenStorageService service;

    setUp(() {
      service = TokenStorageService();
    });

    group('saveAccessToken', () {
      test('should save access token successfully', () async {
        SharedPreferences.setMockInitialValues({});

        await service.saveAccessToken('test_access_token');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_access_token'), 'test_access_token');
      });
    });

    group('saveRefreshToken', () {
      test('should save refresh token successfully', () async {
        SharedPreferences.setMockInitialValues({});

        await service.saveRefreshToken('test_refresh_token');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_refresh_token'), 'test_refresh_token');
      });
    });

    group('saveTokens', () {
      test('should save both tokens successfully', () async {
        SharedPreferences.setMockInitialValues({});

        await service.saveTokens(
          accessToken: 'test_access',
          refreshToken: 'test_refresh',
        );

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_access_token'), 'test_access');
        expect(prefs.getString('auth_refresh_token'), 'test_refresh');
      });
    });

    group('getAccessToken', () {
      test('should return access token when it exists', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'stored_access_token',
        });

        final token = await service.getAccessToken();

        expect(token, 'stored_access_token');
      });

      test('should return null when access token does not exist', () async {
        SharedPreferences.setMockInitialValues({});

        final token = await service.getAccessToken();

        expect(token, isNull);
      });
    });

    group('getRefreshToken', () {
      test('should return refresh token when it exists', () async {
        SharedPreferences.setMockInitialValues({
          'auth_refresh_token': 'stored_refresh_token',
        });

        final token = await service.getRefreshToken();

        expect(token, 'stored_refresh_token');
      });

      test('should return null when refresh token does not exist', () async {
        SharedPreferences.setMockInitialValues({});

        final token = await service.getRefreshToken();

        expect(token, isNull);
      });
    });

    group('getTokens', () {
      test('should return both tokens when they exist', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'access',
          'auth_refresh_token': 'refresh',
        });

        final tokens = await service.getTokens();

        expect(tokens['accessToken'], 'access');
        expect(tokens['refreshToken'], 'refresh');
      });

      test('should return nulls when tokens do not exist', () async {
        SharedPreferences.setMockInitialValues({});

        final tokens = await service.getTokens();

        expect(tokens['accessToken'], isNull);
        expect(tokens['refreshToken'], isNull);
      });
    });

    group('deleteAccessToken', () {
      test('should delete access token', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'test_token',
        });

        await service.deleteAccessToken();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_access_token'), isNull);
      });
    });

    group('deleteRefreshToken', () {
      test('should delete refresh token', () async {
        SharedPreferences.setMockInitialValues({
          'auth_refresh_token': 'test_token',
        });

        await service.deleteRefreshToken();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_refresh_token'), isNull);
      });
    });

    group('clearTokens', () {
      test('should clear all tokens', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'access',
          'auth_refresh_token': 'refresh',
        });

        await service.clearTokens();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_access_token'), isNull);
        expect(prefs.getString('auth_refresh_token'), isNull);
      });
    });

    group('hasAccessToken', () {
      test('should return true when access token exists and is not empty', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'test_token',
        });

        final result = await service.hasAccessToken();

        expect(result, true);
      });

      test('should return false when access token does not exist', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await service.hasAccessToken();

        expect(result, false);
      });

      test('should return false when access token is empty', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': '',
        });

        final result = await service.hasAccessToken();

        expect(result, false);
      });
    });

    group('hasTokens', () {
      test('should return true when both tokens exist', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'access',
          'auth_refresh_token': 'refresh',
        });

        final result = await service.hasTokens();

        expect(result, true);
      });

      test('should return false when access token is missing', () async {
        SharedPreferences.setMockInitialValues({
          'auth_refresh_token': 'refresh',
        });

        final result = await service.hasTokens();

        expect(result, false);
      });

      test('should return false when refresh token is missing', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'access',
        });

        final result = await service.hasTokens();

        expect(result, false);
      });
    });

    group('saveUserInfo', () {
      test('should save user info successfully', () async {
        SharedPreferences.setMockInitialValues({});

        await service.saveUserInfo(
          email: 'test@example.com',
          method: 'email',
        );

        final prefs = await SharedPreferences.getInstance();
        final userInfo = prefs.getString('auth_user_info');
        expect(userInfo, isNotNull);
        expect(userInfo, contains('test@example.com'));
        expect(userInfo, contains('email'));
      });
    });

    group('getUserInfo', () {
      test('should return user info when it exists', () async {
        SharedPreferences.setMockInitialValues({
          'auth_user_info': '{"method":"email","email":"test@example.com"}',
        });

        final userInfo = await service.getUserInfo();

        expect(userInfo, isNotNull);
        expect(userInfo!['email'], 'test@example.com');
        expect(userInfo['method'], 'email');
      });

      test('should return null when user info does not exist', () async {
        SharedPreferences.setMockInitialValues({});

        final userInfo = await service.getUserInfo();

        expect(userInfo, isNull);
      });

      test('should return null when user info is invalid JSON', () async {
        SharedPreferences.setMockInitialValues({
          'auth_user_info': 'invalid json',
        });

        final userInfo = await service.getUserInfo();

        expect(userInfo, isNull);
      });
    });

    group('getUserEmail', () {
      test('should return email when user info exists', () async {
        SharedPreferences.setMockInitialValues({
          'auth_user_info': '{"method":"email","email":"test@example.com"}',
        });

        final email = await service.getUserEmail();

        expect(email, 'test@example.com');
      });

      test('should return null when user info does not exist', () async {
        SharedPreferences.setMockInitialValues({});

        final email = await service.getUserEmail();

        expect(email, isNull);
      });
    });

    group('getAuthMethod', () {
      test('should return auth method when user info exists', () async {
        SharedPreferences.setMockInitialValues({
          'auth_user_info': '{"method":"google","email":"test@example.com"}',
        });

        final method = await service.getAuthMethod();

        expect(method, 'google');
      });

      test('should return null when user info does not exist', () async {
        SharedPreferences.setMockInitialValues({});

        final method = await service.getAuthMethod();

        expect(method, isNull);
      });
    });

    group('saveAuthInfo', () {
      test('should save all authentication information', () async {
        SharedPreferences.setMockInitialValues({});

        await service.saveAuthInfo(
          accessToken: 'access',
          refreshToken: 'refresh',
          email: 'test@example.com',
          method: 'email',
        );

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_access_token'), 'access');
        expect(prefs.getString('auth_refresh_token'), 'refresh');

        final userInfo = await service.getUserInfo();
        expect(userInfo!['email'], 'test@example.com');
        expect(userInfo['method'], 'email');
      });
    });

    group('getAuthInfo', () {
      test('should return all authentication information', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'access',
          'auth_refresh_token': 'refresh',
          'auth_user_info': '{"method":"email","email":"test@example.com"}',
        });

        final authInfo = await service.getAuthInfo();

        expect(authInfo['accessToken'], 'access');
        expect(authInfo['refreshToken'], 'refresh');
        expect(authInfo['email'], 'test@example.com');
        expect(authInfo['method'], 'email');
      });

      test('should return partial info when some data is missing', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'access',
        });

        final authInfo = await service.getAuthInfo();

        expect(authInfo['accessToken'], 'access');
        expect(authInfo['refreshToken'], isNull);
        expect(authInfo['email'], isNull);
        expect(authInfo['method'], isNull);
      });
    });

    group('clearAll', () {
      test('should clear all authentication data', () async {
        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'access',
          'auth_refresh_token': 'refresh',
          'auth_user_info': '{"method":"email","email":"test@example.com"}',
        });

        await service.clearAll();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_access_token'), isNull);
        expect(prefs.getString('auth_refresh_token'), isNull);
        // Note: clearAll only removes tokens, not user info
      });
    });
  });
}
