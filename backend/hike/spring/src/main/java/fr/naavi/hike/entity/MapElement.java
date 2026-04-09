package fr.naavi.hike.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import fr.naavi.hike.converter.MapElementCategoryConverter;
import fr.naavi.hike.entitylistener.MapElementListener;
import fr.naavi.hike.enums.MapElementEnum;
import fr.naavi.hike.enums.ReactionEnum;
import fr.naavi.hike.enums.StatusEnum;
import fr.naavi.hike.enums.TypeMapElementEnum;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@Entity(name = "map_elements")
@EntityListeners(MapElementListener.class)
public class MapElement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "text")
    private String description;

    @Column
    private Double latitude;

    @Column
    private Double longitude;

    @Enumerated(EnumType.STRING)
    private StatusEnum status;

    @Column
    @Enumerated(EnumType.STRING)
    private TypeMapElementEnum type;

    @Column(columnDefinition = "text")
    @Convert(converter = MapElementCategoryConverter.class)
    private List<MapElementEnum> categories = new ArrayList<>();

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column
    private LocalDateTime updatedAt;

    @ManyToMany(targetEntity = Media.class)
    private List<Media> images = new ArrayList<>();

    @OneToMany(mappedBy = "mapElement", fetch = FetchType.LAZY, orphanRemoval = true)
    @JsonIgnore
    private List<MapElementReaction> reactions = new ArrayList<>();

    @Transient
    public long getLikesCount() {
        return reactions.stream().filter(r -> r.getReaction() == ReactionEnum.LIKE).count();
    }

    @Transient
    public long getDislikesCount() {
        return reactions.stream().filter(r -> r.getReaction() == ReactionEnum.DISLIKE).count();
    }
}