package fr.naavi.identity.configuration;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.naavi.identity.security.AuthenticationNotRequiredMatcher;
import fr.naavi.identity.security.InternalApiKeyFilter;
import fr.naavi.identity.security.JWTAuthenticationFilter;
import fr.naavi.identity.security.LoginAuthenticationProvider;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.servlet.HandlerMapping;

import java.util.List;
import java.util.Map;

@Configuration
public class SecurityConfiguration {
    private static final Logger log = LoggerFactory.getLogger(SecurityConfiguration.class);

    @Autowired
    @Qualifier("requestMappingHandlerMapping")
    private HandlerMapping handlerMapping;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * Configures the security filter chain for the application.
     * Disables CSRF, logout, HTTP basic authentication, and form login.
     *
     * @param http HttpSecurity object to configure security settings
     * @param loginAuthenticationProvider the provider to handle login authentication
     * @return SecurityFilterChain instance
     * @throws Exception if an error occurs during configuration
     */
    @Bean
    @Order(1)
    public SecurityFilterChain loginFilterChain(
            HttpSecurity http,
            LoginAuthenticationProvider loginAuthenticationProvider
    ) throws Exception {
        http.securityMatcher("/login");
        http.csrf(AbstractHttpConfigurer::disable);
        http.logout(AbstractHttpConfigurer::disable);
        http.httpBasic(AbstractHttpConfigurer::disable);
        http.formLogin(AbstractHttpConfigurer::disable);
        http.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        http.authenticationManager(authenticationManager(loginAuthenticationProvider));
        return http.build();
    }

    /**
     * Configures the security filter chain for internal endpoints.
     * Disables CSRF, logout, HTTP basic authentication, and form login.
     * Sets session management to stateless.
     *
     * @param http HttpSecurity object to configure security settings
     * @param internalApiKeyFilter the filter to handle internal API key authentication
     * @return SecurityFilterChain instance
     * @throws Exception if an error occurs during configuration
     */
    @Bean
    @Order(2)
    public SecurityFilterChain internalFilterChain(HttpSecurity http, InternalApiKeyFilter internalApiKeyFilter) throws Exception {
        http.securityMatcher("/internal/**");
        http.csrf(AbstractHttpConfigurer::disable);
        http.logout(AbstractHttpConfigurer::disable);
        http.httpBasic(AbstractHttpConfigurer::disable);
        http.formLogin(AbstractHttpConfigurer::disable);
        http.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        http.addFilterBefore(internalApiKeyFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /**
     * Configures the security filter chain for the application.
     * Disables CSRF, logout, HTTP basic authentication, and form login.
     * Sets up authorization rules and exception handling.
     *
     * @param http HttpSecurity object to configure security settings
     * @param jwtAuthenticationFilter the filter to handle JWT authentication
     * @return SecurityFilterChain instance
     * @throws Exception if an error occurs during configuration
     */
    @Bean
    @Order(3)
    public SecurityFilterChain securityFilterChain(HttpSecurity http, JWTAuthenticationFilter jwtAuthenticationFilter) throws Exception {
        http.csrf(AbstractHttpConfigurer::disable);
        http.logout(AbstractHttpConfigurer::disable);
        http.httpBasic(AbstractHttpConfigurer::disable);
        http.formLogin(AbstractHttpConfigurer::disable);
        http.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        http.authorizeHttpRequests(authorize -> authorize
                .requestMatchers(new AuthenticationNotRequiredMatcher(handlerMapping)).permitAll()
                .anyRequest().authenticated()
        );
        http.addFilterAfter(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
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
            log.error("Access denied {}", accessDeniedException.getMessage());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            Map<String, String> errorResponse = Map.of(
                    "message", "Access denied. You do not have the necessary permissions to access this resource"
            );
            response.getWriter().write(this.objectMapper.writeValueAsString(errorResponse));
        };
    }

    /**
     * AuthenticationManager bean that uses the LoginAuthenticationProvider for authentication.
     *
     * @param loginAuthenticationProvider the provider to handle login authentication
     * @return AuthenticationManager instance
     */
    @Bean
    public AuthenticationManager authenticationManager(LoginAuthenticationProvider loginAuthenticationProvider) {
        return new ProviderManager(List.of(loginAuthenticationProvider));
    }

    /**
     * Password encoder bean for encoding passwords.
     * Uses BCrypt hashing algorithm.
     *
     * @return PasswordEncoder instance
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
}
