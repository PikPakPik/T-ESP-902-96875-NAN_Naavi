package fr.naavi.hike.entity;

import fr.naavi.hike.composite.HikeReactionId;
import fr.naavi.hike.entitylistener.HikeReactionListener;
import fr.naavi.hike.enums.ReactionEnum;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "hike_reactions")
@EntityListeners(HikeReactionListener.class)
public class HikeReaction {
    @EmbeddedId
    private HikeReactionId id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("hikeId")
    @JoinColumn(name = "hike_id", nullable = false)
    private Hike hike;

    @Enumerated(EnumType.STRING)
    private ReactionEnum reaction;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
