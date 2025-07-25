package fr.naavi.identity.entitylistener;

import fr.naavi.identity.entity.User;
import fr.naavi.identity.enums.StatusEnum;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;

import java.time.LocalDateTime;
import java.util.List;

public class UserListener {
    /**
     * @param user The user entity being persisted.
     */
    @PrePersist
    protected void onCreate(User user) {
        user.setCreatedAt(LocalDateTime.now());
        user.setRoles(List.of("ROLE_USER"));
        user.setStatus(StatusEnum.UNVERIFIED);
    }

    /**
     * @param user The user entity being persisted.
     */
    @PreUpdate
    protected void onUpdate(User user) {
        user.setUpdatedAt(LocalDateTime.now());
    }
}