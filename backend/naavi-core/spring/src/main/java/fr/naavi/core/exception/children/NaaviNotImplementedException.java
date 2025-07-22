package fr.naavi.core.exception.children;

import fr.naavi.core.exception.GenericHttpException;
import org.springframework.http.HttpStatus;

/**
 * Exception thrown when a requested operation or feature is not implemented.
 * This exception typically indicates that the functionality exists in the API
 * but has not yet been implemented or is intentionally unhandled.
 * Responds with HTTP status {@link HttpStatus#NOT_IMPLEMENTED}.
 */
public class NaaviNotImplementedException extends GenericHttpException {

    /**
     * Constructs a new {@code NaaviNotImplementedException} with a default i18n key and message.
     *
     * <p>Default values are:
     * <ul>
     *     <li>i18nKey: {@code "not_implemented"}</li>
     *     <li>message: {@code "Not implemented"}</li>
     * </ul>
     * </p>
     */
    public NaaviNotImplementedException() {
        this("not_implemented", "Not implemented");
    }

    /**
     * Constructs a new {@code NaaviNotImplementedException} with the given i18n key and message.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public NaaviNotImplementedException(String i18nKey, String message) {
        this(i18nKey, message, null);
    }

    /**
     * Constructs a new {@code NaaviNotImplementedException} with the given i18n key, message, and extra data.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param extra   Additional data to include in the response (may be {@code null}).
     */
    public NaaviNotImplementedException(String i18nKey, String message, Object extra) {
        super(HttpStatus.NOT_IMPLEMENTED, i18nKey, message, extra);
    }
}
