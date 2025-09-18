package fr.naavi.identity.dto.output;

import io.swagger.v3.oas.annotations.media.Schema;

public class AuthenticationDTO {
    @Schema(description = "Jeton d'authentification", example = "eyJhbGciOiJIUzI1NiIsInR5cCI6...")
    private final String accessToken;

    @Schema(description = "Jeton de re-authentification", example = "eyJhbGciOiJIUzI1NiIsInR5cCI6...")
    private final String refreshToken;

    /**
     * Constructs for AuthenticationDto with access and refresh tokens.
     */
    public AuthenticationDTO(String accessToken, String refreshToken) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }

    public String getAccessToken() {
        return accessToken;
    }

    public String getRefreshToken() {
        return refreshToken;
    }
}
