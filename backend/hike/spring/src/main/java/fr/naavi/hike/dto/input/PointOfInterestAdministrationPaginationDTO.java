package fr.naavi.hike.dto.input;

import fr.naavi.core.dto.PaginationDTO;
import io.swagger.v3.oas.annotations.media.Schema;

public class PointOfInterestAdministrationPaginationDTO extends PaginationDTO {
    @Schema(description = "Statut du point d'intérêt", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String status;

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
