package fr.naavi.core.exception.children;

import fr.naavi.core.exception.GenericHttpException;
import org.springframework.http.HttpStatus;

/**
 * Exception thrown when a user attempts to access a resource they are not authorized to access.
 * This exception typically indicates a lack of necessary permissions or access rights.
 * Responds with HTTP status {@link HttpStatus#FORBIDDEN}.
 */
public class NaaviForbiddenException extends GenericHttpException {

    /**
     * Constructs a new {@code NaaviForbiddenException} with a default i18n key and message.
     *
     * <p>Default values are:
     * <ul>
     *     <li>i18nKey: {@code "forbidden"}</li>
     *     <li>message: {@code "Can't access this resource"}</li>
     * </ul>
     * </p>
     */
    public NaaviForbiddenException() {
        this("forbidden", "Can't access this resource");
    }

    /**
     * Constructs a new {@code NaaviForbiddenException} with the given i18n key and message.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public NaaviForbiddenException(String i18nKey, String message) {
        this(i18nKey, message, null);
    }

    /**
     * Constructs a new {@code NaaviForbiddenException} with the given i18n key, message, and extra data.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param extra   Additional data to include in the response (may be {@code null}).
     */
    public NaaviForbiddenException(String i18nKey, String message, Object extra) {
        super(HttpStatus.FORBIDDEN, i18nKey, message, extra);
    }
}
