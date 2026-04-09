package fr.naavi.hike.composite;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.Data;

import java.io.Serializable;

@Data
@Embeddable
public class HikeReactionId implements Serializable {
    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "hike_id", nullable = false)
    private Long hikeId;
}