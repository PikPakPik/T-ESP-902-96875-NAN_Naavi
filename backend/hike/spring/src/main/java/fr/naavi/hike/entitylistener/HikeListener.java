package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.Hike;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.enums.VisibilityEnum;
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
        if (hike.getVisibility() == null) {
            hike.setVisibility(VisibilityEnum.PUBLIC);
        }
        validateSourceAndOwner(hike);
    }

    /**
     * @param hike The hike entity being persisted.
     */
    @PreUpdate
    protected void onUpdate(Hike hike) {
        hike.setUpdatedAt(LocalDateTime.now());
        validateSourceAndOwner(hike);
    }

    private void validateSourceAndOwner(Hike hike) {
        if (hike.getSource() == SourceEnum.OFFICIAL && hike.getUserId() != null) {
            throw new IllegalStateException("Official hikes cannot have an owner user.");
        }

        if (hike.getSource() == SourceEnum.COMMUNITY && hike.getUserId() == null) {
            throw new IllegalStateException("Community hikes require an owner user id.");
        }

        if (hike.getSource() == SourceEnum.OFFICIAL && hike.getVisibility() == VisibilityEnum.PRIVATE) {
            throw new IllegalStateException("Official hikes can only be PUBLIC or UNLISTED.");
        }
    }
}