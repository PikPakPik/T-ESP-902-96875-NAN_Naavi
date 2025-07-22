package fr.naavi.core.exception;

import fr.naavi.core.dto.ApiResponseDto;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ControllerAdvice
public class GlobalExceptionHandler {
    /**
     * Handles GenericHttpException and returns a standardized API response.
     *
     * @param ex The GenericHttpException to handle.
     * @return A ResponseEntity containing the ApiResponseDto with error details.
     */
    @ExceptionHandler(GenericHttpException.class)
    public ResponseEntity<ApiResponseDto> handleGenericHttpException(GenericHttpException ex) {
        return new ResponseEntity<>(ex.generateApiResponseDto(), ex.getStatus());
    }
}