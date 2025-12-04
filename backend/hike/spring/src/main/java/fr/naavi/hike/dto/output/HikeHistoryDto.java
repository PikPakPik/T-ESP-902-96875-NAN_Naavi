package fr.naavi.hike.dto.output;

import fr.naavi.hike.entity.HikeHistory;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

@Schema(description = "Informations sur une randonnée")
public class HikeHistoryDto {
    @Schema(description = "Identifiant de la randonnée", example = "1")
    private final Long id;

    @Schema(description = "Nom de la randonnée", example = "Circuit de l'Oratoire au départ de saulges")
    private final String hike;

    @Schema(description = "Durée de la randonnée (en secondes)", example = "3600")
    private final Integer duration;

    @Schema(description = "Date de création de la randonnée", example = "2024-06-01T12:00:00")
    private final LocalDateTime createdAt;

    /**
     * Constructor for HikeDto.
     *
     * @param hikeHistory The hike to output.
     * @param showId True if the id should be shown, false otherwise.
     */
    public HikeHistoryDto(HikeHistory hikeHistory, boolean showId) {
        this.id = showId ? hikeHistory.getId() : null;
        this.hike = hikeHistory.getHike().getName();
        this.duration = hikeHistory.getDuration();
        this.createdAt = hikeHistory.getCreatedAt();
    }

    public Long getId() {
        return id;
    }

    public String getHike() {
        return hike;
    }

    public Integer getDuration() {
        return duration;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
