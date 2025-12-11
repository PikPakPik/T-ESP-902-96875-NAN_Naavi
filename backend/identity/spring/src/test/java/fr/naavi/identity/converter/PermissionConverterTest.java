package fr.naavi.identity.converter;

import fr.naavi.core.enums.PermissionEnum;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PermissionConverterTest {

    private PermissionsConverter converter;

    @BeforeEach
    void setUp() {
        converter = new PermissionsConverter();
    }

    @Test
    void shouldConvertToDatabaseColumn_WhenValidListProvided() {
        List<PermissionEnum> permissions = List.of(
                PermissionEnum.USER_READ,
                PermissionEnum.USER_WRITE,
                PermissionEnum.USER_DELETE
        );

        String result = converter.convertToDatabaseColumn(permissions);

        assertThat(result).contains("USER_READ", "USER_WRITE", "USER_DELETE");
    }

    @Test
    void shouldReturnEmptyString_WhenEmptyListProvided() {
        String result = converter.convertToDatabaseColumn(Collections.emptyList());

        assertThat(result).isEqualTo("[]");
    }

    @Test
    void shouldConvertToEntityAttribute_WhenValidStringProvided() {
        String dbData = "[\"USER_WRITE\",\"USER_READ\",\"USER_DELETE\"]";

        List<PermissionEnum> result = converter.convertToEntityAttribute(dbData);

        assertThat(result).containsExactly(
                PermissionEnum.USER_WRITE,
                PermissionEnum.USER_READ,
                PermissionEnum.USER_DELETE
        );
    }

    @Test
    void shouldReturnEmptyList_WhenEmptyStringProvided() {
        List<PermissionEnum> result = converter.convertToEntityAttribute("[]");

        assertThat(result).isNotNull().isEmpty();
    }
}
