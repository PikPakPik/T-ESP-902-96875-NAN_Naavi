package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.HikeHistory;
import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class HikeHistoryListener {
    /**
     * @param hikeHistory The hikeHistory entity being persisted.
     */
    @PrePersist
    protected void onCreate(HikeHistory hikeHistory) {
        if (hikeHistory.getCreatedAt() == null) {
            hikeHistory.setCreatedAt(LocalDateTime.now());
        }
    }
}