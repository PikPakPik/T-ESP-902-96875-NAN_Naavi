package fr.naavi.identity.dto.output;

public class AuthenticationDTO {
    private final String accessToken;
    private String refreshToken;

    /**
     * Constructs for AuthenticationDto with access token only.
     */
    public AuthenticationDTO(String accessToken) {
        this.accessToken = accessToken;
    }

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
