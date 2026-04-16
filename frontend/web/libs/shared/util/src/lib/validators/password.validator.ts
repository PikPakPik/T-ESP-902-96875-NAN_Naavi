import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

/**
 * Password validation requirements
 */
export interface PasswordValidationResult {
  minLength: boolean;
  hasUppercase: boolean;
  hasLowercase: boolean;
  hasDigit: boolean;
  hasSpecialChar: boolean;
}

/**
 * Validates password strength requirements:
 * - At least 12 characters
 * - At least 1 uppercase letter
 * - At least 1 lowercase letter
 * - At least 1 digit
 * - At least 1 special character (@$!%*?&)
 */
export function strongPasswordValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const password = control.value;

    if (!password) {
      return null; // Let required validator handle empty values
    }

    const result = validatePasswordStrength(password);

    if (
      result.minLength &&
      result.hasUppercase &&
      result.hasLowercase &&
      result.hasDigit &&
      result.hasSpecialChar
    ) {
      return null;
    }

    return { strongPassword: result };
  };
}

/**
 * Validates a password and returns detailed results for each requirement
 */
export function validatePasswordStrength(password: string): PasswordValidationResult {
  return {
    minLength: password.length >= 12,
    hasUppercase: /[A-Z]/.test(password),
    hasLowercase: /[a-z]/.test(password),
    hasDigit: /[0-9]/.test(password),
    hasSpecialChar: /[@$!%*?&]/.test(password),
  };
}

/**
 * Returns a human-readable error message for password validation
 */
export function getPasswordValidationMessage(result: PasswordValidationResult): string {
  const missing: string[] = [];

  if (!result.minLength) {
    missing.push('12 caractères minimum');
  }
  if (!result.hasUppercase) {
    missing.push('une majuscule');
  }
  if (!result.hasLowercase) {
    missing.push('une minuscule');
  }
  if (!result.hasDigit) {
    missing.push('un chiffre');
  }
  if (!result.hasSpecialChar) {
    missing.push('un caractère spécial (@$!%*?&)');
  }

  if (missing.length === 0) {
    return '';
  }

  return `Le mot de passe doit contenir : ${missing.join(', ')}`;
}
