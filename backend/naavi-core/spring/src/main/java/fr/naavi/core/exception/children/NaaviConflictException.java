package fr.naavi.core.exception.children;

import fr.naavi.core.exception.GenericHttpException;
import org.springframework.http.HttpStatus;

/**
 * Exception thrown when a conflict occurs in the application.
 * This exception is typically used to indicate that a requested operation
 * could not be completed due to a conflict with the current state of the resource.
 * For example, attempting to create a resource that already exists.
 */
public class NaaviConflictException extends GenericHttpException {
    /**
     * Constructs a new {@code NaaviConflictException} with the given i18n key and message.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public NaaviConflictException(String i18nKey, String message) {
        this(i18nKey, message, null);
    }

    /**
     * Constructs a new {@code NaaviConflictException} with the given i18n key, message, and extra data.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param extra   Additional data to include in the response (may be {@code null}).
     */
    public NaaviConflictException(String i18nKey, String message, Object extra) {
        super(HttpStatus.CONFLICT, i18nKey, message, extra);
    }
}
