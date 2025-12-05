package fr.naavi.core.converter;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import tools.jackson.core.JacksonException;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.util.List;

@SuppressWarnings("unused")
@Converter
public abstract class ListConverter<T> implements AttributeConverter<List<T>, String> {
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final TypeReference<List<T>> typeReference;

    /**
     * Constructor for ListConverter.
     *
     * @param typeReference TypeReference&lt;List&lt;T&gt;&gt;
     */
    protected ListConverter(TypeReference<List<T>> typeReference) {
        this.typeReference = typeReference;
    }

    @Override
    public String convertToDatabaseColumn(List<T> attribute) {
        try {
            return objectMapper.writeValueAsString(attribute);
        } catch (JacksonException e) {
            return "[]";
        }
    }

    @Override
    public List<T> convertToEntityAttribute(String databaseValue) {
        try {
            return objectMapper.readValue(databaseValue, typeReference);
        } catch (JacksonException e) {
            return List.of();
        }
    }
}
