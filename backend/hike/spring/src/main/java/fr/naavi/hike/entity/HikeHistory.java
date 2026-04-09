package fr.naavi.hike.entity;

import fr.naavi.hike.entitylistener.HikeHistoryListener;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.FetchType;
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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hike_id", nullable = false)
    private Hike hike;

    @Column(name = "duration")
    private Integer duration;

    @Column(name = "distance")
    private Double distance;

    @Column(name = "elevation_gain")
    private Integer elevationGain;

    @Column(name = "average_speed")
    private Double averageSpeed;

    @Column(name = "wkb_geometry", columnDefinition = "TEXT")
    private String wkbGeometry;

    @Column(name = "starting_point_latitude")
    private Double startingPointLatitude;

    @Column(name = "starting_point_longitude")
    private Double startingPointLongitude;

    @Column(name = "arrival_point_latitude")
    private Double arrivalPointLatitude;

    @Column(name = "arrival_point_longitude")
    private Double arrivalPointLongitude;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /** {@code createdAt} est renseigné à la persistance si encore {@code null}. */
    public HikeHistory() {
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

    /**
     * @return The distance of the hike in meters.
     */
    public Double getDistance() {
        return distance;
    }

    /**
     * @param distance The distance of the hike in meters.
     */
    public void setDistance(Double distance) {
        this.distance = distance;
    }

    /**
     * @return The elevation gain of the hike in meters.
     */
    public Integer getElevationGain() {
        return elevationGain;
    }

    /**
     * @param elevationGain The elevation gain of the hike in meters.
     */
    public void setElevationGain(Integer elevationGain) {
        this.elevationGain = elevationGain;
    }

    /**
     * @return The average speed in km/h.
     */
    public Double getAverageSpeed() {
        return averageSpeed;
    }

    /**
     * @param averageSpeed The average speed in km/h.
     */
    public void setAverageSpeed(Double averageSpeed) {
        this.averageSpeed = averageSpeed;
    }

    /**
     * @return The hike trace in WKB format.
     */
    public String getWkbGeometry() {
        return wkbGeometry;
    }

    /**
     * @param wkbGeometry The hike trace in WKB format.
     */
    public void setWkbGeometry(String wkbGeometry) {
        this.wkbGeometry = wkbGeometry;
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
     * @return The longitude of the arrival point.
     */
    public Double getArrivalPointLongitude() {
        return arrivalPointLongitude;
    }

    /**
     * @param arrivalPointLongitude The longitude of the arrival point.
     */
    public void setArrivalPointLongitude(Double arrivalPointLongitude) {
        this.arrivalPointLongitude = arrivalPointLongitude;
    }
}