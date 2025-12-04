package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.PointOfInterest;
import fr.naavi.hike.enums.StatusEnum;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;

import java.time.LocalDateTime;

public class PointOfInterestListener {
    /**
     * @param pointOfInterest The point of interest entity being persisted.
     */
    @PrePersist
    protected void onCreate(PointOfInterest pointOfInterest) {
        pointOfInterest.setCreatedAt(LocalDateTime.now());
        if (pointOfInterest.getStatus() == null) {
            pointOfInterest.setStatus(StatusEnum.DRAFT);
        }
    }

    /**
     * @param pointOfInterest The point of interest entity being persisted.
     */
    @PreUpdate
    protected void onUpdate(PointOfInterest pointOfInterest) {
        pointOfInterest.setUpdatedAt(LocalDateTime.now());
    }
}