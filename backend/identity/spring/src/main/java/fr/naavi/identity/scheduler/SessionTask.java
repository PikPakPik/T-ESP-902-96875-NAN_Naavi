package fr.naavi.identity.scheduler;

import fr.naavi.identity.repository.SessionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class SessionTask {
    private static final Logger log = LoggerFactory.getLogger(SessionTask.class);

    private final SessionRepository sessionRepository;

    /**
     * Constructs a SessionTask
     */
    public SessionTask(SessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }

    /**
     * Scheduled task to delete expired user sessions.
     * This method runs every hour and removes all sessions that have expired.
     */
    @Scheduled(cron = "0 0 * * * *")
    public void deleteExpiredSessions() {
        LocalDateTime now = LocalDateTime.now();
        int deletedCount = sessionRepository.deleteAllExpiredSessions(now);

        log.info("[User Sessions] {} expired sessions have been removed.", deletedCount);
    }
}
