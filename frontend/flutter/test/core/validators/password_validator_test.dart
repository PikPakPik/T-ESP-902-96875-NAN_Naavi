import 'package:flutter_test/flutter_test.dart';
import 'package:naavi/core/validators/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    group('validate', () {
      test('should return all false for empty password', () {
        final result = PasswordValidator.validate('');

        expect(result.minLength, false);
        expect(result.hasUppercase, false);
        expect(result.hasLowercase, false);
        expect(result.hasDigit, false);
        expect(result.hasSpecialChar, false);
        expect(result.isValid, false);
      });

      test('should return all true for valid strong password', () {
        final result = PasswordValidator.validate('MyPassword1!');

        expect(result.minLength, true);
        expect(result.hasUppercase, true);
        expect(result.hasLowercase, true);
        expect(result.hasDigit, true);
        expect(result.hasSpecialChar, true);
        expect(result.isValid, true);
      });

      test('should detect missing uppercase', () {
        final result = PasswordValidator.validate('mypassword1!');

        expect(result.hasUppercase, false);
        expect(result.isValid, false);
      });

      test('should detect missing lowercase', () {
        final result = PasswordValidator.validate('MYPASSWORD1!');

        expect(result.hasLowercase, false);
        expect(result.isValid, false);
      });

      test('should detect missing digit', () {
        final result = PasswordValidator.validate('MyPassword!!');

        expect(result.hasDigit, false);
        expect(result.isValid, false);
      });

      test('should detect missing special character', () {
        final result = PasswordValidator.validate('MyPassword12');

        expect(result.hasSpecialChar, false);
        expect(result.isValid, false);
      });

      test('should detect password too short (less than 12 chars)', () {
        final result = PasswordValidator.validate('MyPass1!');

        expect(result.minLength, false);
        expect(result.isValid, false);
      });

      test('should accept password with exactly 12 characters', () {
        final result = PasswordValidator.validate('MyPasswor1!a');

        expect(result.minLength, true);
      });

      test('should accept all valid special characters', () {
        final specialChars = ['@', r'$', '!', '%', '*', '?', '&'];

        for (final char in specialChars) {
          final result = PasswordValidator.validate('MyPassword1$char');
          expect(
            result.hasSpecialChar,
            true,
            reason: 'Should accept special char: $char',
          );
        }
      });
    });

    group('isValid', () {
      test('should return true for valid password', () {
        expect(PasswordValidator.isValid('MyPassword1!'), true);
      });

      test('should return false for invalid password', () {
        expect(PasswordValidator.isValid('weak'), false);
      });
    });

    group('getValidationMessage', () {
      test('should return null for valid password', () {
        final message = PasswordValidator.getValidationMessage('MyPassword1!');
        expect(message, null);
      });

      test('should return message listing all missing requirements', () {
        final message = PasswordValidator.getValidationMessage('');

        expect(message, isNotNull);
        expect(message, contains('12 caractères minimum'));
        expect(message, contains('une majuscule'));
        expect(message, contains('une minuscule'));
        expect(message, contains('un chiffre'));
        expect(message, contains('un caractère spécial'));
      });

      test('should only list missing requirements', () {
        final message = PasswordValidator.getValidationMessage('mypassword12');

        expect(message, isNotNull);
        expect(message, contains('une majuscule'));
        expect(message, contains('un caractère spécial'));
        expect(message, isNot(contains('une minuscule')));
        expect(message, isNot(contains('un chiffre')));
      });
    });
  });
}
