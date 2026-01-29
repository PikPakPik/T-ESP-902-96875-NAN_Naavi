import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/presentation/auth/state/AuthState.dart';

void main() {
  group('AuthState', () {
    test('AuthStateInitial should be instance of AuthState', () {
      const state = AuthStateInitial();
      expect(state, isA<AuthState>());
    });

    test('AuthStateLoading should be instance of AuthState', () {
      const state = AuthStateLoading();
      expect(state, isA<AuthState>());
    });

    test('AuthStateSuccess should be instance of AuthState', () {
      const state = AuthStateSuccess();
      expect(state, isA<AuthState>());
    });

    test('AuthStateError should be instance of AuthState', () {
      const state = AuthStateError('Test error message');
      expect(state, isA<AuthState>());
      expect(state.message, equals('Test error message'));
    });

    test('AuthStateEmailSent should store email', () {
      const state = AuthStateEmailSent('test@example.com');
      expect(state, isA<AuthState>());
      expect(state.email, equals('test@example.com'));
    });

    test('AuthStateEmailSent with different emails', () {
      const state1 = AuthStateEmailSent('user1@example.com');
      const state2 = AuthStateEmailSent('user2@example.com');

      expect(state1.email, 'user1@example.com');
      expect(state2.email, 'user2@example.com');
      expect(state1.email, isNot(state2.email));
    });

    test('AuthStateEmailChecked should store email and emailExists', () {
      const state = AuthStateEmailChecked(
        email: 'test@example.com',
        emailExists: true,
      );
      expect(state, isA<AuthState>());
      expect(state.email, equals('test@example.com'));
      expect(state.emailExists, isTrue);
    });

    test('AuthStateEmailChecked should handle email not existing', () {
      const state = AuthStateEmailChecked(
        email: 'new@example.com',
        emailExists: false,
      );
      expect(state.emailExists, isFalse);
    });

    test('AuthStateEmailChecked with different values', () {
      const state1 = AuthStateEmailChecked(
        email: 'a@example.com',
        emailExists: true,
      );
      const state2 = AuthStateEmailChecked(
        email: 'b@example.com',
        emailExists: false,
      );

      expect(state1.email, 'a@example.com');
      expect(state1.emailExists, true);
      expect(state2.email, 'b@example.com');
      expect(state2.emailExists, false);
    });

    test('AuthStatePasswordRequired should store email', () {
      const state = AuthStatePasswordRequired('test@example.com');
      expect(state, isA<AuthState>());
      expect(state.email, equals('test@example.com'));
    });

    test('AuthStateCreatePassword should store email', () {
      const state = AuthStateCreatePassword('test@example.com');
      expect(state, isA<AuthState>());
      expect(state.email, equals('test@example.com'));
    });
  });
}
