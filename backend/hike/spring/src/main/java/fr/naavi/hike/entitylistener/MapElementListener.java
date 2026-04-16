package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.MapElement;
import fr.naavi.hike.enums.SourceEnum;
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
        validateSourceAndOwner(mapElement);
    }

    /**
     * @param mapElement The map element entity being persisted.
     */
    @PreUpdate
    protected void onUpdate(MapElement mapElement) {
        mapElement.setUpdatedAt(LocalDateTime.now());
        validateSourceAndOwner(mapElement);
    }

    private void validateSourceAndOwner(MapElement mapElement) {
        if (mapElement.getSource() == SourceEnum.OFFICIAL && mapElement.getUserId() != null) {
            throw new IllegalStateException("Official map elements cannot have an owner user.");
        }

        if (mapElement.getSource() == SourceEnum.COMMUNITY && mapElement.getUserId() == null) {
            throw new IllegalStateException("Community map elements require an owner user id.");
        }
    }
}
