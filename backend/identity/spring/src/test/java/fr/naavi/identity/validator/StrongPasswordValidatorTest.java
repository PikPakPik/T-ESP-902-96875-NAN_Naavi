package fr.naavi.identity.validator;

import fr.naavi.identity.validator.StrongPasswordValidator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

class StrongPasswordValidatorTest {

    private StrongPasswordValidator validator;

    @BeforeEach
    void setUp() {
        validator = new StrongPasswordValidator();
    }

    @Test
    void shouldReturnTrue_WhenPasswordIsNull() {
        // Null passwords should be handled by @NotBlank
        boolean result = validator.isValid(null, null);
        assertThat(result).isTrue();
    }

    @Test
    void shouldReturnTrue_WhenPasswordIsEmpty() {
        // Empty passwords should be handled by @NotBlank
        boolean result = validator.isValid("", null);
        assertThat(result).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "MyPassword1!",      // Valid: 12 chars, uppercase, lowercase, digit, special
            "Azertyuiop1!",      // Valid: exact 12 chars
            "SecurePass123@",    // Valid: 14 chars
            "Test$Password1",    // Valid with $ special char
            "Valid!Pass123",     // Valid with !
            "MyP@ssword12",      // Valid with @
            "Password1%ab",      // Valid with %
            "StrongPwd1*a",      // Valid with *
            "MyPasswor1?a",      // Valid with ?
            "Abcdefgh1&ab"       // Valid with &
    })
    void shouldReturnTrue_WhenPasswordMeetsAllRequirements(String password) {
        boolean result = validator.isValid(password, null);
        assertThat(result)
                .as("Password '%s' should be valid", password)
                .isTrue();
    }

    @Test
    void shouldReturnFalse_WhenPasswordIsTooShort() {
        // Only 11 characters
        boolean result = validator.isValid("MyPass1!abc", null);
        assertThat(result).isFalse();
    }

    @Test
    void shouldReturnFalse_WhenPasswordHasNoUppercase() {
        boolean result = validator.isValid("mypassword1!", null);
        assertThat(result).isFalse();
    }

    @Test
    void shouldReturnFalse_WhenPasswordHasNoLowercase() {
        boolean result = validator.isValid("MYPASSWORD1!", null);
        assertThat(result).isFalse();
    }

    @Test
    void shouldReturnFalse_WhenPasswordHasNoDigit() {
        boolean result = validator.isValid("MyPasswordAb!", null);
        assertThat(result).isFalse();
    }

    @Test
    void shouldReturnFalse_WhenPasswordHasNoSpecialChar() {
        boolean result = validator.isValid("MyPassword123", null);
        assertThat(result).isFalse();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "short1!",           // Too short
            "nouppercase1!aaa",  // No uppercase
            "NOLOWERCASE1!AAA",  // No lowercase
            "NoDigitsHere!aa",   // No digit
            "NoSpecialChar1a",   // No special character
            "12345678901!",      // No letters
            "abcdefghij1!",      // No uppercase
            "ABCDEFGHIJ1!",      // No lowercase
    })
    void shouldReturnFalse_WhenPasswordDoesNotMeetRequirements(String password) {
        boolean result = validator.isValid(password, null);
        assertThat(result)
                .as("Password '%s' should be invalid", password)
                .isFalse();
    }

    @Test
    void shouldAcceptExactly12Characters() {
        // Exactly 12 characters with all requirements
        boolean result = validator.isValid("Abcdefgh1!ab", null);
        assertThat(result).isTrue();
    }

    @Test
    void shouldRejectPasswordWith11Characters() {
        // 11 characters - one short
        boolean result = validator.isValid("Abcdefgh1!a", null);
        assertThat(result).isFalse();
    }
}
