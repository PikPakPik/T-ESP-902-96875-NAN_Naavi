package fr.naavi.core.converter;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;

import java.io.IOException;
import java.util.List;

@SuppressWarnings("unused")
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
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }

    @Override
    public List<T> convertToEntityAttribute(String databaseValue) {
        try {
            return objectMapper.readValue(databaseValue, typeReference);
        } catch (IOException e) {
            return List.of();
        }
    }
}
