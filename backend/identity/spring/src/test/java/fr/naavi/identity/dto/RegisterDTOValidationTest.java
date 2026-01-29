package fr.naavi.identity.dto;

import fr.naavi.identity.dto.input.RegisterDTO;
import fr.naavi.identity.util.DtoFactory;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class RegisterDTOValidationTest {

    private Validator validator;

    @BeforeEach
    void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    void shouldPassValidation_WhenPasswordMeetsAllRequirements() throws Exception {
        RegisterDTO dto = DtoFactory.createDto(RegisterDTO.class, Map.of(
                "firstname", "John",
                "lastname", "Doe",
                "email", "john.doe@example.com",
                "password", "MyPassword1!",
                "confirmPassword", "MyPassword1!",
                "token", "turnstile_token"
        ));

        Set<ConstraintViolation<RegisterDTO>> violations = validator.validate(dto);

        assertThat(violations).isEmpty();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "short1!",           // Too short
            "nouppercase1!aaa",  // No uppercase
            "NOLOWERCASE1!AAA",  // No lowercase
            "NoDigitsHere!aa",   // No digit
            "NoSpecialChar1a"    // No special character
    })
    void shouldFailValidation_WhenPasswordDoesNotMeetRequirements(String weakPassword) throws Exception {
        RegisterDTO dto = DtoFactory.createDto(RegisterDTO.class, Map.of(
                "firstname", "John",
                "lastname", "Doe",
                "email", "john.doe@example.com",
                "password", weakPassword,
                "confirmPassword", weakPassword,
                "token", "turnstile_token"
        ));

        Set<ConstraintViolation<RegisterDTO>> violations = validator.validate(dto);

        assertThat(violations)
                .isNotEmpty()
                .anyMatch(v -> v.getPropertyPath().toString().equals("password"));
    }

    @Test
    void shouldFailValidation_WhenPasswordIsTooShort() throws Exception {
        RegisterDTO dto = DtoFactory.createDto(RegisterDTO.class, Map.of(
                "firstname", "John",
                "lastname", "Doe",
                "email", "john.doe@example.com",
                "password", "Short1!",
                "confirmPassword", "Short1!",
                "token", "turnstile_token"
        ));

        Set<ConstraintViolation<RegisterDTO>> violations = validator.validate(dto);

        assertThat(violations)
                .isNotEmpty()
                .anyMatch(v -> v.getPropertyPath().toString().equals("password"));
    }

    @Test
    void shouldHaveCorrectErrorMessage_WhenPasswordIsWeak() throws Exception {
        RegisterDTO dto = DtoFactory.createDto(RegisterDTO.class, Map.of(
                "firstname", "John",
                "lastname", "Doe",
                "email", "john.doe@example.com",
                "password", "weak",
                "confirmPassword", "weak",
                "token", "turnstile_token"
        ));

        Set<ConstraintViolation<RegisterDTO>> violations = validator.validate(dto);

        assertThat(violations)
                .anyMatch(v -> v.getMessage().contains("12 caractères"));
    }
}
