package fr.naavi.identity.security;

import tools.jackson.databind.ObjectMapper;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.enums.JwtEnum;
import fr.naavi.core.service.JwtService;
import fr.naavi.identity.entity.Session;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.SessionRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public class JWTAuthenticationFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(JWTAuthenticationFilter.class);

    private final ObjectMapper objectMapper;
    private final SessionRepository sessionRepository;
    private final JwtService jwtService;

    /**
     * Constructs a JWTAuthenticationFilter.
     */
    public JWTAuthenticationFilter(
            ObjectMapper objectMapper,
            SessionRepository sessionRepository,
            JwtService jwtService
    ) {
        this.objectMapper = objectMapper;
        this.sessionRepository = sessionRepository;
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        try {
            String authorizationValue = request.getHeader("Authorization");
            String token = (authorizationValue != null && authorizationValue.startsWith("Bearer "))
                    ? authorizationValue.substring("Bearer ".length())
                    : authorizationValue;

            if (token != null && !token.isEmpty()) {
                Claims claims = this.jwtService.verifyJwt(token, JwtEnum.AUTH);
                String sessId = claims.get("sessId", String.class);

                Optional<Session> session = this.sessionRepository.findByAccessToken(sessId);

                if (session.isEmpty()) {
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    ApiResponseDTO apiResponseDto = new ApiResponseDTO(
                            "session.not_found_or_invalid",
                            "Session not found or invalid token"
                    );
                    response.getWriter().write(this.objectMapper.writeValueAsString(apiResponseDto));
                    return;
                }

                if (session.get().getAccessTokenExpiredAt().isBefore(LocalDateTime.now())) {
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    ApiResponseDTO apiResponseDto = new ApiResponseDTO(
                            "session.not_found_or_invalid",
                            "Session not found or invalid token"
                    );
                    response.getWriter().write(this.objectMapper.writeValueAsString(apiResponseDto));
                    return;
                }

                request.setAttribute("sessId", sessId);

                Collection<GrantedAuthority> authorities = getAuthorities(session.get().getUser());
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        session.get().getUser(),
                        null,
                        authorities
                );
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (JwtException e) {
            log.warn("Authentication failed (invalid or expired token): {}", e.getMessage());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            ApiResponseDTO apiResponseDto = new ApiResponseDTO(
                    "authentication.error",
                    "Authentication error"
            );
            response.getWriter().write(objectMapper.writeValueAsString(apiResponseDto));
            return;
        } catch (Exception e) {
            log.error("Internal error during authentication", e);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            ApiResponseDTO apiResponseDto = new ApiResponseDTO(
                    "internal.error",
                    "An internal error occurred"
            );
            response.getWriter().write(objectMapper.writeValueAsString(apiResponseDto));
            return;
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Retrieves the authorities granted to the user.
     *
     * @return a collection of granted authorities
     */
    private Collection<GrantedAuthority> getAuthorities(User user) {
        List<GrantedAuthority> authorities = new ArrayList<>();

        user.getRoles().forEach(role -> {
            authorities.add(new SimpleGrantedAuthority(role.name()));
        });

        user.getPermissions().forEach(permission -> {
            authorities.add(new SimpleGrantedAuthority("PERM_" + permission.name()));
        });

        return authorities;
    }
}
