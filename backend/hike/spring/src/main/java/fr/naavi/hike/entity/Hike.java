package fr.naavi.hike.entity;

import fr.naavi.hike.converter.SeasonConverter;
import fr.naavi.hike.entitylistener.HikeListener;
import fr.naavi.hike.enums.DifficultyEnum;
import fr.naavi.hike.enums.SeasonEnum;
import fr.naavi.hike.enums.SourceEnum;
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

    @Column(name = "arrival_point_latitude")
    private Double arrivalPointLatitude;

    @Column(name = "arrival_point_longitude")
    private Double arrivalPointLongitude;

    @Column(name = "arrival_elevation")
    private Integer arrivalElevation;

    @Column(name = "wkb_geometry", columnDefinition = "TEXT")
    private String wkbGeometry;

    @Column(name = "wkb_waypoints", columnDefinition = "TEXT")
    private String wkbWaypoints;

    @Column(name = "distance")
    private Integer distance;

    @Column(name = "duration")
    private Integer duration;

    @Column(name = "location")
    private String location;

    @Enumerated(EnumType.STRING)
    private DifficultyEnum difficulty;

    @Enumerated(EnumType.STRING)
    private SourceEnum source;

    @Column(columnDefinition = "text")
    @Convert(converter = SeasonConverter.class)
    private List<SeasonEnum> seasons = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    private StatusEnum status;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column
    private LocalDateTime updatedAt;

    /**
     * @return The unique identifier of the hike.
     */
    public Long getId() {
        return id;
    }

    /**
     * @return The name of the hike.
     */
    public String getName() {
        return name;
    }

    /**
     * @param name The name of the hike.
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * @return The latitude of the starting point.
     */
    public Double getStartingPointLatitude() {
        return startingPointLatitude;
    }

    /**
     * @param startingPointLatitude The latitude of the starting point.
     */
    public void setStartingPointLatitude(Double startingPointLatitude) {
        this.startingPointLatitude = startingPointLatitude;
    }

    /**
     * @return The longitude of the starting point.
     */
    public Double getStartingPointLongitude() {
        return startingPointLongitude;
    }

    /**
     * @param startingPointLongitude The longitude of the starting point.
     */
    public void setStartingPointLongitude(Double startingPointLongitude) {
        this.startingPointLongitude = startingPointLongitude;
    }

    /**
     * @return the startingElevation
     */
    public Integer getStartingElevation() {
        return startingElevation;
    }

    /**
     * @param startingElevation the startingElevation to set
     */
    public void setStartingElevation(Integer startingElevation) {
        this.startingElevation = startingElevation;
    }

    /**
     * @return The latitude of the arrival point.
     */
    public Double getArrivalPointLatitude() {
        return arrivalPointLatitude;
    }

    /**
     * @param arrivalPointLatitude The latitude of the arrival point.
     */
    public void setArrivalPointLatitude(Double arrivalPointLatitude) {
        this.arrivalPointLatitude = arrivalPointLatitude;
    }

    /**
     * @return the arrivalPointLongitude
     */
    public Double getArrivalPointLongitude() {
        return arrivalPointLongitude;
    }

    /**
     * @param arrivalPointLongitude the arrivalPointLongitude to set
     */
    public void setArrivalPointLongitude(Double arrivalPointLongitude) {
        this.arrivalPointLongitude = arrivalPointLongitude;
    }

    /**
     * @return the arrivalElevation
     */
    public Integer getArrivalElevation() {
        return arrivalElevation;
    }

    /**
     * @param arrivalElevation the arrivalElevation to set
     */
    public void setArrivalElevation(Integer arrivalElevation) {
        this.arrivalElevation = arrivalElevation;
    }

    /**
     * @return the wkbGeometry
     */
    public String getWkbGeometry() {
        return wkbGeometry;
    }

    /**
     * @param wkbGeometry the wkbGeometry to set
     */
    public void setWkbGeometry(String wkbGeometry) {
        this.wkbGeometry = wkbGeometry;
    }

    /**
     * @return the wkbWaypoints
     */
    public String getWkbWaypoints() {
        return wkbWaypoints;
    }

    /**
     * @param wkbWaypoints the wkbWaypoints to set
     */
    public void setWkbWaypoints(String wkbWaypoints) {
        this.wkbWaypoints = wkbWaypoints;
    }

    /**
     * @return the distance
     */
    public Integer getDistance() {
        return distance;
    }

    /**
     * @param distance the distance to set
     */
    public void setDistance(Integer distance) {
        this.distance = distance;
    }

    /**
     * @return the duration
     */
    public Integer getDuration() {
        return duration;
    }

    /**
     * @param duration the duration to set
     */
    public void setDuration(Integer duration) {
        this.duration = duration;
    }

    /**
     * @return the location
     */
    public String getLocation() {
        return location;
    }

    /**
     * @param location the location to set
     */
    public void setLocation(String location) {
        this.location = location;
    }

    /**
     * @return The difficulty of the hike.
     */
    public DifficultyEnum getDifficulty() {
        return difficulty;
    }

    /**
     * @param difficulty The difficulty to set for the hike.
     */
    public void setDifficulty(DifficultyEnum difficulty) {
        this.difficulty = difficulty;
    }

    /**
     * @return the source
     */
    public SourceEnum getSource() {
        return source;
    }

    /**
     * @param source the source to set
     */
    public void setSource(SourceEnum source) {
        this.source = source;
    }

    /**
     * @return The list of seasons the hike is available for.
     */
    public List<SeasonEnum> getSeasons() {
        return seasons;
    }

    /**
     * @param seasons The list of seasons to set for the hike.
     */
    public void setSeasons(List<SeasonEnum> seasons) {
        this.seasons = seasons;
    }

    /**
     * @return The status of the user, indicating their verification and access level.
     */
    public StatusEnum getStatus() {
        return status;
    }

    /**
     * @param status The status to set for the user, indicating their verification and access level.
     */
    public void setStatus(StatusEnum status) {
        this.status = status;
    }

    /**
     * @return The timestamp when the user was created.
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt The timestamp to set for when the user was created.
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    /**
     * @return The timestamp when the user was last updated.
     */
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    /**
     * @param updatedAt The timestamp to set for when the user was last updated.
     */
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
