package fr.naavi.hike.dto.input;

import fr.naavi.core.validation.ValidationGroups;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.enums.StatusEnum;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public class PointOfInterestDTO {
    @Schema(description = "Nom du point d'intérêt", example = "Parc national des Paysages")
    @NotNull(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    @NotEmpty(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    private String name;

    @Schema(description = "Nom du point d'intérêt", example = "Parc national des Paysages")
    @NotNull(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    @NotEmpty(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    private String description;

    @Schema(description = "Latitude du point d'intérêt", example = "47.2180438348419")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double latitude;

    @Schema(description = "Longitude du point d'intérêt", example = "-1.5549507712791397")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double longitude;

    @ArraySchema(schema = @Schema(
            description = "Liste des catégories du point d'intérêt",
            implementation = PointOfInterestCategoryEnum.class)
    )
    private List<String> categories;

    @Schema(description = "Statut du point d'intérêt", example = "PUBLISHED", implementation = StatusEnum.class)
    private String status;

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public Double getLatitude() {
        return latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public List<String> getCategories() {
        return categories;
    }

    public String getStatus() {
        return status;
    }
}
