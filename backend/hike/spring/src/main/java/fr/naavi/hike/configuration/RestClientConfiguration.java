package fr.naavi.hike.configuration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfiguration {

    /**
     * Nominatim RestClient. Uses RestClient.builder() directly; trace propagation
     * for internal service-to-service calls is handled by RestTemplateBuilder
     * (identity, naavi-core) and HTTP server instrumentation.
     */
    @Bean
    public RestClient nominatimRestClient() {
        return RestClient.builder()
                .baseUrl("https://nominatim.openstreetmap.org")
                .defaultHeader("User-Agent", "Naavi-Trails/1.0")
                .build();
    }
}