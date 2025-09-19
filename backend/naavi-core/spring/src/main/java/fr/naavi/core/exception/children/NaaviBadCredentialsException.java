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
     * @param extra   Additional data to include in the response (may be {@code null}).
     */
    public NaaviBadCredentialsException(String i18nKey, String message, Object extra) {
        super(i18nKey, message, extra);
    }
}
