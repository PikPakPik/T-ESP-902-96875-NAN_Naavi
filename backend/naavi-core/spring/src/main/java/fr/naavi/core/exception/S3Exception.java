package fr.naavi.core.exception;

public class S3Exception extends RuntimeException {
    /**
     * Constructor for S3Exception.
     *
     * @param message The error message.
     * @param cause The underlying cause of the exception.
     */
    public S3Exception(String message, Throwable cause) {
        super(message, cause);
    }
}
