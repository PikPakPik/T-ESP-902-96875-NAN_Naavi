package fr.naavi.hike.exception;

public class FileImportException extends RuntimeException {
    /**
     * Constructor for FileImportException.
     *
     * @param message The error message.
     */
    public FileImportException(String message) {
        super(message);
    }

    /**
     * Constructor for FileImportException.
     *
     * @param message The error message.
     * @param cause The cause of the exception.
     */
    public FileImportException(String message, Throwable cause) {
        super(message, cause);
    }
}
