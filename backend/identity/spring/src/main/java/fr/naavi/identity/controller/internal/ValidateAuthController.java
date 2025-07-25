package fr.naavi.identity.controller.internal;

import fr.naavi.identity.abstraction.AbstractController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/internal")
public class ValidateAuthController extends AbstractController {
    /**
     * Endpoint for health check.
     * This endpoint is used to verify if the service is running.
     *
     * @return a map containing the health status and timestamp
     */
    @GetMapping("/validate-auth")
    public Map<String, Object> validateAuth() {
        String authorizationValue = this.getCurrentRequest().getHeader("Authorization");
        String token = (authorizationValue != null && authorizationValue.startsWith("Bearer "))
                ? authorizationValue.substring("Bearer ".length())
                : authorizationValue;

        if (token != null && !token.isEmpty()) {
            return Map.of(
                    "type", "logged"
            );
        }

        return Map.of(
                "type", "guest"
        );
    }
}