package fr.naavi.identity.security;

import fr.naavi.core.annotation.AuthenticationNotRequired;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import org.springframework.security.web.util.matcher.RequestMatcher;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerExecutionChain;
import org.springframework.web.servlet.HandlerMapping;

public class AuthenticationNotRequiredMatcher implements RequestMatcher {
    private final HandlerMapping handlerMapping;

    /**
     * Constructs a new AuthenticationNotRequiredMatcher with the specified HandlerMapping.
     *
     * @param handlerMapping the HandlerMapping to use for retrieving handler methods
     */
    public AuthenticationNotRequiredMatcher(HandlerMapping handlerMapping) {
        this.handlerMapping = handlerMapping;
    }

    /**
     * Checks if the request matches the criteria for not requiring authentication.
     * It looks for the AuthenticationNotRequired annotation on the handler method or class.
     *
     * @param request the HttpServletRequest to check
     * @return true if the request matches (i.e., does not require authentication), false otherwise
     */
    @Override
    public boolean matches(HttpServletRequest request) {
        try {
            HandlerMethod handlerMethod = this.getHandlerMethod(request);
            if (handlerMethod == null) {
                return false;
            }

            AuthenticationNotRequired methodAnnotation =
                    handlerMethod.getMethodAnnotation(AuthenticationNotRequired.class);

            AuthenticationNotRequired classAnnotation =
                    handlerMethod.getBeanType().getAnnotation(AuthenticationNotRequired.class);

            return methodAnnotation != null || classAnnotation != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Retrieves the HandlerMethod for the given request.
     *
     * @param request the HttpServletRequest
     * @return the HandlerMethod if found, null otherwise
     * @throws Exception if an error occurs while retrieving the handler method
     */
    private HandlerMethod getHandlerMethod(HttpServletRequest request) throws Exception {
        HttpServletRequestWrapper requestWrapper = new HttpServletRequestWrapper(request);

        HandlerExecutionChain handlerChain = handlerMapping.getHandler(requestWrapper);
        if (handlerChain != null && handlerChain.getHandler() instanceof HandlerMethod) {
            return (HandlerMethod) handlerChain.getHandler();
        }

        return null;
    }
}
