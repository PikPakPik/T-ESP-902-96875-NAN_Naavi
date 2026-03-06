package fr.naavi.identity.security;

import tools.jackson.databind.ObjectMapper;
import fr.naavi.core.enums.JwtEnum;
import fr.naavi.core.enums.PermissionEnum;
import fr.naavi.core.enums.RoleEnum;
import fr.naavi.core.service.JwtService;
import fr.naavi.identity.entity.Session;
import fr.naavi.identity.entity.User;
import fr.naavi.identity.repository.SessionRepository;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JWTAuthenticationFilterTest {

    @Mock
    private SessionRepository sessionRepository;

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
        filter = new JWTAuthenticationFilter(objectMapper, sessionRepository, jwtService);
        request = new MockHttpServletRequest();
        response = new MockHttpServletResponse();
        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private User createUser(List<RoleEnum> roles, List<PermissionEnum> permissions) {
        User user = new User();
        user.setFirstname("John");
        user.setLastname("Doe");
        user.setEmail("john@naavi.app");
        user.setPassword("hashed");
        user.setRoles(roles);
        user.setPermissions(permissions);
        return user;
    }

    private Session createSession(User user, String accessToken, LocalDateTime expiresAt) {
        Session session = new Session();
        session.setUser(user);
        session.setAccessToken(accessToken);
        session.setRefreshToken("refresh-token");
        session.setClientIp("127.0.0.1");
        session.setUserAgent("JUnit");
        session.setCreatedAt(LocalDateTime.now());
        session.setAccessTokenExpiredAt(expiresAt);
        session.setRefreshTokenExpiredAt(expiresAt.plusDays(6));
        return session;
    }

    // ── No token (public routes) ────────────────────────────────────────

    @Nested
    @DisplayName("Without Authorization header")
    class NoToken {

        @Test
        @DisplayName("should continue filter chain when no Authorization header")
        void noAuthorizationHeader() throws ServletException, IOException {
            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(response.getStatus()).isEqualTo(200);
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }

        @Test
        @DisplayName("should continue filter chain when Authorization header is empty")
        void emptyAuthorizationHeader() throws ServletException, IOException {
            request.addHeader("Authorization", "");

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }
    }

    // ── Valid token (happy path) ────────────────────────────────────────

    @Nested
    @DisplayName("With valid Bearer token")
    class ValidToken {

        @Test
        @DisplayName("should authenticate user and continue filter chain")
        void validBearerToken() throws ServletException, IOException {
            String sessId = "sess-123";
            User user = createUser(List.of(RoleEnum.ROLE_USER), List.of());
            Session session = createSession(user, sessId, LocalDateTime.now().plusHours(1));

            request.addHeader("Authorization", "Bearer valid-jwt-token");
            when(jwtService.verifyJwt("valid-jwt-token", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenReturn(sessId);
            when(sessionRepository.findByAccessToken(sessId)).thenReturn(Optional.of(session));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(response.getStatus()).isEqualTo(200);
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
            assertThat(SecurityContextHolder.getContext().getAuthentication().getPrincipal()).isEqualTo(user);
            assertThat(request.getAttribute("sessId")).isEqualTo(sessId);
        }

        @Test
        @DisplayName("should grant ROLE_USER authority by default")
        void authoritiesIncludeRoleUser() throws ServletException, IOException {
            String sessId = "sess-456";
            User user = createUser(List.of(), List.of());
            Session session = createSession(user, sessId, LocalDateTime.now().plusHours(1));

            request.addHeader("Authorization", "Bearer token");
            when(jwtService.verifyJwt("token", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenReturn(sessId);
            when(sessionRepository.findByAccessToken(sessId)).thenReturn(Optional.of(session));

            filter.doFilterInternal(request, response, filterChain);

            var auth = SecurityContextHolder.getContext().getAuthentication();
            assertThat(auth).isNotNull();
            assertThat(auth.getAuthorities())
                    .extracting("authority")
                    .contains("ROLE_USER");
        }

        @Test
        @DisplayName("should grant roles and permissions as authorities")
        void authoritiesIncludeRolesAndPermissions() throws ServletException, IOException {
            String sessId = "sess-789";
            User user = createUser(
                    List.of(RoleEnum.ROLE_ADMIN),
                    List.of(PermissionEnum.USER_READ, PermissionEnum.USER_WRITE)
            );
            Session session = createSession(user, sessId, LocalDateTime.now().plusHours(1));

            request.addHeader("Authorization", "Bearer token");
            when(jwtService.verifyJwt("token", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenReturn(sessId);
            when(sessionRepository.findByAccessToken(sessId)).thenReturn(Optional.of(session));

            filter.doFilterInternal(request, response, filterChain);

            var auth = SecurityContextHolder.getContext().getAuthentication();
            assertThat(auth).isNotNull();
            assertThat(auth.getAuthorities())
                    .extracting("authority")
                    .contains("ROLE_USER", "ROLE_ADMIN", "PERM_USER_READ", "PERM_USER_WRITE");
        }

        @Test
        @DisplayName("should accept token without 'Bearer ' prefix")
        void tokenWithoutBearerPrefix() throws ServletException, IOException {
            String sessId = "sess-raw";
            User user = createUser(List.of(), List.of());
            Session session = createSession(user, sessId, LocalDateTime.now().plusHours(1));

            request.addHeader("Authorization", "raw-jwt-token");
            when(jwtService.verifyJwt("raw-jwt-token", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenReturn(sessId);
            when(sessionRepository.findByAccessToken(sessId)).thenReturn(Optional.of(session));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain).doFilter(request, response);
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
        }
    }

    // ── Session not found ───────────────────────────────────────────────

    @Nested
    @DisplayName("Session not found")
    class SessionNotFound {

        @Test
        @DisplayName("should return 401 when session not found in DB")
        void sessionNotFound() throws ServletException, IOException {
            request.addHeader("Authorization", "Bearer valid-jwt");
            when(jwtService.verifyJwt("valid-jwt", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenReturn("unknown-sess");
            when(sessionRepository.findByAccessToken("unknown-sess")).thenReturn(Optional.empty());

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(401);
            assertThat(response.getContentType()).isEqualTo("application/json");
            assertThat(response.getContentAsString()).contains("session.not_found_or_invalid");
            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }
    }

    // ── Session expired ─────────────────────────────────────────────────

    @Nested
    @DisplayName("Session expired")
    class SessionExpired {

        @Test
        @DisplayName("should return 401 when access token is expired in DB")
        void accessTokenExpired() throws ServletException, IOException {
            String sessId = "sess-expired";
            User user = createUser(List.of(), List.of());
            Session session = createSession(user, sessId, LocalDateTime.now().minusHours(1));

            request.addHeader("Authorization", "Bearer expired-jwt");
            when(jwtService.verifyJwt("expired-jwt", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenReturn(sessId);
            when(sessionRepository.findByAccessToken(sessId)).thenReturn(Optional.of(session));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(401);
            assertThat(response.getContentAsString()).contains("session.not_found_or_invalid");
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
            request.addHeader("Authorization", "Bearer bad-jwt");
            when(jwtService.verifyJwt("bad-jwt", JwtEnum.AUTH))
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
        @DisplayName("should return 401 on expired JWT signature")
        void expiredJwtSignature() throws ServletException, IOException {
            request.addHeader("Authorization", "Bearer expired-sig");
            when(jwtService.verifyJwt("expired-sig", JwtEnum.AUTH))
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
            request.addHeader("Authorization", "Bearer crash-jwt");
            when(jwtService.verifyJwt("crash-jwt", JwtEnum.AUTH))
                    .thenThrow(new RuntimeException("DB connection failed"));

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
            request.addHeader("Authorization", "Bearer npe-jwt");
            when(jwtService.verifyJwt("npe-jwt", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenThrow(new NullPointerException("oops"));

            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(500);
            assertThat(response.getContentAsString()).contains("internal.error");
        }

        @Test
        @DisplayName("should return 500 on IllegalStateException from repository")
        void repositoryExceptionReturns500() throws ServletException, IOException {
            request.addHeader("Authorization", "Bearer repo-err");
            when(jwtService.verifyJwt("repo-err", JwtEnum.AUTH)).thenReturn(claims);
            when(claims.get("sessId", String.class)).thenReturn("sess-x");
            when(sessionRepository.findByAccessToken("sess-x"))
                    .thenThrow(new IllegalStateException("Connection pool exhausted"));

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
        @DisplayName("should not set authentication when verifyJwt returns null claims")
        void nullClaimsFromVerifyJwt() throws ServletException, IOException {
            request.addHeader("Authorization", "Bearer null-claims-jwt");
            when(jwtService.verifyJwt("null-claims-jwt", JwtEnum.AUTH)).thenReturn(null);

            // verifyJwt returns null → claims.get() throws NullPointerException
            // which is caught by the generic Exception catch → 500
            filter.doFilterInternal(request, response, filterChain);

            verify(filterChain, never()).doFilter(any(), any());
            assertThat(response.getStatus()).isEqualTo(500);
        }

        @Test
        @DisplayName("should not authenticate when token is only whitespace")
        void whitespaceToken() throws ServletException, IOException {
            request.addHeader("Authorization", "   ");
            // " " doesn't start with "Bearer " → token = "   "
            // "   ".isEmpty() returns false, so verifyJwt is called
            when(jwtService.verifyJwt("   ", JwtEnum.AUTH))
                    .thenThrow(new JwtException("Malformed token"));

            filter.doFilterInternal(request, response, filterChain);

            assertThat(response.getStatus()).isEqualTo(401);
            assertThat(response.getContentAsString()).contains("authentication.error");
        }

        @Test
        @DisplayName("should clear SecurityContext before returning on error")
        void securityContextClearedOnError() throws ServletException, IOException {
            request.addHeader("Authorization", "Bearer invalid");
            when(jwtService.verifyJwt("invalid", JwtEnum.AUTH))
                    .thenThrow(new JwtException("bad"));

            filter.doFilterInternal(request, response, filterChain);

            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        }
    }
}
