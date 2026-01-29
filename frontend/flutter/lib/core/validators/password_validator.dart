/// Result of password validation with detailed requirements check
class PasswordValidationResult {
  final bool minLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordValidationResult({
    required this.minLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  /// Returns true if all requirements are met
  bool get isValid =>
      minLength && hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
}

/// Validates password strength requirements:
/// - At least 12 characters
/// - At least 1 uppercase letter
/// - At least 1 lowercase letter
/// - At least 1 digit
/// - At least 1 special character (@$!%*?&)
class PasswordValidator {
  static const int minPasswordLength = 12;
  static const String specialChars = r'@$!%*?&';

  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[@$!%*?&]');

  /// Validates a password and returns detailed results for each requirement
  static PasswordValidationResult validate(String password) {
    return PasswordValidationResult(
      minLength: password.length >= minPasswordLength,
      hasUppercase: _uppercaseRegex.hasMatch(password),
      hasLowercase: _lowercaseRegex.hasMatch(password),
      hasDigit: _digitRegex.hasMatch(password),
      hasSpecialChar: _specialCharRegex.hasMatch(password),
    );
  }

  /// Returns a human-readable error message listing missing requirements
  /// Returns null if password is valid
  static String? getValidationMessage(String password) {
    final result = validate(password);

    if (result.isValid) {
      return null;
    }

    final List<String> missing = [];

    if (!result.minLength) {
      missing.add('$minPasswordLength caractères minimum');
    }
    if (!result.hasUppercase) {
      missing.add('une majuscule');
    }
    if (!result.hasLowercase) {
      missing.add('une minuscule');
    }
    if (!result.hasDigit) {
      missing.add('un chiffre');
    }
    if (!result.hasSpecialChar) {
      missing.add('un caractère spécial ($specialChars)');
    }

    return 'Le mot de passe doit contenir : ${missing.join(', ')}';
  }

  /// Simple validation that returns true if password meets all requirements
  static bool isValid(String password) {
    return validate(password).isValid;
  }
}
