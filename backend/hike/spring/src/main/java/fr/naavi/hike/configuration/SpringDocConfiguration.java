package fr.naavi.hike.configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

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
     * @return OpenAPI instance with configured server URL and title
     */
    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .addServersItem(new Server().url(swaggerUiServerUrl))
                .info(new Info().title(swaggerUiTitle));
    }
}
