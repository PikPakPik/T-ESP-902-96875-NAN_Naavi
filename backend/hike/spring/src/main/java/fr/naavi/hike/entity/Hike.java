package fr.naavi.hike.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import fr.naavi.hike.entitylistener.HikeListener;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.SourceEnum;
import fr.naavi.hike.enums.VisibilityEnum;
import fr.naavi.hike.enums.ReactionEnum;
import fr.naavi.hike.enums.StatusEnum;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Entity(name = "hikes")
@EntityListeners(HikeListener.class)
public class Hike {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name")
    private String name;

    @Column(name = "starting_point_latitude")
    private Double startingPointLatitude;

    @Column(name = "starting_point_longitude")
    private Double startingPointLongitude;

    @Column(name = "starting_elevation")
    private Integer startingElevation;

    @Column(name = "arrival_elevation")
    private Integer arrivalElevation;

    @Column(name = "arrival_point_latitude")
    private Double arrivalPointLatitude;

    @Column(name = "arrival_point_longitude")
    private Double arrivalPointLongitude;

    @Column(name = "wkb_geometry", columnDefinition = "TEXT")
    private String wkbGeometry;

    @Column(name = "wkb_waypoints", columnDefinition = "TEXT")
    private String wkbWaypoints;

    @Column(name = "distance")
    private Double distance;

    @Column(name = "duration")
    private Double duration;

    @Column(name = "location")
    private String location;

    @Enumerated(EnumType.STRING)
    private DifficultyEnum difficulty;

    @Enumerated(EnumType.STRING)
    private SourceEnum source;

    @Column(name = "user_id")
    private Long userId;

    @Enumerated(EnumType.STRING)
    private VisibilityEnum visibility;

    @Enumerated(EnumType.STRING)
    private StatusEnum status;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "hike", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<HikeHistory> histories = new ArrayList<>();

    @ManyToMany(targetEntity = Media.class)
    private List<Media> images = new ArrayList<>();

    @OneToMany(mappedBy = "hike", fetch = FetchType.LAZY, orphanRemoval = true)
    @JsonIgnore
    private List<HikeReaction> reactions = new ArrayList<>();

    @Transient
    public long getLikesCount() {
        return reactions.stream().filter(r -> r.getReaction() == ReactionEnum.LIKE).count();
    }

    @Transient
    public long getDislikesCount() {
        return reactions.stream().filter(r -> r.getReaction() == ReactionEnum.DISLIKE).count();
    }
}
