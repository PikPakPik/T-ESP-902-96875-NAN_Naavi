package fr.naavi.identity.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.identity.enums.StatusEnum;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class ConfigurationController {
    /**
     * Endpoint for retrieving the service configuration.
     *
     * @return A map containing available roles and permissions.
     */
    @Operation(
            summary = "Récupération des configurations du service",
            description = "Permet de récupérer les configurations disponibles dans le service d'identité",
            tags = {"Service"}
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Configuration récupérée avec succès",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "  \"roles\": ["
                                            + "    \"ROLE_USER\""
                                            + "   ],\n"
                                            + "  \"permissions\": ["
                                            + "    \"USER_READ\""
                                            + "   ],\n"
                                            + "  \"user_status\": ["
                                            + "    \"UNVERIFIED\""
                                            + "  ]\n"
                                            + "}"
                            )
                    )
            )
    })
    @AuthenticationNotRequired
    @GetMapping("/configurations")
    public Map<String, Object> configuration() {
        return Map.of(
                "roles", RoleEnum.values(),
                "permissions", PermissionEnum.values(),
                "user_status", StatusEnum.values()
        );
    }
}
