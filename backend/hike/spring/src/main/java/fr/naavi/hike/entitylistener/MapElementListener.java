package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.enums.StatusEnum;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;

import java.time.LocalDateTime;

public class MapElementListener {
    /**
     * @param mapElement The map element entity being persisted.
     */
    @PrePersist
    protected void onCreate(MapElement mapElement) {
        mapElement.setCreatedAt(LocalDateTime.now());
        if (mapElement.getStatus() == null) {
            mapElement.setStatus(StatusEnum.DRAFT);
        }
    }

    /**
     * @param mapElement The map element entity being persisted.
     */
    @PreUpdate
    protected void onUpdate(MapElement mapElement) {
        mapElement.setUpdatedAt(LocalDateTime.now());
    }
}