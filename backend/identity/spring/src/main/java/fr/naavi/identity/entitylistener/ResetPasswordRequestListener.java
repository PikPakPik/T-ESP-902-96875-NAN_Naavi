package fr.naavi.identity.entitylistener;

import fr.naavi.identity.entity.ResetPasswordRequest;
import jakarta.persistence.PrePersist;

import java.time.LocalDateTime;

public class ResetPasswordRequestListener {
    /**
     * @param resetPasswordRequest The reset password request entity being persisted.
     */
    @PrePersist
    protected void onCreate(ResetPasswordRequest resetPasswordRequest) {
        resetPasswordRequest.setCreatedAt(LocalDateTime.now());
        resetPasswordRequest.setExpiredAt(LocalDateTime.now().plusMinutes(10));
    }
}
