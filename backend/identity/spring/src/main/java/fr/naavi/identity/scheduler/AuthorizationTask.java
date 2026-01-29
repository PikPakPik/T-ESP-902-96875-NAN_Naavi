package fr.naavi.identity.scheduler;

import fr.naavi.identity.repository.AuthorizationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class AuthorizationTask {
    private static final Logger log = LoggerFactory.getLogger(AuthorizationTask.class);

    private final AuthorizationRepository authorizationRepository;

    /**
     * Constructs an AuthorizationTask
     */
    public AuthorizationTask(AuthorizationRepository authorizationRepository) {
        this.authorizationRepository = authorizationRepository;
    }

    /**
     * Scheduled task to delete expired reset password requests.
     * This method runs every hour and removes all requests that have expired.
     */
    @Scheduled(cron = "0 0 * * * *")
    public void deleteExpiredSessions() {
        LocalDateTime now = LocalDateTime.now();
        int deletedCount = this.authorizationRepository.deleteAllExpiredRequests(now);

        log.info("[Authorizations Requests] {} expired requests have been removed.", deletedCount);
    }
}
