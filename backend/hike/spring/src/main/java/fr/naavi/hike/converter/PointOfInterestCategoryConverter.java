package fr.naavi.hike.converter;

import tools.jackson.core.type.TypeReference;
import fr.naavi.core.converter.ListConverter;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import jakarta.persistence.Converter;

@Converter
public class PointOfInterestCategoryConverter extends ListConverter<PointOfInterestCategoryEnum> {
    /**
     * Constructs a PointOfInterestCategoryConverter.
     */
    public PointOfInterestCategoryConverter() {
        super(new TypeReference<>() {
        });
    }
}