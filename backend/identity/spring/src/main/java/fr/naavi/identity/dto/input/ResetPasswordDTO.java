package fr.naavi.identity.dto.input;

import fr.naavi.core.validator.EqualTo;
import jakarta.validation.constraints.NotBlank;

@EqualTo(sourceProperty = "confirmPassword", targetProperty = "password")
public class ResetPasswordDTO {
    @NotBlank
    private String token;

    @NotBlank
    private String password;

    @NotBlank
    private String confirmPassword;

    public String getToken() {
        return token;
    }

    public String getPassword() {
        return password;
    }

    public String getConfirmPassword() {
        return confirmPassword;
    }
}
