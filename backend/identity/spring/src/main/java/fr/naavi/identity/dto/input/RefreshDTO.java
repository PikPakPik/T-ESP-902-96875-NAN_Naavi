package fr.naavi.identity.dto.input;

import jakarta.validation.constraints.NotBlank;

public class RefreshDTO {
    @NotBlank
    private String token;

    public String getToken() {
        return token;
    }
}
