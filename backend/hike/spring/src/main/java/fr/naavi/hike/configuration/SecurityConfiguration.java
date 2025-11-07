package fr.naavi.hike.configuration;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.naavi.core.service.JwtService;
import fr.naavi.hike.security.AuthenticationNotRequiredMatcher;
import fr.naavi.hike.security.JWTAuthenticationFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.servlet.HandlerMapping;

import java.util.Map;

@Configuration
public class SecurityConfiguration {
    @Autowired
    @Qualifier("requestMappingHandlerMapping")
    private HandlerMapping handlerMapping;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * Configures the security filter chain for Swagger UI and API documentation.
     * Disables CSRF, logout, HTTP basic authentication, and form login.
     * Sets session management to stateless.
     *
     * @param http HttpSecurity object to configure security settings
     * @return SecurityFilterChain instance
     * @throws Exception if an error occurs during configuration
     */
    @Bean
    @Order(1)
    public SecurityFilterChain swaggerFilterChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/api-docs/**", "/swagger-ui/**", "/swagger-ui.html");
        http.csrf(AbstractHttpConfigurer::disable);
        http.logout(AbstractHttpConfigurer::disable);
        http.httpBasic(AbstractHttpConfigurer::disable);
        http.formLogin(AbstractHttpConfigurer::disable);
        http.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }

    /**
     * Configures the security filter chain for the application.
     * Disables CSRF, logout, HTTP basic authentication, and form login.
     * Sets up authorization rules and exception handling.
     *
     * @param http HttpSecurity object to configure security settings
     * @param objectMapper ObjectMapper for JSON serialization
     * @param jwtService JwtService for handling JWT operations
     * @return SecurityFilterChain instance
     * @throws Exception if an error occurs during configuration
     */
    @Bean
    @Order(2)
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            ObjectMapper objectMapper,
            JwtService jwtService
    ) throws Exception {
        JWTAuthenticationFilter jwtAuthenticationFilter = new JWTAuthenticationFilter(
                objectMapper,
                jwtService
        );

        http.csrf(AbstractHttpConfigurer::disable);
        http.logout(AbstractHttpConfigurer::disable);
        http.httpBasic(AbstractHttpConfigurer::disable);
        http.formLogin(AbstractHttpConfigurer::disable);
        http.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        http.authorizeHttpRequests(authorize -> authorize
                .requestMatchers(new AuthenticationNotRequiredMatcher(handlerMapping)).permitAll()
                .anyRequest().authenticated()
        );
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        http.exceptionHandling(exception -> exception
                .authenticationEntryPoint(authenticationEntryPoint())
                .accessDeniedHandler(accessDeniedHandler())
        );
        return http.build();
    }

    /**
     * @return an AuthenticationEntryPoint that handles unauthorized access
     */
    @Bean
    public AuthenticationEntryPoint authenticationEntryPoint() {
        return (HttpServletRequest request, HttpServletResponse response, AuthenticationException authException) -> {
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            Map<String, Object> errorResponse = Map.of(
                    "message", "Unauthorized access. You must be authenticated to access this resource."
            );
            response.getWriter().write(this.objectMapper.writeValueAsString(errorResponse));
        };
    }

    /**
     * @return an AccessDeniedHandler that handles access denied exceptions
     */
    @Bean
    public AccessDeniedHandler accessDeniedHandler() {
        return (HttpServletRequest request, HttpServletResponse response, AccessDeniedException accessDeniedException) -> {
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            Map<String, String> errorResponse = Map.of(
                    "message", "Access denied. You do not have the necessary permissions to access this resource"
            );
            response.getWriter().write(this.objectMapper.writeValueAsString(errorResponse));
        };
    }
}