package fr.naavi.core.logging;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * Filter that populates MDC (Mapped Diagnostic Context) with request metadata
 * for structured logging in Seq and Grafana Loki.
 *
 * <p>Adds: CorrelationId, RequestId, RequestPath, RequestMethod, MicroService</p>
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class MdcLoggingFilter extends OncePerRequestFilter {

    private static final String CORRELATION_ID = "CorrelationId";
    private static final String REQUEST_ID = "RequestId";
    private static final String REQUEST_PATH = "RequestPath";
    private static final String REQUEST_METHOD = "RequestMethod";
    private static final String MICRO_SERVICE = "MicroService";

    private final String microServiceName;

    public MdcLoggingFilter(
            @Value("${spring.application.name:naavi}") String microServiceName
    ) {
        this.microServiceName = microServiceName != null ? microServiceName : "naavi";
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        try {
            String correlationId = request.getHeader("X-Correlation-ID");
            if (correlationId == null || correlationId.isBlank()) {
                correlationId = UUID.randomUUID().toString();
            }

            MDC.put(CORRELATION_ID, correlationId);
            MDC.put(REQUEST_ID, UUID.randomUUID().toString());
            MDC.put(REQUEST_PATH, request.getRequestURI());
            MDC.put(REQUEST_METHOD, request.getMethod());
            MDC.put(MICRO_SERVICE, microServiceName);

            response.setHeader("X-Correlation-ID", correlationId);

            filterChain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
