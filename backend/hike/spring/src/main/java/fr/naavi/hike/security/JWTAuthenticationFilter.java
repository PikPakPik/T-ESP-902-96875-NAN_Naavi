package fr.naavi.hike.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.enums.JwtEnum;
import fr.naavi.core.enums.TokenType;
import fr.naavi.core.service.JwtService;
import io.jsonwebtoken.Claims;
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
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

public class JWTAuthenticationFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(JWTAuthenticationFilter.class);

    private final ObjectMapper objectMapper;
    private final JwtService jwtService;

    /**
     * Constructs a JWTAuthenticationFilter.
     */
    public JWTAuthenticationFilter(
            ObjectMapper objectMapper,
            JwtService jwtService
    ) {
        this.objectMapper = objectMapper;
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        try {
            String xUserValue = request.getHeader("X-User");

            if (xUserValue != null && !xUserValue.isEmpty()) {
                Claims claims = this.jwtService.verifyJwt(xUserValue, JwtEnum.EXCHANGE);
                String type = claims.get("type", String.class);

                if (type.equals(TokenType.LOGGED.name())) {
                    Collection<?> rawRoles = claims.get("roles", Collection.class);
                    Collection<String> roles = rawRoles != null
                            ? rawRoles.stream().map(Object::toString).toList()
                            : List.of();
                    Collection<GrantedAuthority> authorities = getAuthorities(roles);
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            Map.of(
                                    "id", claims.get("id", Integer.class),
                                    "firstname", claims.get("firstname", String.class),
                                    "lastname", claims.get("lastname", String.class),
                                    "email", claims.get("email", String.class),
                                    "roles", claims.get("roles", Collection.class),
                                    "permissions", claims.get("permissions", Collection.class)
                            ),
                            null,
                            authorities
                    );
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        } catch (Exception e) {
            log.error("Authentication error: {}", e.getMessage());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            ApiResponseDTO apiResponseDto = new ApiResponseDTO(
                    "authentication.error",
                    "Authentication error"
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
    private Collection<GrantedAuthority> getAuthorities(Collection<String> user) {
        List<GrantedAuthority> authorities = new ArrayList<>();

        user.forEach(role -> {
            authorities.add(new SimpleGrantedAuthority(role));
        });

        user.forEach(permission -> {
            authorities.add(new SimpleGrantedAuthority("PERM_" + permission));
        });

        return authorities;
    }
}
