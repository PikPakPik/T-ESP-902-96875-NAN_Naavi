package fr.naavi.core.utils;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

public class RequestUtils {

    /**
     * Retrieves the client's IP address from the request headers.
     * It checks for "X-Forwarded-For" and "X-Real-IP" headers first, then falls back to the remote address.
     *
     * @return the client's IP address as a String
     */
    public static String getClientIpAddress() {
        ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
        HttpServletRequest request = attrs.getRequest();

        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }

        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }

        return request.getRemoteAddr();
    }

    /**
     * Retrieves the User-Agent header from the request.
     *
     * @return the User-Agent string from the request headers
     */
    public static String getUserAgent() {
        ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
        HttpServletRequest request = attrs.getRequest();
        return request.getHeader("User-Agent");
    }
}
