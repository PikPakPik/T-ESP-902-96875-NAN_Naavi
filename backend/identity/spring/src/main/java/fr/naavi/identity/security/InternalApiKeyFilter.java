package fr.naavi.identity.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.naavi.core.dto.ApiResponseDTO;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class InternalApiKeyFilter extends OncePerRequestFilter {
    @Value("${naavi.internal.api-key}")
    private String internalApiKey;

    private final ObjectMapper objectMapper;

    /**
     * Constructor for InternalApiKeyFilter.
     */
    public InternalApiKeyFilter(
            ObjectMapper objectMapper
    ) {
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String internalApiKeyValue = request.getHeader("X-Internal-Api-Key");

        if (internalApiKeyValue != null && !internalApiKeyValue.isEmpty() && !internalApiKeyValue.equals(this.internalApiKey)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            ApiResponseDTO apiResponseDto = new ApiResponseDTO(
                    "internal.api_key.invalid",
                    "Invalid internal API key"
            );
            response.getWriter().write(this.objectMapper.writeValueAsString(apiResponseDto));
            return;
        }

        filterChain.doFilter(request, response);
    }
}
