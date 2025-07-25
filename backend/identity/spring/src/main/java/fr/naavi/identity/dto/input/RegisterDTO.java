package fr.naavi.identity.dto.input;

import fr.naavi.core.validator.EqualTo;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

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
    private String password;

    @NotBlank
    private String confirmPassword;

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
}
