package fr.naavi.hike.converter;

import fr.naavi.hike.enums.MapElementEnum;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class MapElementConverterTest {

    private MapElementCategoryConverter converter;

    @BeforeEach
    void setUp() {
        converter = new MapElementCategoryConverter();
    }

    @Test
    void shouldConvertToDatabaseColumn_WhenValidListProvided() {
        List<MapElementEnum> seasons = List.of(
                MapElementEnum.MUST_SEE_SPOT,
                MapElementEnum.MONUMENT,
                MapElementEnum.WATER,
                MapElementEnum.ACCOMMODATION,
                MapElementEnum.BIVOUAC,
                MapElementEnum.RESTAURANT,
                MapElementEnum.TOILET,
                MapElementEnum.PARKING,
                MapElementEnum.ACTIVITY
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

        List<MapElementEnum> result = converter.convertToEntityAttribute(dbData);

        assertThat(result).containsExactly(
                MapElementEnum.MUST_SEE_SPOT,
                MapElementEnum.MONUMENT,
                MapElementEnum.WATER,
                MapElementEnum.ACCOMMODATION,
                MapElementEnum.BIVOUAC,
                MapElementEnum.RESTAURANT,
                MapElementEnum.TOILET,
                MapElementEnum.PARKING,
                MapElementEnum.ACTIVITY
        );
    }

    @Test
    void shouldReturnEmptyList_WhenEmptyStringProvided() {
        List<MapElementEnum> result = converter.convertToEntityAttribute("[]");

        assertThat(result).isNotNull().isEmpty();
    }
}
