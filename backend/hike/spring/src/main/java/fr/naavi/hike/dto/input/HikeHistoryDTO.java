package fr.naavi.hike.dto.input;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

public class HikeHistoryDTO {
    @Schema(description = "ID de la randonnée", example = "1")
    @NotNull()
    private Long hikeId;

    @Schema(description = "Temps réaliser pour parcourir la randonnée en seconde", example = "3600")
    @NotNull()
    private Integer duration;

    @Schema(description = "Nom de la randonnée", example = "Circuit de l'Oratoire au départ de saulges")
    private String hike;

    @Schema(description = "Distance parcourue (en mètres)", example = "12500")
    private Double distance;

    @Schema(description = "Dénivelé positif (en mètres)", example = "450")
    private Integer elevationGain;

    @Schema(description = "Vitesse moyenne (en km/h)", example = "4.2")
    private Double averageSpeed;

    @Schema(description = "Tracé de la randonnée au format WKB")
    private String wkbGeometry;

    @Schema(description = "Latitude du point de départ", example = "47.2180438348419")
    private Double startingPointLatitude;

    @Schema(description = "Longitude du point de départ", example = "-1.5549507712791397")
    private Double startingPointLongitude;

    @Schema(description = "Latitude du point d'arrivée", example = "47.2180438348419")
    private Double arrivalPointLatitude;

    @Schema(description = "Longitude du point d'arrivée", example = "-1.5549507712791397")
    private Double arrivalPointLongitude;

    @Schema(description = "Date de création de l'entrée d'historique", example = "2024-06-01T12:00:00")
    private LocalDateTime createdAt;

    public Long getHikeId() {
        return hikeId;
    }

    public Integer getDuration() {
        return duration;
    }

    public String getHike() {
        return hike;
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
}
