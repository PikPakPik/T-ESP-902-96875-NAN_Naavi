package fr.naavi.hike.dto.output;

import fr.naavi.hike.entity.HikeHistory;
import fr.naavi.hike.enums.StatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

@Schema(description = "Informations sur une randonnée")
public class HikeHistoryDto {
    @Schema(description = "Identifiant de la randonnée", example = "1")
    private final Long id;

    @Schema(description = "Nom de la randonnée", example = "Circuit de l'Oratoire au départ de saulges")
    private final String hike;

    @Schema(description = "Identifiant de la randonnée liée", example = "42")
    private final Long hikeId;

    @Schema(description = "Durée de la randonnée (en secondes)", example = "3600")
    private final Integer duration;

    @Schema(description = "Distance parcourue (en mètres)", example = "12500")
    private final Double distance;

    @Schema(description = "Dénivelé positif (en mètres)", example = "450")
    private final Integer elevationGain;

    @Schema(description = "Vitesse moyenne (en km/h)", example = "4.2")
    private final Double averageSpeed;

    @Schema(description = "Tracé de la randonnée au format WKB")
    private final String wkbGeometry;

    @Schema(description = "Latitude du point de départ", example = "47.2180438348419")
    private final Double startingPointLatitude;

    @Schema(description = "Longitude du point de départ", example = "-1.5549507712791397")
    private final Double startingPointLongitude;

    @Schema(description = "Latitude du point d'arrivée", example = "47.2180438348419")
    private final Double arrivalPointLatitude;

    @Schema(description = "Longitude du point d'arrivée", example = "-1.5549507712791397")
    private final Double arrivalPointLongitude;

    @Schema(description = "Date de création de la randonnée", example = "2024-06-01T12:00:00")
    private final LocalDateTime createdAt;

    @Schema(description = "Indique si la randonnée liée a été supprimée", example = "false")
    private final boolean hikeDeleted;

    /**
     * Constructor for HikeDto.
     *
     * @param hikeHistory The hike to output.
     * @param showId True if the id should be shown, false otherwise.
     */
    public HikeHistoryDto(HikeHistory hikeHistory, boolean showId) {
        this.id = showId ? hikeHistory.getId() : null;
        this.hike = hikeHistory.getHike() != null
            ? hikeHistory.getHike().getName()
            : null;
        this.hikeId = hikeHistory.getHike() != null
            ? hikeHistory.getHike().getId()
            : null;
        this.hikeDeleted = hikeHistory.getHike() != null
            && hikeHistory.getHike().getStatus() == StatusEnum.DELETED;
        this.duration = hikeHistory.getDuration();
        this.distance = hikeHistory.getDistance() != null
            ? hikeHistory.getDistance()
            : hikeHistory.getHike() != null ? hikeHistory.getHike().getDistance() : null;
        this.elevationGain = buildElevationGain(hikeHistory);
        this.averageSpeed = buildAverageSpeed(hikeHistory);
        this.wkbGeometry = hikeHistory.getWkbGeometry() != null
            ? hikeHistory.getWkbGeometry()
            : hikeHistory.getHike() != null ? hikeHistory.getHike().getWkbGeometry() : null;
        this.startingPointLatitude = hikeHistory.getStartingPointLatitude() != null
            ? hikeHistory.getStartingPointLatitude()
            : hikeHistory.getHike() != null ? hikeHistory.getHike().getStartingPointLatitude() : null;
        this.startingPointLongitude = hikeHistory.getStartingPointLongitude() != null
            ? hikeHistory.getStartingPointLongitude()
            : hikeHistory.getHike() != null ? hikeHistory.getHike().getStartingPointLongitude() : null;
        this.arrivalPointLatitude = hikeHistory.getArrivalPointLatitude() != null
            ? hikeHistory.getArrivalPointLatitude()
            : hikeHistory.getHike() != null ? hikeHistory.getHike().getArrivalPointLatitude() : null;
        this.arrivalPointLongitude = hikeHistory.getArrivalPointLongitude() != null
            ? hikeHistory.getArrivalPointLongitude()
            : hikeHistory.getHike() != null ? hikeHistory.getHike().getArrivalPointLongitude() : null;
        this.createdAt = hikeHistory.getCreatedAt();
    }

    public Long getId() {
        return id;
    }

    public String getHike() {
        return hike;
    }

    public Long getHikeId() {
        return hikeId;
    }

    public Integer getDuration() {
        return duration;
    }

    public Double getDistance() {
        return distance;
    }

    public Integer getElevationGain() {
        return elevationGain;
    }

    public Double getAverageSpeed() {
        return averageSpeed;
    }

    public String getWkbGeometry() {
        return wkbGeometry;
    }

    public Double getStartingPointLatitude() {
        return startingPointLatitude;
    }

    public Double getStartingPointLongitude() {
        return startingPointLongitude;
    }

    public Double getArrivalPointLatitude() {
        return arrivalPointLatitude;
    }

    public Double getArrivalPointLongitude() {
        return arrivalPointLongitude;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public boolean isHikeDeleted() {
        return hikeDeleted;
    }

    private Integer buildElevationGain(HikeHistory hikeHistory) {
        if (hikeHistory.getElevationGain() != null) {
            return hikeHistory.getElevationGain();
        }
        if (
                hikeHistory.getHike() == null
                        || hikeHistory.getHike().getStartingElevation() == null
                        || hikeHistory.getHike().getArrivalElevation() == null
        ) {
            return null;
        }

        int gain = hikeHistory.getHike().getArrivalElevation()
                - hikeHistory.getHike().getStartingElevation();
        return Math.max(gain, 0);
    }

    private Double buildAverageSpeed(HikeHistory hikeHistory) {
        if (hikeHistory.getAverageSpeed() != null) {
            return hikeHistory.getAverageSpeed();
        }
        if (
                hikeHistory.getDuration() == null
                        || hikeHistory.getDuration() <= 0
                        || hikeHistory.getHike() == null
                        || hikeHistory.getHike().getDistance() == null
        ) {
            return null;
        }

        double distanceKm = hikeHistory.getHike().getDistance() / 1000d;
        double durationHours = hikeHistory.getDuration() / 3600d;
        if (durationHours <= 0) {
            return null;
        }

        return distanceKm / durationHours;
    }
}
