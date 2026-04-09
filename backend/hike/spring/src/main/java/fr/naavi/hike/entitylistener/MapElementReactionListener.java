package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.MapElementReaction;
import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class MapElementReactionListener {
    /**
     * @param mapElementReaction The map element entity being persisted.
     */
    @PrePersist
    protected void onCreate(MapElementReaction mapElementReaction) {
        mapElementReaction.setCreatedAt(LocalDateTime.now());
    }
}