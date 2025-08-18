package fr.naavi.identity.controller;

import fr.naavi.identity.abstraction.AbstractController;
import fr.naavi.identity.entity.User;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(
        name = "Utilisateur",
        description = "Points d'accès pour récupérer les informations de l'utilisateur connecté"
)
@SecurityScheme(
        type = SecuritySchemeType.HTTP,
        name = "bearerAuth",
        scheme = "bearer",
        bearerFormat = "JWT",
        paramName = "Authorization: Bearer <token>",
        in = SecuritySchemeIn.HEADER
)
@RestController
public class UserController extends AbstractController {
    /**
     * Endpoint to retrieve the current authenticated user.
     * This endpoint returns the details of the user currently authenticated in the session.
     *
     * @return the User object representing the current user
     */
    @Operation(
            summary = "Récupérer l'utilisateur connecté",
            description = "Retourne les informations de l'utilisateur actuellement authentifié. Requiert une authentification.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Utilisateur authentifié retourné avec succès.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = User.class,
                                    example = "{\n"
                                            + "  \"firstname\": \"Jean\",\n"
                                            + "  \"lastname\": \"Dupont\",\n"
                                            + "  \"email\": \"user@example.com\",\n"
                                            + "  \"roles\": [\"ROLE_USER\"],\n"
                                            + "  \"status\": \"ACTIVE\",\n"
                                            + "  \"createdAt\": \"2024-06-01T12:00:00\",\n"
                                            + "  \"updatedAt\": \"2024-06-10T15:30:00\"\n"
                                            + "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Non authentifié. L'utilisateur doit être connecté.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "  \"message\": \"Unauthorized access. You must be authenticated to access this resource.\"\n"
                                            + "}"
                            )
                    )
            )
    })
    @GetMapping("/user")
    public User user() {
        return this.getUser();
    }
}