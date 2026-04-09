package fr.naavi.hike.entity;

import fr.naavi.hike.composite.MapElementReactionId;
import fr.naavi.hike.entitylistener.MapElementReactionListener;
import fr.naavi.hike.enums.ReactionEnum;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "map_element_reactions")
@EntityListeners(MapElementReactionListener.class)
public class MapElementReaction {
    @EmbeddedId
    private MapElementReactionId id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("mapElementId")
    @JoinColumn(name = "map_element_id", nullable = false)
    private MapElement mapElement;

    @Enumerated(EnumType.STRING)
    private ReactionEnum reaction;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
