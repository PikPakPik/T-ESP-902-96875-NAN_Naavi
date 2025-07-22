package fr.naavi.core.exception.children;

import fr.naavi.core.exception.GenericHttpException;
import org.springframework.http.HttpStatus;


/**
 * Exception thrown when authentication is required and has failed or has not yet been provided.
 * This exception typically indicates that the user must authenticate to access the requested resource.
 * Responds with HTTP status {@link HttpStatus#UNAUTHORIZED}.
 */
public class NaaviUnauthorizedException extends GenericHttpException {

    /**
     * Constructs a new {@code NaaviUnauthorizedException} with a default i18n key and message.
     *
     * <p>Default values are:
     * <ul>
     *     <li>i18nKey: {@code "unauthorized"}</li>
     *     <li>message: {@code "Can't access this resource"}</li>
     * </ul>
     * </p>
     */
    public NaaviUnauthorizedException() {
        this("unauthorized", "Can't access this resource");
    }

    /**
     * Constructs a new {@code NaaviUnauthorizedException} with the given i18n key and message.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public NaaviUnauthorizedException(String i18nKey, String message) {
        this(i18nKey, message, null);
    }

    /**
     * Constructs a new {@code NaaviUnauthorizedException} with the given i18n key, message, and extra data.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param extra   Additional data to include in the response (may be {@code null}).
     */
    public NaaviUnauthorizedException(String i18nKey, String message, Object extra) {
        super(HttpStatus.UNAUTHORIZED, i18nKey, message, extra);
    }
}
