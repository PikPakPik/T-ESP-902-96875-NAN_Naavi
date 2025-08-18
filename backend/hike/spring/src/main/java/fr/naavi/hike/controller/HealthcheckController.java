package fr.naavi.hike.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Tag(
        name = "Healthcheck",
        description = "Points d'accès pour vérifier l'état de santé du service de randonnée"
)
@RestController
public class HealthcheckController {
    /**
     * Endpoint for health check.
     * This endpoint is used to verify if the service is running.
     *
     * @return a map containing the health status and timestamp
     */
    @Operation(
            summary = "Vérification de l'état du service",
            description = "Permet de vérifier si le service de randonnée est opérationnel."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Service opérationnel.",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(
                                    example = "{\n"
                                            + "  \"service\": \"hike\",\n"
                                            + "  \"i18nKey\": \"healthcheck.success\",\n"
                                            + "  \"message\": \"Service is running\",\n"
                                            + "  \"timestamp\": 1710000000000\n"
                                            + "}"
                            )
                    )
            )
    })
    @AuthenticationNotRequired
    @GetMapping("/healthcheck")
    public Map<String, Object> healthCheck() {
        return Map.of(
                "service", "hike",
                "i18nKey", "healthcheck.success",
                "message", "Service is running",
                "timestamp", System.currentTimeMillis()
        );
    }
}