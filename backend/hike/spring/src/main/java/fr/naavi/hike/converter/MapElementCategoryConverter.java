package fr.naavi.hike.converter;

import fr.naavi.hike.enums.MapElementEnum;
import tools.jackson.core.type.TypeReference;
import fr.naavi.core.converter.ListConverter;
import jakarta.persistence.Converter;

@Converter
public class MapElementCategoryConverter extends ListConverter<MapElementEnum> {
    /**
     * Constructs a PointOfInterestCategoryConverter.
     */
    public MapElementCategoryConverter() {
        super(new TypeReference<>() {
        });
    }
}