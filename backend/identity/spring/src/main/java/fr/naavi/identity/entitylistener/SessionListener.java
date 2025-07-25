package fr.naavi.identity.entitylistener;

import fr.naavi.identity.entity.Session;
import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class SessionListener {
    /**
     * @param session The user entity being persisted.
     */
    @PrePersist
    protected void onCreate(Session session) {
        session.setCreatedAt(LocalDateTime.now());
        session.setAccessTokenExpiredAt(LocalDateTime.now().plusDays(1));
        session.setRefreshTokenExpiredAt(LocalDateTime.now().plusDays(7));
    }
}
