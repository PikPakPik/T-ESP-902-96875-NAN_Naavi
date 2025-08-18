package fr.naavi.identity.entity;

import fr.naavi.identity.entitylistener.ResetPasswordRequestListener;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

import java.time.LocalDateTime;

@Entity(name = "reset_password_requests")
@EntityListeners(ResetPasswordRequestListener.class)
public class ResetPasswordRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(nullable = false)
    private User user;

    @Column(nullable = false)
    private String token;

    @Column(nullable = false, updatable = false)
    private LocalDateTime expiredAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * @return the unique identifier of the reset password request
     */
    public Long getId() {
        return id;
    }

    /**
     * @return the user associated with this reset password request
     */
    public User getUser() {
        return user;
    }

    /**
     * @param user the user to associate with this reset password request
     */
    public void setUser(User user) {
        this.user = user;
    }

    /**
     * @return the token for this reset password request
     */
    public String getToken() {
        return token;
    }

    /**
     * @param token the token to set for this reset password request
     */
    public void setToken(String token) {
        this.token = token;
    }

    /**
     * @return the expiration time of this reset password request
     */
    public LocalDateTime getExpiredAt() {
        return expiredAt;
    }

    /**
     * @param expiredAt the expiration time to set for this reset password request
     */
    public void setExpiredAt(LocalDateTime expiredAt) {
        this.expiredAt = expiredAt;
    }

    /**
     * @return the creation time of this reset password request
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt the creation time to set for this reset password request
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
