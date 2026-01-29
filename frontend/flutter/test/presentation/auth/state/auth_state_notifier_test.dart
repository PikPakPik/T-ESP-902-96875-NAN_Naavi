import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naavi/core/services/auth/auth_service.dart';
import 'package:naavi/core/services/network/check_network_service.dart';
import 'package:naavi/core/services/turnstile_service.dart';
import 'package:naavi/presentation/auth/state/AuthState.dart';
import 'package:naavi/presentation/auth/state/AuthStateNotifier.dart';

// Mocks
class MockAuthService extends Mock implements AuthService {}

class MockBuildContext extends Mock implements BuildContext {}

class MockTurnstileService extends Mock implements TurnstileService {}

class MockCheckNetworkService extends Mock implements CheckNetworkService {}

void main() {
  setUpAll(() {
    // Register fallback values if needed
  });

  group('AuthStateNotifier', () {
    late AuthStateNotifier notifier;
    late MockAuthService mockAuthService;
    late MockBuildContext mockContext;
    late MockTurnstileService mockTurnstileService;
    late MockCheckNetworkService mockCheckNetworkService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockContext = MockBuildContext();
      mockTurnstileService = MockTurnstileService();
      mockCheckNetworkService = MockCheckNetworkService();

      // Injecter le mock TurnstileService
      TurnstileService.instance = mockTurnstileService;

      // Par défaut, le mock retourne un token valide
      when(
        () => mockTurnstileService.getToken(),
      ).thenAnswer((_) async => 'test_token');

      // Par défaut, on est en ligne
      when(
        () => mockCheckNetworkService.checkConnection(),
      ).thenAnswer((_) async => ConnectivityState.online);

      notifier = AuthStateNotifier(
        authService: mockAuthService,
        checkNetworkService: mockCheckNetworkService,
      );
    });

    tearDown(() {
      TurnstileService.resetInstance();
    });

    test('initial state should be AuthStateInitial', () {
      expect(notifier.state, isA<AuthStateInitial>());
    });

    group('signInWithGoogle', () {
      test(
        'should emit loading then success state on successful Google sign-in',
        () async {
          when(
            () => mockAuthService.signInWithGoogle(),
          ).thenAnswer((_) async => true);
          when(() => mockContext.mounted).thenReturn(false);

          // Collect state changes using stream
          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.signInWithGoogle(mockContext);
          await Future.delayed(Duration.zero); // Allow stream to emit

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateSuccess>()]);
          verify(() => mockAuthService.signInWithGoogle()).called(1);

          await subscription.cancel();
        },
      );

      test(
        'should emit loading then error state when Google sign-in fails',
        () async {
          when(
            () => mockAuthService.signInWithGoogle(),
          ).thenAnswer((_) async => false);

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.signInWithGoogle(mockContext);
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
          expect(
            (states.last as AuthStateError).message,
            'Échec de la connexion avec Google',
          );

          await subscription.cancel();
        },
      );

      test(
        'should emit error state when Google sign-in throws exception',
        () async {
          when(
            () => mockAuthService.signInWithGoogle(),
          ).thenThrow(Exception('Network error'));

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.signInWithGoogle(mockContext);
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
          expect((states.last as AuthStateError).message, contains('Erreur:'));

          await subscription.cancel();
        },
      );
    });

    group('signInWithApple', () {
      test(
        'should emit loading then success state on successful Apple sign-in',
        () async {
          when(
            () => mockAuthService.signInWithApple(),
          ).thenAnswer((_) async => true);
          when(() => mockContext.mounted).thenReturn(false);

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.signInWithApple(mockContext);
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateSuccess>()]);
          verify(() => mockAuthService.signInWithApple()).called(1);

          await subscription.cancel();
        },
      );

      test(
        'should emit loading then error state when Apple sign-in fails',
        () async {
          when(
            () => mockAuthService.signInWithApple(),
          ).thenAnswer((_) async => false);

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.signInWithApple(mockContext);
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
          expect(
            (states.last as AuthStateError).message,
            'Échec de la connexion avec Apple',
          );

          await subscription.cancel();
        },
      );

      test(
        'should emit error state when Apple sign-in throws exception',
        () async {
          when(
            () => mockAuthService.signInWithApple(),
          ).thenThrow(Exception('Apple ID error'));

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.signInWithApple(mockContext);
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
          expect((states.last as AuthStateError).message, contains('Erreur:'));

          await subscription.cancel();
        },
      );
    });

    group('checkEmail', () {
      const testEmail = 'test@example.com';
      const testToken = 'test_token';

      test('should emit error state when email is empty', () async {
        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.checkEmail(mockContext, '');
        await Future.delayed(Duration.zero);

        expect(states, [isA<AuthStateError>()]);
        expect(
          (states.last as AuthStateError).message,
          'Veuillez entrer une adresse email valide',
        );
        verifyNever(() => mockAuthService.checkEmailExists(any(), any()));

        await subscription.cancel();
      });

      test('should emit error state when email is invalid', () async {
        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.checkEmail(mockContext, 'invalid-email');
        await Future.delayed(Duration.zero);

        expect(states, [isA<AuthStateError>()]);
        expect(
          (states.last as AuthStateError).message,
          'Veuillez entrer une adresse email valide',
        );
        verifyNever(() => mockAuthService.checkEmailExists(any(), any()));

        await subscription.cancel();
      });

      test('should emit error state when Turnstile token is null', () async {
        when(
          () => mockTurnstileService.getToken(),
        ).thenAnswer((_) async => null);

        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.checkEmail(mockContext, testEmail);
        await Future.delayed(Duration.zero);

        expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
        expect(
          (states.last as AuthStateError).message,
          'Erreur de vérification de sécurité',
        );

        await subscription.cancel();
      });

      test('should emit PasswordRequired state when email exists', () async {
        when(
          () => mockAuthService.checkEmailExists(testEmail, testToken),
        ).thenAnswer((_) async => true);

        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.checkEmail(mockContext, testEmail);
        await Future.delayed(Duration.zero);

        expect(states, [
          isA<AuthStateLoading>(),
          isA<AuthStatePasswordRequired>(),
        ]);
        expect((states.last as AuthStatePasswordRequired).email, testEmail);
        verify(
          () => mockAuthService.checkEmailExists(testEmail, testToken),
        ).called(1);

        await subscription.cancel();
      });

      test(
        'should emit CreatePassword state when email does not exist',
        () async {
          when(
            () => mockAuthService.checkEmailExists(testEmail, testToken),
          ).thenAnswer((_) async => false);

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.checkEmail(mockContext, testEmail);
          await Future.delayed(Duration.zero);

          expect(states, [
            isA<AuthStateLoading>(),
            isA<AuthStateCreatePassword>(),
          ]);
          expect((states.last as AuthStateCreatePassword).email, testEmail);

          await subscription.cancel();
        },
      );

      test(
        'should emit error state when checkEmailExists throws exception',
        () async {
          when(
            () => mockAuthService.checkEmailExists(testEmail, testToken),
          ).thenThrow(Exception('API error'));

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.checkEmail(mockContext, testEmail);
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);

          await subscription.cancel();
        },
      );
    });

    group('loginWithPassword', () {
      const testEmail = 'test@example.com';
      const testPassword = 'Password123!';
      const testToken = 'test_token';

      test('should emit error state when password is empty', () async {
        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.loginWithPassword(mockContext, testEmail, '');
        await Future.delayed(Duration.zero);

        expect(states, [isA<AuthStateError>()]);
        expect(
          (states.last as AuthStateError).message,
          'Veuillez entrer votre mot de passe',
        );
        verifyNever(() => mockAuthService.login(any(), any(), any()));

        await subscription.cancel();
      });

      test('should emit error state when Turnstile token is null', () async {
        when(
          () => mockTurnstileService.getToken(),
        ).thenAnswer((_) async => null);

        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.loginWithPassword(mockContext, testEmail, testPassword);
        await Future.delayed(Duration.zero);

        expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
        expect(
          (states.last as AuthStateError).message,
          'Erreur de vérification de sécurité',
        );

        await subscription.cancel();
      });

      test(
        'should emit loading then success state on successful login',
        () async {
          when(
            () => mockAuthService.login(testEmail, testPassword, testToken),
          ).thenAnswer((_) async => {'accessToken': 'token', 'user': {}});
          when(() => mockContext.mounted).thenReturn(false);

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.loginWithPassword(
            mockContext,
            testEmail,
            testPassword,
          );
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateSuccess>()]);
          verify(
            () => mockAuthService.login(testEmail, testPassword, testToken),
          ).called(1);

          await subscription.cancel();
        },
      );

      test(
        'should emit error state when login fails with null result',
        () async {
          when(
            () => mockAuthService.login(testEmail, testPassword, testToken),
          ).thenAnswer((_) async => null);

          final states = <AuthState>[];
          final subscription = notifier.stream.listen(
            (state) => states.add(state),
          );

          await notifier.loginWithPassword(
            mockContext,
            testEmail,
            testPassword,
          );
          await Future.delayed(Duration.zero);

          expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
          expect(
            (states.last as AuthStateError).message,
            'Email ou mot de passe incorrect',
          );

          await subscription.cancel();
        },
      );

      test('should emit error state when login throws exception', () async {
        when(
          () => mockAuthService.login(testEmail, testPassword, testToken),
        ).thenThrow(Exception('Login error'));

        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.loginWithPassword(mockContext, testEmail, testPassword);
        await Future.delayed(Duration.zero);

        expect(states, [isA<AuthStateLoading>(), isA<AuthStateError>()]);
        expect((states.last as AuthStateError).message, contains('Erreur:'));

        await subscription.cancel();
      });
    });

    group('State Transitions', () {
      test('should transition from initial to loading to success', () async {
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => true);
        when(() => mockContext.mounted).thenReturn(false);

        expect(notifier.state, isA<AuthStateInitial>());

        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.signInWithGoogle(mockContext);
        await Future.delayed(Duration.zero);

        expect(states[0], isA<AuthStateLoading>());
        expect(states[1], isA<AuthStateSuccess>());

        await subscription.cancel();
      });

      test('should transition from loading to error on failure', () async {
        when(
          () => mockAuthService.signInWithApple(),
        ).thenAnswer((_) async => false);

        final states = <AuthState>[];
        final subscription = notifier.stream.listen(
          (state) => states.add(state),
        );

        await notifier.signInWithApple(mockContext);
        await Future.delayed(Duration.zero);

        expect(states[0], isA<AuthStateLoading>());
        expect(states[1], isA<AuthStateError>());

        await subscription.cancel();
      });

      test('should maintain error state until next action', () async {
        when(
          () => mockAuthService.checkEmailExists(any(), any()),
        ).thenThrow(Exception('Error'));

        await notifier.checkEmail(mockContext, 'test@example.com');

        expect(notifier.state, isA<AuthStateError>());

        // State should remain error until next action
        await Future.delayed(const Duration(milliseconds: 100));
        expect(notifier.state, isA<AuthStateError>());
      });
    });

    group('Email Validation', () {
      test('should accept valid email formats', () async {
        final validEmails = [
          'test@example.com',
          'user.name@domain.com',
          'user+tag@example.co.uk',
          'user_123@test-domain.org',
        ];

        for (final email in validEmails) {
          when(
            () => mockAuthService.checkEmailExists(email, 'test_token'),
          ).thenAnswer((_) async => true);

          await notifier.checkEmail(mockContext, email);

          // Should not emit error for valid email
          expect(notifier.state, isNot(isA<AuthStateError>()));

          // Reset state
          notifier = AuthStateNotifier(
            authService: mockAuthService,
            checkNetworkService: mockCheckNetworkService,
          );
        }
      });

      test('should reject invalid email formats', () async {
        final invalidEmails = [
          'invalid',
          '@example.com',
          'user@',
          'user domain@example.com',
          'user..name@example.com',
        ];

        for (final email in invalidEmails) {
          notifier = AuthStateNotifier(
            authService: mockAuthService,
            checkNetworkService: mockCheckNetworkService,
          );

          // Configure mock even for invalid emails (in case validation logic changes)
          when(
            () => mockAuthService.checkEmailExists(any(), any()),
          ).thenAnswer((_) async => false);

          await notifier.checkEmail(mockContext, email);

          expect(notifier.state, isA<AuthStateError>());
          expect(
            (notifier.state as AuthStateError).message,
            'Veuillez entrer une adresse email valide',
          );
        }
      });
    });
  });
}
