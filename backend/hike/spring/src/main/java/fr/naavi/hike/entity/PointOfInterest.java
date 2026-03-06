package fr.naavi.hike.entity;

import fr.naavi.hike.converter.PointOfInterestCategoryConverter;
import fr.naavi.hike.entitylistener.PointOfInterestListener;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.enums.StatusEnum;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Entity(name = "points_of_interest")
@EntityListeners(PointOfInterestListener.class)
public class PointOfInterest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column
    private String name;

    @Column(columnDefinition = "text")
    private String description;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(columnDefinition = "text")
    @Convert(converter = PointOfInterestCategoryConverter.class)
    private List<PointOfInterestCategoryEnum> categories = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    private StatusEnum status;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column
    private LocalDateTime updatedAt;

    @ManyToMany(targetEntity = Media.class)
    private List<Media> images = new ArrayList<>();
}
