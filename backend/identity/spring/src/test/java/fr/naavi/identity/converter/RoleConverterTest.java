package fr.naavi.identity.converter;

import fr.naavi.core.enums.RoleEnum;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class RoleConverterTest {

    private RolesConverter converter;

    @BeforeEach
    void setUp() {
        converter = new RolesConverter();
    }

    @Test
    void shouldConvertToDatabaseColumn_WhenValidListProvided() {
        List<RoleEnum> permissions = List.of(
                RoleEnum.ROLE_USER,
                RoleEnum.ROLE_ADMIN,
                RoleEnum.ROLE_MODERATOR
        );

        String result = converter.convertToDatabaseColumn(permissions);

        assertThat(result).contains("ROLE_USER", "ROLE_ADMIN", "ROLE_MODERATOR");
    }

    @Test
    void shouldReturnEmptyString_WhenEmptyListProvided() {
        String result = converter.convertToDatabaseColumn(Collections.emptyList());

        assertThat(result).isEqualTo("[]");
    }

    @Test
    void shouldConvertToEntityAttribute_WhenValidStringProvided() {
        String dbData = "[\"ROLE_USER\",\"ROLE_ADMIN\",\"ROLE_MODERATOR\"]";

        List<RoleEnum> result = converter.convertToEntityAttribute(dbData);

        assertThat(result).containsExactly(
                RoleEnum.ROLE_USER,
                RoleEnum.ROLE_ADMIN,
                RoleEnum.ROLE_MODERATOR
        );
    }

    @Test
    void shouldReturnEmptyList_WhenEmptyStringProvided() {
        List<RoleEnum> result = converter.convertToEntityAttribute("[]");

        assertThat(result).isNotNull().isEmpty();
    }
}
