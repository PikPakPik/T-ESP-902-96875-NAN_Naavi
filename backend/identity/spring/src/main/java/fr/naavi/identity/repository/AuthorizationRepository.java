package fr.naavi.identity.repository;

import fr.naavi.identity.entity.Authorization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

public interface AuthorizationRepository extends JpaRepository<Authorization, Long> {
    /**
     * Finds an authorization by its token.
     *
     * @param token The token of the authorization.
     * @return An Optional containing the Authorization if found, otherwise empty.
     */
    Optional<Authorization> findByToken(String token);

    /**
     * Deletes all authorizations that have expired before the specified time.
     *
     * @param now The current time to compare against expiration times.
     * @return The number of authorizations deleted.
     */
    @Modifying
    @Transactional
    @Query("DELETE FROM authorizations a WHERE a.expiredAt < :now")
    int deleteAllExpiredRequests(LocalDateTime now);
}
