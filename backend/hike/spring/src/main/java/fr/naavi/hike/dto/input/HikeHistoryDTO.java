package fr.naavi.hike.dto.input;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

public class HikeHistoryDTO {
    @Schema(description = "ID de la randonnée", example = "1")
    @NotNull()
    private Long hikeId;

    @Schema(description = "Temps réaliser pour parcourir la randonnée en seconde", example = "3600")
    @NotNull()
    private Integer duration;

    public Long getHikeId() {
        return hikeId;
    }

    public Integer getDuration() {
        return duration;
    }
}
