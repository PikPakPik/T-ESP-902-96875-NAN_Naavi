package fr.naavi.identity.exception;

import org.springframework.security.core.AuthenticationException;

public class BannedException extends AuthenticationException {
    /**
     * Constructs a BannedException with a default message.
     */
    public BannedException() {
        super("Your account has been banned.");
    }
}
