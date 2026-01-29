package fr.naavi.identity.entitylistener;

import fr.naavi.identity.entity.Authorization;
import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class AuthorizationListener {
    /**
     * @param authorization The reset password request entity being persisted.
     */
    @PrePersist
    protected void onCreate(Authorization authorization) {
        authorization.setCreatedAt(LocalDateTime.now());
        authorization.setExpiredAt(LocalDateTime.now().plusHours(24));
    }
}
