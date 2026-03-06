package fr.naavi.hike.entity;

import fr.naavi.hike.entitylistener.MediaListener;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity(name = "medias")
@EntityListeners(MediaListener.class)
public class Media {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "filename", nullable = false)
    private String filename;

    @Column(name = "user_id", nullable = false)
    private Long user;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
