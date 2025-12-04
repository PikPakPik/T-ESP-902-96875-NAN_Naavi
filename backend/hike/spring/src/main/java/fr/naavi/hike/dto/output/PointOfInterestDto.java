package fr.naavi.hike.dto.output;

import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.enums.StatusEnum;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;
import java.util.List;

@Schema(description = "Informations sur un Point d'intérêt")
public class PointOfInterestDto {
    @Schema(description = "Identifiant du point d'intérêt", example = "1")
    private final Long id;

    @Schema(description = "Nom du point d'intérêt", example = "Parc national des Paysages")
    private final String name;

    @Schema(description = "Description du point d'intérêt")
    private final String description;

    @Schema(description = "Latitude du point d'intérêt", example = "47.2180438348419")
    private final Double latitude;

    @Schema(description = "Longitude du point d'intérêt", example = "-1.5549507712791397")
    private final Double longitude;

    @ArraySchema(schema = @Schema(
            description = "Liste des catégories du point d'intérêt",
            implementation = PointOfInterestCategoryEnum.class)
    )
    private final List<PointOfInterestCategoryEnum> categories;

    @Schema(description = "Statut du point d'intérêt", example = "PUBLISHED", implementation = StatusEnum.class)
    private final StatusEnum status;

    @Schema(description = "Date de création du point d'intérêt", example = "2024-06-01T12:00:00")
    private final LocalDateTime createdAt;

    @Schema(description = "Date de modification du point d'intérêt", example = "2024-06-08T12:00:00")
    private final LocalDateTime updatedAt;

    /**
     * Constructor for PointOfInterestDto.
     *
     * @param pointOfInterest The point of interest to output.
     * @param showId True if the id should be shown, false otherwise.
     */
    public PointOfInterestDto(PointOfInterest pointOfInterest, boolean showId) {
        this.id = showId ? pointOfInterest.getId() : null;
        this.name = pointOfInterest.getName();
        this.description = pointOfInterest.getDescription();
        this.latitude = pointOfInterest.getLatitude();
        this.longitude = pointOfInterest.getLongitude();
        this.categories = pointOfInterest.getCategories();
        this.status = pointOfInterest.getStatus();
        this.createdAt = pointOfInterest.getCreatedAt();
        this.updatedAt = pointOfInterest.getUpdatedAt();
    }

    public Long getId() {
        return id;
    }

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

    public List<PointOfInterestCategoryEnum> getCategories() {
        return categories;
    }

    public StatusEnum getStatus() {
        return status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
}
