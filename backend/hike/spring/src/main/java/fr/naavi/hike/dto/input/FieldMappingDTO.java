package fr.naavi.hike.dto.input;

import fr.naavi.hike.enums.UnitEnum;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.Map;

@Data
public class FieldMappingDTO {
    @NotBlank
    private String source;

    private UnitEnum unit;

    private Map<String, String> values;
}
