package fr.naavi.identity.entity;

import fr.naavi.identity.entitylistener.SessionListener;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

import java.time.LocalDateTime;

@Entity(name = "sessions")
@EntityListeners(SessionListener.class)
public class Session {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(nullable = false)
    private User user;

    @Column(nullable = false)
    private String accessToken;

    @Column(nullable = false)
    private String refreshToken;

    @Column(nullable = false)
    private String clientIp;

    @Column(nullable = false)
    private String userAgent;

    @Column(nullable = false, updatable = false)
    private LocalDateTime accessTokenExpiredAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime refreshTokenExpiredAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * @return the unique identifier of the session
     */
    public Long getId() {
        return id;
    }

    /**
     * @return the user associated with this session
     */
    public User getUser() {
        return user;
    }

    /**
     * @param user the user to associate with this session
     */
    public void setUser(User user) {
        this.user = user;
    }

    /**
     * @return the access token for this session
     */
    public String getAccessToken() {
        return accessToken;
    }

    /**
     * @param accessToken the access token to set for this session
     */
    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    /**
     * @return the refresh token for this session
     */
    public String getRefreshToken() {
        return refreshToken;
    }

    /**
     * @param refreshToken the refresh token to set for this session
     */
    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    /**
     * @return the IP address of the client that initiated this session
     */
    public String getClientIp() {
        return clientIp;
    }

    /**
     * @param clientIp the IP address of the client to set for this session
     */
    public void setClientIp(String clientIp) {
        this.clientIp = clientIp;
    }

    /**
     * @return the user agent string of the client that initiated this session
     */
    public String getUserAgent() {
        return userAgent;
    }

    /**
     * @param userAgent the user agent string to set for this session
     */
    public void setUserAgent(String userAgent) {
        this.userAgent = userAgent;
    }

    /**
     * @return the expiration time of the access token
     */
    public LocalDateTime getAccessTokenExpiredAt() {
        return accessTokenExpiredAt;
    }

    /**
     * @param accessTokenExpiredAt the expiration time to set for the access token
     */
    public void setAccessTokenExpiredAt(LocalDateTime accessTokenExpiredAt) {
        this.accessTokenExpiredAt = accessTokenExpiredAt;
    }

    /**
     * @return the expiration time of the access token
     */
    public LocalDateTime getRefreshTokenExpiredAt() {
        return refreshTokenExpiredAt;
    }

    /**
     * @param refreshTokenExpiredAt the expiration time to set for the refresh token
     */
    public void setRefreshTokenExpiredAt(LocalDateTime refreshTokenExpiredAt) {
        this.refreshTokenExpiredAt = refreshTokenExpiredAt;
    }

    /**
     * @return the creation time of this session
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt the creation time to set for this session
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
