package fr.naavi.identity.converter;

import tools.jackson.core.type.TypeReference;
import fr.naavi.core.converter.ListConverter;
import fr.naavi.core.enums.PermissionEnum;
import jakarta.persistence.Converter;

@Converter
public class PermissionsConverter extends ListConverter<PermissionEnum> {
    /**
     * Constructs a PermissionsConverter.
     */
    public PermissionsConverter() {
        super(new TypeReference<>() {});
    }
}