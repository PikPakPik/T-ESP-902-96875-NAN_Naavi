package fr.naavi.hike.converter;

import com.fasterxml.jackson.core.type.TypeReference;
import fr.naavi.core.converter.ListConverter;
import fr.naavi.hike.enums.SeasonEnum;
import jakarta.persistence.Converter;

@Converter
public class SeasonConverter extends ListConverter<SeasonEnum> {
    /**
     * Constructs a SeasonConverter.
     */
    public SeasonConverter() {
        super(new TypeReference<>() {});
    }
}