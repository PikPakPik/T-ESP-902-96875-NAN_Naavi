package fr.naavi.hike.entitylistener;

import fr.naavi.hike.entity.Media;
import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class MediaListener {
    /**
     * @param media The media entity being persisted.
     */
    @PrePersist
    protected void onCreate(Media media) {
        media.setCreatedAt(LocalDateTime.now());
    }
}