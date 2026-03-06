package fr.naavi.hike.converter;

import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PointOfInterestCategoryConverterTest {

    private PointOfInterestCategoryConverter converter;

    @BeforeEach
    void setUp() {
        converter = new PointOfInterestCategoryConverter();
    }

    @Test
    void shouldConvertToDatabaseColumn_WhenValidListProvided() {
        List<PointOfInterestCategoryEnum> seasons = List.of(
                PointOfInterestCategoryEnum.MUST_SEE_SPOT,
                PointOfInterestCategoryEnum.MONUMENT,
                PointOfInterestCategoryEnum.WATER,
                PointOfInterestCategoryEnum.ACCOMMODATION,
                PointOfInterestCategoryEnum.BIVOUAC,
                PointOfInterestCategoryEnum.RESTAURANT,
                PointOfInterestCategoryEnum.TOILET,
                PointOfInterestCategoryEnum.PARKING,
                PointOfInterestCategoryEnum.ACTIVITY
        );

        String result = converter.convertToDatabaseColumn(seasons);

        assertThat(result).contains("MUST_SEE_SPOT", "MONUMENT", "WATER", "ACCOMMODATION", "BIVOUAC", "RESTAURANT", "TOILET", "PARKING", "ACTIVITY");
    }

    @Test
    void shouldReturnEmptyString_WhenEmptyListProvided() {
        String result = converter.convertToDatabaseColumn(Collections.emptyList());

        assertThat(result).isEqualTo("[]");
    }

    @Test
    void shouldConvertToEntityAttribute_WhenValidStringProvided() {
        String dbData = "[\"MUST_SEE_SPOT\", \"MONUMENT\", \"WATER\", \"ACCOMMODATION\", \"BIVOUAC\", \"RESTAURANT\", \"TOILET\", \"PARKING\", \"ACTIVITY\"]";

        List<PointOfInterestCategoryEnum> result = converter.convertToEntityAttribute(dbData);

        assertThat(result).containsExactly(
                PointOfInterestCategoryEnum.MUST_SEE_SPOT,
                PointOfInterestCategoryEnum.MONUMENT,
                PointOfInterestCategoryEnum.WATER,
                PointOfInterestCategoryEnum.ACCOMMODATION,
                PointOfInterestCategoryEnum.BIVOUAC,
                PointOfInterestCategoryEnum.RESTAURANT,
                PointOfInterestCategoryEnum.TOILET,
                PointOfInterestCategoryEnum.PARKING,
                PointOfInterestCategoryEnum.ACTIVITY
        );
    }

    @Test
    void shouldReturnEmptyList_WhenEmptyStringProvided() {
        List<PointOfInterestCategoryEnum> result = converter.convertToEntityAttribute("[]");

        assertThat(result).isNotNull().isEmpty();
    }
}
