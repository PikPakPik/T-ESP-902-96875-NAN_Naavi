package fr.naavi.core.dto;

public class ApiResponseDTO {
    private final String i18nKey;
    private final String message;
    private final Object extra;

    /**
     * Constructs an ApiResponseDto with the specified i18n key and message.
     *
     * @param i18nKey The internationalization key for the response message.
     * @param message The message to be returned in the response.
     */
    public ApiResponseDTO(String i18nKey, String message) {
        this(i18nKey, message, null);
    }

    /**
     * Constructs an ApiResponseDto with the specified i18n key and message.
     *
     * @param i18nKey The internationalization key for the response message.
     * @param message The message to be returned in the response.
     * @param extra   The object returned to give more details
     */
    public ApiResponseDTO(String i18nKey, String message, Object extra) {
        this.i18nKey = i18nKey;
        this.message = message;
        this.extra = extra;
    }

    // <editor-fold desc="Getter Only">
    public String getI18nKey() {
        return i18nKey;
    }

    public String getMessage() {
        return message;
    }

    public Object getExtra() {
        return extra;
    }
    // </editor-fold>
}
