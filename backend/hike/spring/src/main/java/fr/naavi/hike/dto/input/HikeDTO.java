package fr.naavi.hike.dto.input;

import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.core.validation.ValidationGroups;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

public class HikeDTO {
    @Schema(description = "Nom de la randonnée", example = "Circuit de l'Oratoire au départ de saulges")
    @NotNull(groups = { ValidationGroups.OnCreate.class, ValidationGroups.OnUpdate.class })
    private String name;

    @Schema(description = "Point de départ de la randonnée (latitude)", example = "47.2180438348419")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double startingPointLatitude;

    @Schema(description = "Point de départ de la randonnée (longitude)", example = "-1.5549507712791397")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double startingPointLongitude;

    @Schema(description = "Dénivelé du point de départ", example = "100")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Integer startingElevation;

    @Schema(description = "Point d'arrivée de la randonnée (latitude)", example = "47.2180438348419")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double arrivalPointLatitude;

    @Schema(description = "Point d'arrivée de la randonnée (longitude)", example = "-1.5549507712791397")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Double arrivalPointLongitude;

    @Schema(description = "Dénivelé du point d'arrivée", example = "200")
    @NotNull(groups = ValidationGroups.OnCreate.class)
    private Integer arrivalElevation;

    @Schema(description = "Liste des points de la randonnée au format WKB")
    private String wkbGeometry;

    @Schema(description = "Distance de la randonnée en mètre", example = "3600")
    private Integer distance;

    @Schema(description = "Temps moyen de la randonnée en seconde", example = "3600")
    private Integer duration;

    @Schema(description = "Difficulté de la randonnée", example = "EASY", implementation = DifficultyEnum.class)
    private String difficulty;

    @Schema(description = "Statut de la randonnée", example = "PUBLISHED", implementation = StatusEnum.class)
    private String status;

    public String getName() {
        return name;
    }

    public Double getStartingPointLatitude() {
        return startingPointLatitude;
    }

    public Double getStartingPointLongitude() {
        return startingPointLongitude;
    }

    public Integer getStartingElevation() {
        return startingElevation;
    }

    public Double getArrivalPointLatitude() {
        return arrivalPointLatitude;
    }

    public Double getArrivalPointLongitude() {
        return arrivalPointLongitude;
    }

    public Integer getArrivalElevation() {
        return arrivalElevation;
    }

    public String getWkbGeometry() {
        return wkbGeometry;
    }

    public Integer getDistance() {
        return distance;
    }

    public Integer getDuration() {
        return duration;
    }

    public String getDifficulty() {
        return difficulty;
    }

    public String getStatus() {
        return status;
    }
}
