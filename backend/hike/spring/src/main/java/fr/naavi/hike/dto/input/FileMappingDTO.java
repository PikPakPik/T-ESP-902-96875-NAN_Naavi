package fr.naavi.hike.dto.input;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.Map;

@Data
public class FileMappingDTO {

    @NotEmpty
    private Map<
                @NotBlank String,
                @NotNull FieldMappingDTO
                > mappings;
}

