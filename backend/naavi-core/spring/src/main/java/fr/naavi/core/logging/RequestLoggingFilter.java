package fr.naavi.core.logging;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Filter that logs HTTP request/response with method, path, status and duration.
 * Request/response bodies are not logged to avoid sensitive data exposure.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1)
public class RequestLoggingFilter extends OncePerRequestFilter {

    private static final Logger LOG = LoggerFactory.getLogger(RequestLoggingFilter.class);

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String method = request.getMethod();
        String path = request.getRequestURI();
        String queryString = request.getQueryString();
        String fullPath = queryString != null ? path + "?" + queryString : path;

        long start = System.nanoTime();

        try {
            filterChain.doFilter(request, response);
        } finally {
            int status = response.getStatus();
            double durationMs = (System.nanoTime() - start) / 1_000_000.0;
            int effectiveStatus = status > 0 ? status : 200;

            if (effectiveStatus >= 400) {
                LOG.error("Request finished \"{}\" \"{}\" - {} in {}ms",
                        method, fullPath, effectiveStatus, String.format("%.2f", durationMs));
            } else {
                LOG.info("Request finished \"{}\" \"{}\" - {} in {}ms",
                        method, fullPath, effectiveStatus, String.format("%.2f", durationMs));
            }
        }
    }
}
