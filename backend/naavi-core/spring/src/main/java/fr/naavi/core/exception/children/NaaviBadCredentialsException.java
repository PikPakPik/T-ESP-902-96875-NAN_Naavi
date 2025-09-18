package fr.naavi.core.exception.children;

public class NaaviBadCredentialsException extends NaaviBadRequestException {
    /**
     * Exception thrown when the user provides invalid credentials.
     * This exception is typically used to indicate that the provided
     * username or password is incorrect.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     */
    public NaaviBadCredentialsException(String i18nKey, String message) {
        super(i18nKey, message);
    }

    /**
     * Exception thrown when the user provides invalid credentials.
     * This exception is typically used to indicate that the provided
     * username or password is incorrect.
     *
     * @param i18nKey The internationalization key for the error message.
     * @param message The detailed error message.
     * @param cause   The underlying cause of the exception.
     */
    public NaaviBadCredentialsException(String i18nKey, String message, Throwable cause) {
        super(i18nKey, message, cause);
    }
}
