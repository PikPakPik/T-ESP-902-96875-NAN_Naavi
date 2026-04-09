package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.HikeReaction;
import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class HikeReactionListener {
    /**
     * @param hikeReaction The hike reaction entity being persisted.
     */
    @PrePersist
    protected void onCreate(HikeReaction hikeReaction) {
        hikeReaction.setCreatedAt(LocalDateTime.now());
    }
}