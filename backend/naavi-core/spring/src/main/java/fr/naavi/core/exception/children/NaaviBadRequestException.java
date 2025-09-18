package fr.naavi.core.exception.children;

import fr.naavi.core.exception.GenericHttpException;
import org.springframework.http.HttpStatus;

public class NaaviBadRequestException extends GenericHttpException {

    /**
     * Constructs a Bad Request exception with an internationalization key and a detailed message.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message for logging or client response.
     */
    public NaaviBadRequestException(String i18nKey, String message) {
        super(HttpStatus.BAD_REQUEST, i18nKey, message);
    }

    /**
     * Constructs a Bad Request exception with an internationalization key, a detailed message,
     * and an underlying cause.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message for logging or client response.
     * @param cause   The underlying cause of the exception.
     */
    public NaaviBadRequestException(String i18nKey, String message, Throwable cause) {
        super(HttpStatus.BAD_REQUEST, i18nKey, message, cause);
    }
}
