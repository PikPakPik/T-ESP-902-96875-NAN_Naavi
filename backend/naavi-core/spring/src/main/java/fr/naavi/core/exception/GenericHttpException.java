package fr.naavi.core.exception;

import fr.naavi.core.dto.ApiResponseDto;
import org.springframework.http.HttpStatus;

public class GenericHttpException extends RuntimeException {
    private final HttpStatus status;
    private final String i18nKey;
    private final String message;
    private final Object extra;

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
        this(status, i18nKey, message, null);
    }

    /**
     * Exception thrown for generic HTTP errors.
     * This exception is typically used to indicate an error that does not fit
     * into a more specific category.
     *
     * @param status  The HTTP status code associated with the error.
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param extra   The object returned to give more details
     */
    public GenericHttpException(HttpStatus status, String i18nKey, String message, Object extra) {
        super(message);
        this.status = status;
        this.i18nKey = i18nKey;
        this.message = message;
        this.extra = extra;
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

    /**
     * Generates an {@link ApiResponseDto} containing the current exception details.
     *
     * @return a new {@code ApiResponseDto} initialized with the internationalization key,
     *         message, and extra data from this exception.
     */
    public ApiResponseDto generateApiResponseDto() {
        return new ApiResponseDto(i18nKey, message, extra);
    }
}
