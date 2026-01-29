package fr.naavi.identity.exception;

import org.springframework.security.core.AuthenticationException;

public class UnverifiedException extends AuthenticationException {
    /**
     * Constructs an UnverifiedException with a default message.
     */
    public UnverifiedException() {
        super("Your email address has not been confirmed. Please check your email and click the confirmation link.");
    }
}
