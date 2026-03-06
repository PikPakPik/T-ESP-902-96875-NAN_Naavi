package fr.naavi.hike.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.StatusEnum;
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
                                            + "  \"difficulties\": ["
                                            + "    \"EASY\""
                                            + "   ],\n"
                                            + "  \"status\": ["
                                            + "    \"DRAFT\""
                                            + "  ],\n"
                                            + "  \"sources\": ["
                                            + "    \"OFFICIAL\""
                                            + "  ],\n"
                                            + "  \"point_of_interest_categories\": ["
                                            + "    \"MUST_SEE_SPOT\""
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
                "difficulties", DifficultyEnum.values(),
                "status", StatusEnum.values(),
                "sources", SourceEnum.values(),
                "point_of_interest_categories", PointOfInterestCategoryEnum.values()
        );
    }
}
