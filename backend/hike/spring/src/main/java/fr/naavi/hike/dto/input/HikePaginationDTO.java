package fr.naavi.hike.dto.input;

import fr.naavi.core.dto.PaginationDTO;
import fr.naavi.hike.enums.DifficultyEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public class HikePaginationDTO extends PaginationDTO {
    @Schema(description = "Latitude de la position de référence", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull
    private Double latitude;

    @Schema(description = "Longitude de la position de référence", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull
    private Double longitude;

    @Schema(description = "Rayon de recherche des randonnées", requiredMode = Schema.RequiredMode.NOT_REQUIRED, defaultValue = "20", minimum = "1", maximum = "100")
    @Min(value = 1, message = "The radius must be greater than 0.")
    @Max(value = 100, message = "The radius cannot exceed 100.")
    private Integer radius = 20;

    @Schema(description = "Distance maximum de la randonnée", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private Integer distance;

    @Schema(description = "Difficulté de la randonnée", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private DifficultyEnum difficulty;

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public Integer getRadius() {
        return radius;
    }

    public void setRadius(Integer radius) {
        this.radius = radius;
    }

    public Integer getDistance() {
        return distance;
    }

    public void setDistance(Integer distance) {
        this.distance = distance;
    }

    public DifficultyEnum getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(DifficultyEnum difficulty) {
        this.difficulty = difficulty;
    }
}
