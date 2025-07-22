package fr.naavi.core.exception.children;

import fr.naavi.core.exception.GenericHttpException;
import org.springframework.http.HttpStatus;

/**
 * Exception thrown when the service is temporarily unavailable.
 * This exception typically indicates that the server is currently unable
 * to handle the request due to maintenance, overload, or a temporary failure.
 * Responds with HTTP status {@link HttpStatus#SERVICE_UNAVAILABLE}.
 */
public class NaaviServiceUnavailableException extends GenericHttpException {

    /**
     * Constructs a new {@code NaaviServiceUnavailableException} with a default i18n key and message.
     *
     * <p>Default values are:
     * <ul>
     *     <li>i18nKey: {@code "service_unavalable"}</li>
     *     <li>message: {@code "Service unavailable"}</li>
     * </ul>
     * </p>
     */
    public NaaviServiceUnavailableException() {
        this("service_unavalable", "Service unavailable");
    }

    /**
     * Constructs a new {@code NaaviServiceUnavailableException} with the given i18n key and message.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public NaaviServiceUnavailableException(String i18nKey, String message) {
        this(i18nKey, message, null);
    }

    /**
     * Constructs a new {@code NaaviServiceUnavailableException} with the given i18n key, message, and extra data.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param extra   Additional data to include in the response (may be {@code null}).
     */
    public NaaviServiceUnavailableException(String i18nKey, String message, Object extra) {
        super(HttpStatus.SERVICE_UNAVAILABLE, i18nKey, message, extra);
    }
}
