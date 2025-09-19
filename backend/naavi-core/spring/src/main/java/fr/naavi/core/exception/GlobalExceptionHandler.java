package fr.naavi.core.exception;

import fr.naavi.core.dto.ApiResponseDTO;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {
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
        return new ResponseEntity<>(response, HttpStatus.UNPROCESSABLE_ENTITY);
    }
}