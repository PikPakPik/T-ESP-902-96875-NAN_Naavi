package fr.naavi.identity.entity;

import fr.naavi.identity.entitylistener.AuthorizationListener;
import fr.naavi.identity.enums.AuthorizationTypeEnum;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

import java.time.LocalDateTime;

@Entity(name = "authorizations")
@EntityListeners(AuthorizationListener.class)
public class Authorization {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    private AuthorizationTypeEnum type;

    @Column(nullable = false)
    private String token;

    @Column
    private String oldValue = null;

    @Column
    private String newValue = null;

    @Column(nullable = false)
    private LocalDateTime expiredAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * @return The unique identifier of the authorization.
     */
    public Long getId() {
        return id;
    }

    /**
     * @return the user associated with the authorization.
     */
    public User getUser() {
        return user;
    }

    /**
     * @param user the user associated with the authorization.
     */
    public void setUser(User user) {
        this.user = user;
    }

    /**
     * @return the type of authorization associated with this reset password request
     */
    public AuthorizationTypeEnum getType() {
        return type;
    }

    /**
     * @param type the type of authorization to associate with this reset password request
     */
    public void setType(AuthorizationTypeEnum type) {
        this.type = type;
    }

    /**
     * @return the token associated with the authorization.
     */
    public String getToken() {
        return token;
    }

    /**
     * @param token the token to associate with the authorization.
     */
    public void setToken(String token) {
        this.token = token;
    }

    /**
     * @return the old value of the attribute to be modified.
     */
    public String getOldValue() {
        return oldValue;
    }

    /**
     * @param oldValue the old value of the attribute to be modified.
     */
    public void setOldValue(String oldValue) {
        this.oldValue = oldValue;
    }

    /**
     * @return the new value of the attribute to be modified.
     */
    public String getNewValue() {
        return newValue;
    }

    /**
     * @param newValue the new value of the attribute to be modified.
     */
    public void setNewValue(String newValue) {
        this.newValue = newValue;
    }

    /**
     * @return the expiration date and time of the authorization.
     */
    public LocalDateTime getExpiredAt() {
        return expiredAt;
    }

    /**
     * @param expiredAt the expiration date and time to set for the authorization.
     */
    public void setExpiredAt(LocalDateTime expiredAt) {
        this.expiredAt = expiredAt;
    }

    /**
     * @return the creation date and time of the authorization.
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt the creation date and time to set for the authorization.
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
