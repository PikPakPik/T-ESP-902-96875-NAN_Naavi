package fr.naavi.hike.security;

import tools.jackson.databind.ObjectMapper;
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
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.IOException;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JWTAuthenticationFilterTest {

    @Mock
    private JwtService jwtService;

    @Mock
    private Claims claims;

    @Mock
    private FilterChain filterChain;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private JWTAuthenticationFilter filter;
    private MockHttpServletRequest request;
    private MockHttpServletResponse response;

    @BeforeEach
    void setUp() {
        filter = new JWTAuthenticationFilter(objectMapper, jwtService);
        request = new MockHttpServletRequest();
        response = new MockHttpServletResponse();
        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private void stubLoggedClaims(
            Long id,
            String firstname,
            String lastname,
            String email,
            List<String> roles,
            List<String> permissions
    ) {
        when(claims.get("type", String.class)).thenReturn(TokenType.LOGGED.name());
        when(claims.get("id", Long.class)).thenReturn(id);
        when(claims.get("firstname", String.class)).thenReturn(firstname);
        when(claims.get("lastname", String.class)).thenReturn(lastname);
        when(claims.get("email", String.class)).thenReturn(email);
        when(claims.get("roles", java.util.Collection.class)).thenReturn(roles);
        when(claims.get("permissions", java.util.Collection.class)).thenReturn(permissions);
    }

    // ── No X-User header (public routes) ────────────────────────────────

    @Nested
    @DisplayName("Without X-User header")
    class NoXUserHeader {

        @Test
        @DisplayName("should continue filter chain when no X-User header")
        void noXUserHeader() throws ServletException, IOException {
            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(response.getStatus()).isEqualTo(200);
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }

        @Test
        @DisplayName("should continue filter chain when X-User header is empty")
        void emptyXUserHeader() throws ServletException, IOException {
            request.addHeader("X-User", "");

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }
    }

    // ── Valid LOGGED token (happy path) ─────────────────────────────────

    @Nested
    @DisplayName("With valid X-User token (LOGGED)")
    class ValidLoggedToken {

        @Test
        @DisplayName("should authenticate user and continue filter chain")
        void validLoggedToken() throws ServletException, IOException {
            request.addHeader("X-User", "valid-exchange-jwt");
            when(jwtService.verifyJwt("valid-exchange-jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            stubLoggedClaims(1L, "John", "Doe", "john@naavi.app",
                    List.of("ROLE_USER"), List.of());

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(response.getStatus()).isEqualTo(200);

            var auth = SecurityContextHolder.getContext().getAuthentication();
            assertThat(auth).isNotNull();
            assertThat(auth.getPrincipal()).isInstanceOf(UserDTO.class);

            UserDTO user = (UserDTO) auth.getPrincipal();
            assertThat(user.getId()).isEqualTo(1L);
            assertThat(user.getFirstname()).isEqualTo("John");
            assertThat(user.getLastname()).isEqualTo("Doe");
            assertThat(user.getEmail()).isEqualTo("john@naavi.app");
        }

        @Test
        @DisplayName("should grant ROLE_USER authority")
        void authoritiesFromRoles() throws ServletException, IOException {
            request.addHeader("X-User", "jwt");
            when(jwtService.verifyJwt("jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            stubLoggedClaims(2L, "Jane", "Doe", "jane@naavi.app",
                    List.of("ROLE_USER"), List.of());

            filter.doFilterInternal(request, response, filterChain);

            var auth = SecurityContextHolder.getContext().getAuthentication();
            assertThat(auth).isNotNull();
            assertThat(auth.getAuthorities())
                    .extracting("authority")
                    .containsExactly("ROLE_USER");
        }

        @Test
        @DisplayName("should grant multiple roles as authorities")
        void multipleRolesAsAuthorities() throws ServletException, IOException {
            request.addHeader("X-User", "jwt");
            when(jwtService.verifyJwt("jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            stubLoggedClaims(3L, "Admin", "User", "admin@naavi.app",
                    List.of("ROLE_USER", "ROLE_ADMIN"), List.of("USER_READ", "USER_WRITE"));

            filter.doFilterInternal(request, response, filterChain);

            var auth = SecurityContextHolder.getContext().getAuthentication();
            assertThat(auth).isNotNull();
            assertThat(auth.getAuthorities())
                    .extracting("authority")
                    .containsExactly("ROLE_USER", "ROLE_ADMIN");
        }

        @Test
        @DisplayName("should set roles and permissions on UserDTO")
        void userDtoRolesAndPermissions() throws ServletException, IOException {
            request.addHeader("X-User", "jwt");
            when(jwtService.verifyJwt("jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            stubLoggedClaims(4L, "Mod", "User", "mod@naavi.app",
                    List.of("ROLE_USER", "ROLE_MODERATOR"),
                    List.of("USER_READ", "USER_WRITE", "USER_DELETE"));

            filter.doFilterInternal(request, response, filterChain);

            var auth = SecurityContextHolder.getContext().getAuthentication();
            assertThat(auth).isNotNull();
            UserDTO user = (UserDTO) auth.getPrincipal();
            assertThat(user.getRoles()).containsExactly(RoleEnum.ROLE_USER, RoleEnum.ROLE_MODERATOR);
            assertThat(user.getPermissions()).containsExactly(
                    PermissionEnum.USER_READ, PermissionEnum.USER_WRITE, PermissionEnum.USER_DELETE);
        }

        @Test
        @DisplayName("should handle null roles and permissions in claims")
        void nullRolesAndPermissions() throws ServletException, IOException {
            request.addHeader("X-User", "jwt");
            when(jwtService.verifyJwt("jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            when(claims.get("type", String.class)).thenReturn(TokenType.LOGGED.name());
            when(claims.get("id", Long.class)).thenReturn(5L);
            when(claims.get("firstname", String.class)).thenReturn("Null");
            when(claims.get("lastname", String.class)).thenReturn("Roles");
            when(claims.get("email", String.class)).thenReturn("null@naavi.app");
            when(claims.get("roles", java.util.Collection.class)).thenReturn(null);
            when(claims.get("permissions", java.util.Collection.class)).thenReturn(null);

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            var auth = SecurityContextHolder.getContext().getAuthentication();
            assertThat(auth).isNotNull();
            assertThat(auth.getAuthorities()).isEmpty();
            UserDTO user = (UserDTO) auth.getPrincipal();
            assertThat(user.getRoles()).isEmpty();
            assertThat(user.getPermissions()).isEmpty();
        }
    }

    // ── GUEST token type ────────────────────────────────────────────────

    @Nested
    @DisplayName("With GUEST token type")
    class GuestTokenType {

        @Test
        @DisplayName("should not authenticate and continue filter chain for GUEST token")
        void guestTokenDoesNotAuthenticate() throws ServletException, IOException {
            request.addHeader("X-User", "guest-jwt");
            when(jwtService.verifyJwt("guest-jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            when(claims.get("type", String.class)).thenReturn(TokenType.GUEST.name());

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(response.getStatus()).isEqualTo(200);
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }
    }

    // ── JwtException (invalid/expired JWT) ──────────────────────────────

    @Nested
    @DisplayName("JwtException handling")
    class JwtExceptionHandling {

        @Test
        @DisplayName("should return 401 with authentication.error on JwtException")
        void jwtExceptionReturns401() throws ServletException, IOException {
            request.addHeader("X-User", "bad-jwt");
            when(jwtService.verifyJwt("bad-jwt", JwtEnum.EXCHANGE))
                    .thenThrow(new JwtException("Token signature invalid"));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(401);
            assertThat(response.getContentType()).isEqualTo("application/json");
            assertThat(response.getContentAsString()).contains("authentication.error");
            assertThat(response.getContentAsString()).contains("Authentication error");
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }

        @Test
        @DisplayName("should return 401 on expired exchange token")
        void expiredExchangeToken() throws ServletException, IOException {
            request.addHeader("X-User", "expired-jwt");
            when(jwtService.verifyJwt("expired-jwt", JwtEnum.EXCHANGE))
                    .thenThrow(new JwtException("JWT expired at 2025-01-01"));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(401);
            assertThat(response.getContentAsString()).contains("authentication.error");
        }
    }

    // ── Generic Exception (internal error) ──────────────────────────────

    @Nested
    @DisplayName("Generic Exception handling (internal error)")
    class GenericExceptionHandling {

        @Test
        @DisplayName("should return 500 with internal.error on unexpected exception")
        void unexpectedExceptionReturns500() throws ServletException, IOException {
            request.addHeader("X-User", "crash-jwt");
            when(jwtService.verifyJwt("crash-jwt", JwtEnum.EXCHANGE))
                    .thenThrow(new RuntimeException("Crypto provider unavailable"));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(500);
            assertThat(response.getContentType()).isEqualTo("application/json");
            assertThat(response.getContentAsString()).contains("internal.error");
            assertThat(response.getContentAsString()).contains("An internal error occurred");
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }

        @Test
        @DisplayName("should return 500 on NullPointerException during claims parsing")
        void nullPointerDuringClaimsReturns500() throws ServletException, IOException {
            request.addHeader("X-User", "npe-jwt");
            when(jwtService.verifyJwt("npe-jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            when(claims.get("type", String.class)).thenThrow(new NullPointerException("oops"));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(500);
            assertThat(response.getContentAsString()).contains("internal.error");
        }

        @Test
        @DisplayName("should return 500 on IllegalArgumentException from invalid role name")
        void invalidRoleEnumReturns500() throws ServletException, IOException {
            request.addHeader("X-User", "bad-role-jwt");
            when(jwtService.verifyJwt("bad-role-jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            when(claims.get("type", String.class)).thenReturn(TokenType.LOGGED.name());
            when(claims.get("roles", java.util.Collection.class)).thenReturn(List.of("INVALID_ROLE"));
            when(claims.get("permissions", java.util.Collection.class)).thenReturn(List.of());

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(500);
            assertThat(response.getContentAsString()).contains("internal.error");
        }
    }

    // ── Edge cases ──────────────────────────────────────────────────────

    @Nested
    @DisplayName("Edge cases")
    class EdgeCases {

        @Test
        @DisplayName("should return 500 when verifyJwt returns null claims")
        void nullClaimsFromVerifyJwt() throws ServletException, IOException {
            request.addHeader("X-User", "null-claims-jwt");
            when(jwtService.verifyJwt("null-claims-jwt", JwtEnum.EXCHANGE)).thenReturn(null);

            // verifyJwt returns null → claims.get("type") throws NPE → caught by Exception → 500
            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(500);
            assertThat(response.getContentAsString()).contains("internal.error");
        }

        @Test
        @DisplayName("should not authenticate when X-User is only whitespace")
        void whitespaceXUser() throws ServletException, IOException {
            request.addHeader("X-User", "   ");
            // "   ".isEmpty() returns false, so verifyJwt is called
            when(jwtService.verifyJwt("   ", JwtEnum.EXCHANGE))
                    .thenThrow(new JwtException("Malformed token"));

            filter.doFilterInternal(request, response, filterChain);

            assertThat(response.getStatus()).isEqualTo(401);
            assertThat(response.getContentAsString()).contains("authentication.error");
        }

        @Test
        @DisplayName("should clear SecurityContext on JwtException")
        void securityContextClearedOnJwtError() throws ServletException, IOException {
            request.addHeader("X-User", "invalid");
            when(jwtService.verifyJwt("invalid", JwtEnum.EXCHANGE))
                    .thenThrow(new JwtException("bad"));

            filter.doFilterInternal(request, response, filterChain);

            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }

        @Test
        @DisplayName("should clear SecurityContext on generic Exception")
        void securityContextClearedOnGenericError() throws ServletException, IOException {
            request.addHeader("X-User", "error");
            when(jwtService.verifyJwt("error", JwtEnum.EXCHANGE))
                    .thenThrow(new RuntimeException("fail"));

            filter.doFilterInternal(request, response, filterChain);

            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }

        @Test
        @DisplayName("should use JwtEnum.EXCHANGE for token verification")
        void usesExchangeJwtEnum() throws ServletException, IOException {
            request.addHeader("X-User", "exchange-jwt");
            when(jwtService.verifyJwt("exchange-jwt", JwtEnum.EXCHANGE)).thenReturn(claims);
            stubLoggedClaims(10L, "Test", "User", "test@naavi.app",
                    List.of("ROLE_USER"), List.of());

            filter.doFilterInternal(request, response, filterChain);

            verify(jwtService).verifyJwt("exchange-jwt", JwtEnum.EXCHANGE);
            verify(jwtService, never()).verifyJwt(any(), org.mockito.ArgumentMatchers.eq(JwtEnum.AUTH));
        }
    }
}
