package fr.naavi.core.exception.children;

import fr.naavi.core.exception.GenericHttpException;
import org.springframework.http.HttpStatus;

/**
 * Exception thrown when a requested resource could not be found.
 * This exception typically indicates that the client attempted to access
 * a resource that does not exist or is no longer available.
 * Responds with HTTP status {@link HttpStatus#NOT_FOUND}.
 */
public class NaaviNotFoundException extends GenericHttpException {

    /**
     * Constructs a new {@code NaaviNotFoundException} with a default i18n key and message.
     *
     * <p></p>Default values are:
     * <ul>
     *     <li>i18nKey: {@code "not_found"}</li>
     *     <li>message: {@code "Can't access this resource"}</li>
     * </ul>
     * </p>
     */
    public NaaviNotFoundException() {
        this("not_found", "Can't access this resource");
    }

    /**
     * Constructs a new {@code NaaviNotFoundException} with the given i18n key and message.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public NaaviNotFoundException(String i18nKey, String message) {
        this(i18nKey, message, null);
    }

    /**
     * Constructs a new {@code NaaviNotFoundException} with the given i18n key, message, and extra data.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param extra   Additional data to include in the response (may be {@code null}).
     */

    public NaaviNotFoundException(String i18nKey, String message, Object extra) {
        super(HttpStatus.NOT_FOUND, i18nKey, message, extra);
    }
}
