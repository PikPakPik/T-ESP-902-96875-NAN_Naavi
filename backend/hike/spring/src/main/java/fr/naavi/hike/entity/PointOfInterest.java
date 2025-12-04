package fr.naavi.hike.entity;

import fr.naavi.hike.converter.PointOfInterestCategoryConverter;
import fr.naavi.hike.entitylistener.PointOfInterestListener;
import fr.naavi.hike.enums.PointOfInterestCategoryEnum;
import fr.naavi.hike.enums.StatusEnum;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

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

    /**
     * @return The unique identifier of the point of interest.
     */
    public Long getId() {
        return id;
    }

    /**
     * @return The name of the point of interest.
     */
    public String getName() {
        return name;
    }

    /**
     * @param name The name to set for the point of interest.
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * @return The description of the point of interest.
     */
    public String getDescription() {
        return description;
    }

    /**
     * @param description The description to set for the point of interest.
     */
    public void setDescription(String description) {
        this.description = description;
    }

    /**
     * @return The latitude of the point of interest.
     */
    public Double getLatitude() {
        return latitude;
    }

    /**
     * @param latitude The latitude to set for the point of interest.
     */
    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    /**
     * @return The longitude of the point of interest.
     */
    public Double getLongitude() {
        return longitude;
    }

    /**
     * @param longitude The longitude to set for the point of interest.
     */
    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    /**
     * @return The list of categories for the point of interest.
     */
    public List<PointOfInterestCategoryEnum> getCategories() {
        return categories;
    }

    /**
     * @param categories The list of categories to set for the point of interest.
     */
    public void setCategories(List<PointOfInterestCategoryEnum> categories) {
        this.categories = categories;
    }

    /**
     * @return The status of the user, indicating their verification and access level.
     */
    public StatusEnum getStatus() {
        return status;
    }

    /**
     * @param status The status to set for the point of interest, indicating their verification and access level.
     */
    public void setStatus(StatusEnum status) {
        this.status = status;
    }

    /**
     * @return The timestamp when the point of interest was created.
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt The timestamp to set for when the point of interest was created.
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    /**
     * @return The timestamp when the point of interest was last updated.
     */
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    /**
     * @param updatedAt The timestamp to set for when the point of interest was last updated.
     */
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
