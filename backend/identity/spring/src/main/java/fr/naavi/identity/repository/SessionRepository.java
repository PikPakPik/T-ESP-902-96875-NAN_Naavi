package fr.naavi.identity.repository;

import fr.naavi.identity.entity.Session;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

public interface SessionRepository extends JpaRepository<Session, Long> {
    /**
     * Finds a session by its access token.
     *
     * @param accessToken the access token of the session
     * @return an Optional containing the Session if found, or empty if not found
     */
    Optional<Session> findByAccessToken(String accessToken);

    /**
     * Finds a session by its access token.
     *
     * @param accessToken the access token of the session
     * @return an Optional containing the Session if found, or empty if not found
     */
    Optional<Session> findByRefreshToken(String accessToken);

    /**
     * Deletes all sessions that have expired based on the provided current time.
     *
     * @param now the current time used to determine if sessions are expired
     * @return the number of sessions deleted
     */
    @Modifying
    @Transactional
    @Query("DELETE FROM sessions s WHERE s.accessTokenExpiredAt < :now AND s.refreshTokenExpiredAt < :now")
    int deleteAllExpiredSessions(LocalDateTime now);
}