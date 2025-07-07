package fr.naavi.core.exception;

import org.springframework.http.HttpStatus;

public class GenericHttpException extends RuntimeException {
    private final HttpStatus status;
    private final String i18nKey;
    private final String message;

    /**
     * Exception thrown for generic HTTP errors.
     * This exception is typically used to indicate an error that does not fit
     * into a more specific category.
     *
     * @param status  The HTTP status code associated with the error.
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public GenericHttpException(HttpStatus status, String i18nKey, String message) {
        super(message);
        this.status = status;
        this.i18nKey = i18nKey;
        this.message = message;
    }

    /**
     * Exception thrown for generic HTTP errors.
     * This exception is typically used to indicate an error that does not fit
     * into a more specific category.
     *
     * @param status  The HTTP status code associated with the error.
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param cause   The underlying cause of the exception.
     */
    public GenericHttpException(HttpStatus status, String i18nKey, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
        this.i18nKey = i18nKey;
        this.message = message;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getI18nKey() {
        return i18nKey;
    }

    public String getMessage() {
        return message;
    }
}
