package fr.naavi.hike.dto.output;

import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.StatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

@Schema(description = "Informations sur une randonnée")
public class HikeDto {
    @Schema(description = "Identifiant de la randonnée", example = "1")
    private final Long id;

    @Schema(description = "Nom de la randonnée", example = "Circuit de l'Oratoire au départ de saulges")
    private final String name;

    @Schema(description = "Point de départ de la randonnée (latitude)", example = "47.2180438348419")
    private final Double startingPointLatitude;

    @Schema(description = "Point de départ de la randonnée (longitude)", example = "-1.5549507712791397")
    private final Double startingPointLongitude;

    @Schema(description = "Dénivelé du point de départ", example = "100")
    private final Integer startingElevation;

    @Schema(description = "Point d'arrivée de la randonnée (latitude)", example = "47.2180438348419")
    private final Double arrivalPointLatitude;

    @Schema(description = "Point d'arrivée de la randonnée (longitude)", example = "-1.5549507712791397")
    private final Double arrivalPointLongitude;

    @Schema(description = "Dénivelé du point d'arrivée", example = "200")
    private final Integer arrivalElevation;

    @Schema(description = "Liste des points de la randonnée au format WKB")
    private String wkbGeometry;

    @Schema(description = "Distance de la randonnée en mètre")
    private final Integer distance;

    @Schema(description = "Département situant la randonnée", example = "Mayenne")
    private final String location;

    @Schema(description = "Difficulté de la randonnée", example = "EASY", implementation = DifficultyEnum.class)
    private final DifficultyEnum difficulty;

    @Schema(description = "Statut de la randonnée", example = "PUBLISHED", implementation = StatusEnum.class)
    private final StatusEnum status;

    @Schema(description = "Date de création de la randonnée", example = "2024-06-01T12:00:00")
    private final LocalDateTime createdAt;

    @Schema(description = "Date de dernière modification de la randonnée", example = "2024-06-10T15:30:00")
    private final LocalDateTime updatedAt;

    /**
     * Constructor for HikeDto.
     *
     * @param hike The hike to output.
     * @param showId True if the id should be shown, false otherwise.
     */
    public HikeDto(Hike hike, boolean showId) {
        this.id = showId ? hike.getId() : null;
        this.name = hike.getName();
        this.startingPointLatitude = hike.getStartingPointLatitude();
        this.startingPointLongitude = hike.getStartingPointLongitude();
        this.startingElevation = hike.getStartingElevation();
        this.arrivalPointLatitude = hike.getArrivalPointLatitude();
        this.arrivalPointLongitude = hike.getArrivalPointLongitude();
        this.arrivalElevation = hike.getArrivalElevation();
        this.wkbGeometry = hike.getWkbGeometry();
        this.distance = hike.getDistance();
        this.location = hike.getLocation();
        this.difficulty = hike.getDifficulty();
        this.status = hike.getStatus();
        this.createdAt = hike.getCreatedAt();
        this.updatedAt = hike.getUpdatedAt();
    }

    public Long getId() {
        return id;
    }

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

    public String getLocation() {
        return location;
    }

    public DifficultyEnum getDifficulty() {
        return difficulty;
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
