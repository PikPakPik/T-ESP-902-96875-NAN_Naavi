package fr.naavi.identity.repository;

import fr.naavi.identity.entity.ResetPasswordRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

public interface ResetPasswordRequestRepository extends JpaRepository<ResetPasswordRequest, Long> {
    /**
     * Finds a reset password request by its token.
     *
     * @param token The token of the reset password request.
     * @return An Optional containing the ResetPasswordRequest if found, otherwise empty.
     */
    Optional<ResetPasswordRequest> findByToken(String token);

    /**
     * Deletes all expired reset password requests.
     *
     * @param now The current time to compare against the expiration time.
     * @return The number of deleted requests.
     */
    @Modifying
    @Transactional
    @Query("DELETE FROM reset_password_requests r WHERE r.expiredAt < :now")
    int deleteAllExpiredRequests(LocalDateTime now);
}