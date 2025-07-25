package fr.naavi.identity.controller;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthcheckController {
    /**
     * Endpoint for health check.
     * This endpoint is used to verify if the service is running.
     *
     * @return a map containing the health status and timestamp
     */
    @AuthenticationNotRequired
    @GetMapping("/healthcheck")
    public Map<String, Object> healthCheck() {
        return Map.of(
                "service", "identity",
                "i18nKey", "healthcheck.success",
                "message", "Service is running",
                "timestamp", System.currentTimeMillis()
        );
    }
}