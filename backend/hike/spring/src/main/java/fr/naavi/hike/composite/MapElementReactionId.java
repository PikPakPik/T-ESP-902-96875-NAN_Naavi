package fr.naavi.hike.composite;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.Data;

import java.io.Serializable;

@Data
@Embeddable
public class MapElementReactionId implements Serializable {
    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "map_element_id", nullable = false)
    private Long mapElementId;
}