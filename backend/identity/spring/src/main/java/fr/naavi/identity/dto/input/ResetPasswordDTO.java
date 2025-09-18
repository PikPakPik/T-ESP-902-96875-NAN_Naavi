package fr.naavi.identity.dto.input;

import fr.naavi.core.validator.EqualTo;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@EqualTo(sourceProperty = "confirmPassword", targetProperty = "password")
public class ResetPasswordDTO {
    @NotBlank
    private String token;

    @NotBlank
    @Size(min = 8)
    private String password;

    @NotBlank
    @Size(min = 8)
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
