package fr.naavi.identity.dto.input;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public class ForgotPasswordDTO {
    @NotBlank
    @Email
    private String email;

    @NotBlank
    @NotNull
    @NotEmpty
    private String token;

    public String getEmail() {
        return email;
    }

    public String getToken() {
        return token;
    }
}
