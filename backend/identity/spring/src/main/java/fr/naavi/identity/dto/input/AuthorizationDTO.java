package fr.naavi.identity.dto.input;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public class AuthorizationDTO {
    @NotBlank
    @NotNull
    @NotEmpty
    private String authorizationToken;

    @NotBlank
    @NotNull
    @NotEmpty
    private String token;

    public String getAuthorizationToken() {
        return authorizationToken;
    }

    public String getToken() {
        return token;
    }
}
