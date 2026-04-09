package fr.naavi.hike.dto.input;

import fr.naavi.core.validation.ValidationGroups;
import fr.naavi.hike.enums.MapElementEnum;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@Schema(description = "Données d'entrée génériques pour un élément de carte")
public class MapElementDTO {

    @Schema(description = "Nom de l'élément", example = "Parc national")
    @NotNull(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    @NotEmpty(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    private String name;

    @Schema(description = "Description de l'élément")
    @NotNull(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    @NotEmpty(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    private String description;

    @Schema(description = "Latitude", example = "47.2180438348419")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double latitude;

    @Schema(description = "Longitude", example = "-1.5549507712791397")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double longitude;

    @Schema(description = "Statut de l'élément", example = "PUBLISHED")
    private String status;

    @Schema(description = "Type de l'élément", example = "POINT_OF_INTEREST")
    private String type;

    @ArraySchema(schema = @Schema(
            description = "Liste des catégories de l'élément",
            implementation = MapElementEnum.class
    ))
    private List<String> categories;
}