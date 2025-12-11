package fr.naavi.identity.converter;

import tools.jackson.core.type.TypeReference;
import fr.naavi.core.converter.ListConverter;
import fr.naavi.core.enums.RoleEnum;
import jakarta.persistence.Converter;

@Converter
public class RolesConverter extends ListConverter<RoleEnum> {
    /**
     * Constructs a RolesConverter.
     */
    public RolesConverter() {
        super(new TypeReference<>() {});
    }
}