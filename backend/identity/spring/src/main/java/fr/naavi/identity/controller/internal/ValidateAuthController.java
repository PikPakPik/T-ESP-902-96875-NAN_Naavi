package fr.naavi.identity.controller.internal;

import fr.naavi.core.enums.JwtEnum;
import fr.naavi.core.service.JwtService;
import fr.naavi.identity.abstraction.AbstractController;
import fr.naavi.identity.entity.Session;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.SessionRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import io.swagger.v3.oas.annotations.Hidden;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/internal")
public class ValidateAuthController extends AbstractController {
    private final JwtService jwtService;
    private final SessionRepository sessionRepository;

    /**
     * Constructor for ValidateAuthController.
     */
    @Autowired
    public ValidateAuthController(
            JwtService jwtService,
            SessionRepository sessionRepository
    ) {
        this.jwtService = jwtService;
        this.sessionRepository = sessionRepository;
    }

    /**
     * Endpoint for health check.
     * This endpoint is used to verify if the service is running.
     *
     * @return a map containing the health status and timestamp
     */
    @GetMapping("/validate-auth")
    @Hidden
    public ResponseEntity<Void> validateAuth(HttpServletResponse response) {
        String authorizationValue = this.getCurrentRequest().getHeader("Authorization");
        String token = (authorizationValue != null && authorizationValue.startsWith("Bearer "))
                ? authorizationValue.substring("Bearer ".length())
                : authorizationValue;

        if (token == null || token.isEmpty()) {
            response.setHeader("X-User", this.generateGuestToken());
            return ResponseEntity.noContent().build();
        }

        try {
            Claims claims = this.jwtService.verifyJwt(token, JwtEnum.AUTH);
            String sessId = claims.get("sessId", String.class);

            Optional<Session> session = this.sessionRepository.findByAccessToken(sessId);

            if (session.isEmpty()) {
                throw new Exception("Invalid session");
            }

            if (session.get().getAccessTokenExpiredAt().isBefore(LocalDateTime.now())) {
                throw new Exception("Session expired");
            }

            response.setHeader("X-User", this.generateLoggedToken(session.get().getUser()));
        } catch (Exception e) {
            response.setHeader("X-User", this.generateGuestToken());
        }

        return ResponseEntity.noContent().build();
    }

    private String generateGuestToken() {
        Map<String, Object> newClaims = new HashMap<>();
        newClaims.put("type", "guest");
        return this.generateToken(newClaims);
    }

    private String generateLoggedToken(User user) {
        Map<String, Object> newClaims = new HashMap<>();
        newClaims.put("type", "logged");
        newClaims.put("id", user.getId());
        newClaims.put("firstname", user.getFirstname());
        newClaims.put("lastname", user.getLastname());
        newClaims.put("email", user.getEmail());
        newClaims.put("roles", user.getRoles());
        return this.generateToken(newClaims);
    }

    private String generateToken(Map<String, Object> newClaims) {
        Instant now = Instant.now();
        Instant expiration = now.plus(30, ChronoUnit.MINUTES);

        JwtBuilder jwt = Jwts.builder()
                .claims(newClaims)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiration));

        return this.jwtService.signJwt(jwt, JwtEnum.EXCHANGE);
    }
}