package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.StatusEnum;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;

import java.time.LocalDateTime;

public class HikeListener {
    /**
     * @param hike The hike entity being persisted.
     */
    @PrePersist
    protected void onCreate(Hike hike) {
        hike.setCreatedAt(LocalDateTime.now());
        if (hike.getStatus() == null) {
            hike.setStatus(StatusEnum.DRAFT);
        }
    }

    /**
     * @param hike The hike entity being persisted.
     */
    @PreUpdate
    protected void onUpdate(Hike hike) {
        hike.setUpdatedAt(LocalDateTime.now());
    }
}