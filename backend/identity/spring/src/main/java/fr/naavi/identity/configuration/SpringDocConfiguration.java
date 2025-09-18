package fr.naavi.identity.configuration;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Map;

@Configuration
public class SpringDocConfiguration {
    @Value("${springdoc.swagger-ui.server-url}")
    private String swaggerUiServerUrl;

    @Value("${springdoc.swagger-ui.title}")
    private String swaggerUiTitle;

    /**
     * Configuration for OpenAPI documentation.
     * This bean sets the server URL and title for the Swagger UI.
     *
     * @return OpenAPI instance with a configured server URL and title
     */
    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .addServersItem(new Server().url(swaggerUiServerUrl))
                .info(new Info().title(swaggerUiTitle))
                .components(new Components()
                        .addResponses("UnauthorizedError",
                                new ApiResponse()
                                        .description("Non authentifié. L'utilisateur doit être connecté.")
                                        .content(new Content()
                                                .addMediaType("application/json",
                                                        new MediaType()
                                                                .example(
                                                                        Map.of(
                                                                                "message", "Unauthorized access. You must be authenticated to access this resource."
                                                                        )
                                                                )
                                                )
                                        )
                        )
                        .addResponses("AccessDeniedError",
                                new ApiResponse()
                                        .description("Accès refusé. L'utilisateur ne disposent pas des droits nécessaire pour cette action.")
                                        .content(new Content()
                                                .addMediaType("application/json",
                                                        new MediaType()
                                                                .example(
                                                                        Map.of(
                                                                                "message", "Access denied. You do not have the necessary permissions to access this resource"
                                                                        )
                                                                )
                                                )
                                        )
                        )
                        .addResponses("ValidationError",
                                new ApiResponse()
                                        .description("Erreur de validation. Les données envoyées ne respectent pas les contraintes attendues.")
                                        .content(new Content()
                                                .addMediaType("application/json",
                                                        new MediaType()
                                                                .example(
                                                                        Map.of(
                                                                                "i18nKey", "validation.failed",
                                                                                "message", "Validation failed",
                                                                                "extra", Map.of(
                                                                                        "key", "message"
                                                                                )
                                                                        )
                                                                )
                                                )
                                        )
                        )
                );
    }
}
