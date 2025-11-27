package fr.naavi.hike.entity;

import fr.naavi.hike.entitylistener.HikeHistoryListener;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

import java.time.LocalDateTime;

@Entity(name = "hike_history")
@EntityListeners(HikeHistoryListener.class)
public class HikeHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long user;

    @ManyToOne()
    @JoinColumn(name = "hike_id", nullable = false)
    private Hike hike;

    @Column(name = "duration")
    private Integer duration;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Default constructor that initializes createdAt with the current timestamp.
     */
    public HikeHistory() {
        this.createdAt = LocalDateTime.now();
    }

    /**
     * @return The unique identifier of the hike history entry.
     */
    public Long getId() {
        return id;
    }

    /**
     * @return The identifier of the user who completed the hike.
     */
    public Long getUser() {
        return user;
    }

    /**
     * @param user The identifier of the user who completed the hike.
     */
    public void setUser(Long user) {
        this.user = user;
    }

    /**
     * @return The identifier of the hike that was completed.
     */
    public Hike getHike() {
        return hike;
    }

    /**
     * @param hike The identifier of the hike that was completed.
     */
    public void setHike(Hike hike) {
        this.hike = hike;
    }

    /**
     * @return the duration of the hike in seconds.
     */
    public Integer getDuration() {
        return duration;
    }

    /**
     * @param duration The duration of the hike in seconds.
     */
    public void setDuration(Integer duration) {
        this.duration = duration;
    }

    /**
     * @return The timestamp when the hike was completed.
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt The timestamp when the hike was completed.
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}