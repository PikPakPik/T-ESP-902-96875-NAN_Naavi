package fr.naavi.hike.security;

import tools.jackson.databind.ObjectMapper;
import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.enums.JwtEnum;
import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.enums.TokenType;
import fr.naavi.core.service.JwtService;
import fr.naavi.hike.dto.UserDTO;
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
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

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

                    Collection<?> rawPermissions = claims.get("permissions", Collection.class);
                    Collection<String> permissions = rawPermissions != null
                            ? rawPermissions.stream().map(Object::toString).toList()
                            : List.of();

                    List<RoleEnum> roleEnums = roles.stream()
                            .map(RoleEnum::valueOf)
                            .toList();

                    List<PermissionEnum> permissionEnums = permissions.stream()
                            .map(PermissionEnum::valueOf)
                            .toList();

                    UserDTO userDto = new UserDTO();
                    userDto.setId(claims.get("id", Long.class));
                    userDto.setFirstname(claims.get("firstname", String.class));
                    userDto.setLastname(claims.get("lastname", String.class));
                    userDto.setEmail(claims.get("email", String.class));
                    userDto.setRoles(roleEnums);
                    userDto.setPermissions(permissionEnums);


                    List<GrantedAuthority> authorities = new ArrayList<>();

                    userDto.getRoles().forEach(role -> {
                        authorities.add(new SimpleGrantedAuthority(role.name()));
                    });

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDto,
                            null,
                            authorities
                    );
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
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
}
