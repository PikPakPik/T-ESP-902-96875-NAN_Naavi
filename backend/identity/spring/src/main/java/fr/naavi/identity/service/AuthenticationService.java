package fr.naavi.identity.service;

import fr.naavi.core.utils.RequestUtils;
import fr.naavi.identity.dto.output.AuthenticationDTO;
import fr.naavi.identity.entity.Session;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.SessionRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class AuthenticationService {
    private static final Logger log = LoggerFactory.getLogger(AuthenticationService.class);

    private final JwtService jwtService;
    private final SessionRepository sessionRepository;

    /**
     * Constructs a UserService
     */
    @Autowired
    public AuthenticationService(
            JwtService jwtService,
            SessionRepository sessionRepository
    ) {
        this.jwtService = jwtService;
        this.sessionRepository = sessionRepository;
    }

    /**
     * Generates an access token for the user.
     *
     * @return a map containing the access token and its unique identifier
     */
    public Map<String, String> accessToken() {
        String uuid = UUID.randomUUID().toString();
        Instant now = Instant.now();
        Instant expiration = now.plus(1, ChronoUnit.DAYS);
        Map<String, Object> claims = new HashMap<>();
        claims.put("type", "session");
        claims.put("sessId", uuid);

        JwtBuilder jwt = Jwts.builder()
                .claims(claims)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiration));

        return Map.of(
                "token", this.jwtService.signJwt(jwt),
                "sessId", uuid
        );
    }

    /**
     * Generates a refresh token for the user.
     *
     * @return a map containing the refresh token and its unique identifier
     */
    public Map<String, String> refreshToken() {
        String uuid = UUID.randomUUID().toString();
        Instant now = Instant.now();
        Instant expiration = now.plus(7, ChronoUnit.DAYS);

        Map<String, Object> claims = new HashMap<>();
        claims.put("type", "refresh");
        claims.put("sessId", uuid);

        JwtBuilder jwt = Jwts.builder()
                .claims(claims)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiration));

        return Map.of(
                "token", this.jwtService.signJwt(jwt),
                "sessId", uuid
        );
    }

    /**
     * Creates a new session for the user with the provided UUID.
     *
     * @param user the user for whom the session is being created
     * @param accessTokenUuid the unique identifier for the session
     * @param refreshTokenUuid the unique identifier for the refresh token
     */
    public void createSession(User user, String accessTokenUuid, String refreshTokenUuid) {
        Session session = new Session();

        session.setUser(user);
        session.setAccessToken(accessTokenUuid);
        session.setRefreshToken(refreshTokenUuid);
        session.setClientIp(RequestUtils.getClientIpAddress());
        session.setUserAgent(RequestUtils.getUserAgent());

        this.sessionRepository.save(session);
    }

    /**
     * Renews the session using the provided refresh token.
     *
     * @param token the refresh token to renew the session
     * @return an AuthenticationDTO containing the new access and refresh tokens
     */
    public AuthenticationDTO renewSession(String token) {
        try {
            Claims claims = this.jwtService.verifyJwt(token);
            String sessId = claims.get("sessId", String.class);

            Optional<Session> session = this.sessionRepository.findByRefreshToken(sessId);

            if (session.isEmpty()) {
                throw new IllegalArgumentException("Session not found for the provided refresh token.");
            }

            if (session.get().getRefreshTokenExpiredAt().isBefore(LocalDateTime.now())) {
                throw new IllegalArgumentException("Refresh token is expired.");
            }

            Map<String, String> accessToken = this.accessToken();
            Map<String, String> refreshToken = this.refreshToken();

            this.createSession(session.get().getUser(), accessToken.get("sessId"), refreshToken.get("sessId"));

            this.sessionRepository.delete(session.get());

            return new AuthenticationDTO(accessToken.get("token"), refreshToken.get("token"));
        } catch (Exception e) {
            log.error("Error renewing session: {}", e.getMessage());
            throw new IllegalArgumentException("Refresh token is missing or invalid.", e);
        }
    }
}
