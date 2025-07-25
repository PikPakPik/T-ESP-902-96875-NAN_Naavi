package fr.naavi.identity.scheduler;

import fr.naavi.identity.repository.ResetPasswordRequestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class ResetPasswordRequestTask {
    private static final Logger log = LoggerFactory.getLogger(ResetPasswordRequestTask.class);

    private final ResetPasswordRequestRepository resetPasswordRequestRepository;

    /**
     * Constructs a ResetPasswordRequestTask
     */
    public ResetPasswordRequestTask(ResetPasswordRequestRepository resetPasswordRequestRepository) {
        this.resetPasswordRequestRepository = resetPasswordRequestRepository;
    }

    /**
     * Scheduled task to delete expired reset password requests.
     * This method runs every hour and removes all requests that have expired.
     */
    @Scheduled(cron = "0 0 * * * *")
    public void deleteExpiredSessions() {
        LocalDateTime now = LocalDateTime.now();
        int deletedCount = this.resetPasswordRequestRepository.deleteAllExpiredRequests(now);

        log.info("[Reset Password Requests] {} expired requests have been removed.", deletedCount);
    }
}
