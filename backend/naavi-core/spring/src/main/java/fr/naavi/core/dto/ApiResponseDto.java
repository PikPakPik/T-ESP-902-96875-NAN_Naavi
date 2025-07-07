package fr.naavi.core.dto;

public class ApiResponseDto {
    private final String i18nKey;
    private final String message;

    /**
     * Constructs an ApiResponseDto with the specified i18n key and message.
     *
     * @param i18nKey The internationalization key for the response message.
     * @param message The message to be returned in the response.
     */
    public ApiResponseDto(String i18nKey, String message) {
        this.i18nKey = i18nKey;
        this.message = message;
    }

    // <editor-fold desc="Getter Only">
    public String getI18nKey() {
        return i18nKey;
    }

    public String getMessage() {
        return message;
    }
    // </editor-fold>
}
