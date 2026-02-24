package fr.naavi.core.exception;

import fr.naavi.core.dto.ApiResponseDTO;
import fr.naavi.core.utils.ExceptionUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * Handles GenericHttpException and returns a standardized API response.
     *
     * @param ex The GenericHttpException to handle.
     * @return A ResponseEntity containing the ApiResponseDto with error details.
     */
    @ExceptionHandler(GenericHttpException.class)
    public ResponseEntity<ApiResponseDTO> handleGenericHttpException(GenericHttpException ex) {
        return new ResponseEntity<>(ex.generateApiResponseDto(), ex.getStatus());
    }

    /**
     * Handles MethodArgumentNotValidException and returns a standardized API response
     * with validation errors.
     *
     * @param ex The MethodArgumentNotValidException to handle.
     * @return A ResponseEntity containing the ApiResponseDto with validation errors.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponseDTO> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
                errors.put(error.getField(), error.getDefaultMessage())
        );
        ApiResponseDTO response = new ApiResponseDTO(
                "validation.failed",
                "Validation failed",
                errors
        );
        return new ResponseEntity<>(response, HttpStatus.UNPROCESSABLE_CONTENT);
    }

    /**
     * Handles AccessDeniedException (e.g. @PreAuthorize failure) and returns 403 Forbidden.
     *
     * @param ex The AccessDeniedException to handle.
     * @return A ResponseEntity with 403 status.
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponseDTO> handleAccessDeniedException(AccessDeniedException ex) {
        ApiResponseDTO response = new ApiResponseDTO(
                "access.denied",
                "Access denied. You do not have the necessary permissions to access this resource"
        );
        return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
    }

    /**
     * Handles all unhandled exceptions and returns a standardized 500 API response.
     * Logs with stack trace in message so GELF full_message maps to Seq @x (Exception section).
     *
     * @param ex The exception to handle.
     * @return A ResponseEntity containing the ApiResponseDto with error details.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponseDTO> handleException(Exception ex) {
        logUnhandledException(ex);
        return new ResponseEntity<>(
                new ApiResponseDTO("internal.error", "An internal error occurred"),
                HttpStatus.INTERNAL_SERVER_ERROR
        );
    }

    private void logUnhandledException(Exception ex) {
        String message = "Unhandled exception\n" + ExceptionUtils.formatStackTrace(ex);
        log.error(message, ex);
    }
}