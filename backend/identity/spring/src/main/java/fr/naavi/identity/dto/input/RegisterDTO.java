package fr.naavi.identity.dto.input;

import fr.naavi.core.validator.EqualTo;
import fr.naavi.identity.validator.StrongPassword;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

@EqualTo(sourceProperty = "confirmPassword", targetProperty = "password")
public class RegisterDTO {
    @NotBlank
    private String firstname;

    @NotBlank
    private String lastname;

    @NotBlank
    @Email
    private String email;

    @NotBlank
    @StrongPassword
    private String password;

    @NotBlank
    private String confirmPassword;

    @NotBlank
    @NotNull
    @NotEmpty
    private String token;

    public String getFirstname() {
        return firstname;
    }

    public String getLastname() {
        return lastname;
    }

    public String getEmail() {
        return email;
    }

    public String getPassword() {
        return password;
    }

    public String getConfirmPassword() {
        return confirmPassword;
    }

    public String getToken() {
        return token;
    }
}
